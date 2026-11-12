import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'dart:io';
import '../../../data/models/subject_model.dart';
import 'package:universa/app/data/services/content_service.dart';
import 'package:universa/app/data/services/download_service.dart';
import 'package:universa/app/data/services/logger_service.dart';

import 'package:universa/app/data/services/ad_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../subject_details/controllers/subject_details_controller.dart';
import '../views/widgets/video_watermark_overlay.dart';

class LessonDetailsController extends GetxController with WidgetsBindingObserver {
  final ContentService _contentService = Get.find<ContentService>();
  final DownloadService _downloadService = Get.find<DownloadService>();
  final AdService _adService = Get.find<AdService>();
  HttpServer? _localHlsServer;

  final RxInt lessonId = 0.obs;
  final RxnInt nextLessonId = RxnInt();
  final RxnInt prevLessonId = RxnInt();

  /// حالة نافذة المشاهدة المعيارية، انظر [ViewingWindowStates].
  final viewingWindowState = ViewingWindowStates.unknown.obs;

  /// رسالة الخطأ الفعلية عند تعذر التحقق من نافذة المشاهدة.
  final viewingWindowError = RxnString();
  final remainingSeconds = 0.obs;
  Timer? _timer;

  String get viewingWindowRemainingSecondsStr => _formatDuration(remainingSeconds.value);

  final isLoading = true.obs;
  final lesson = Rxn<Lesson>();

  BetterPlayerController? betterPlayerController;
  final isVideoLoading = true.obs;

  final downloadProgress = 0.obs;
  final isDownloading = false.obs;
  final isPaused = false.obs;
  final isDownloaded = false.obs;
  String? currentTaskId;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    final args = Get.arguments;
    if (args is int) {
      lessonId.value = args;
    } else if (args is Map) {
      lessonId.value = args['id'];
    }

    _updateNavigationIds();
    _showAdAndFetch();

    // Listen to global progress stream
    _downloadService.progressStream.listen((event) {
      if (lesson.value != null && event['lesson_id'] == lesson.value!.id) {
        downloadProgress.value = event['progress'];
        final status = event['status'];

        if (status == 1) {
          // Running
          isDownloading.value = true;
          isPaused.value = false;
          isDownloaded.value = false;
        } else if (status == 3) {
          // Success
          isDownloading.value = false;
          isPaused.value = false;
          isDownloaded.value = true;
          LoggerService().success('تم تحميل الدرس بنجاح', title: 'تحميل');
        } else if (status == 5) {
          // Paused
          isDownloading.value = false;
          isPaused.value = true;
        } else {
          // Failed/Cancelled
          isDownloading.value = false;
          isPaused.value = false;
          // Only show error if we were expecting it to run
          // LoggerService().error('فشل التحميل', title: 'خطأ');
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-validate viewing window when app resumes
      if (viewingWindowState.value == ViewingWindowStates.active &&
          !isDownloaded.value) {
        fetchLessonDetails();
      }
    }
  }

  void _updateNavigationIds() {
    try {
      if (Get.isRegistered<SubjectDetailsController>()) {
        final subjectController = Get.find<SubjectDetailsController>();
        nextLessonId.value = subjectController.getNextLessonId(lessonId.value);
        prevLessonId.value = subjectController.getPrevLessonId(lessonId.value);
      }
    } catch (e) {
      debugPrint('SubjectDetailsController not found or error: $e');
    }
  }

  Future<void> loadLesson(int newId) async {
    // Stop current video
    betterPlayerController?.pause();
    betterPlayerController?.dispose();
    betterPlayerController = null;
    _localHlsServer?.close(force: true);
    _localHlsServer = null;
    _timer?.cancel();
    _timer = null;

    // Reset state
    lessonId.value = newId;
    lesson.value = null;
    isLoading.value = true;
    isVideoLoading.value = true;
    isDownloading.value = false;
    isPaused.value = false;
    isDownloaded.value = false;
    downloadProgress.value = 0;
    viewingWindowState.value = ViewingWindowStates.unknown;
    viewingWindowError.value = null;
    remainingSeconds.value = 0;

    // Update navigation
    _updateNavigationIds();

    // Fetch new details
    await _showAdAndFetch();
  }

  Future<void> _showAdAndFetch() async {
    await _adService.showInterstitial(
      onComplete: () {
        fetchLessonDetails();
      },
    );
  }

  Future<void> fetchLessonDetails() async {
    isLoading.value = true;
    viewingWindowError.value = null;
    try {
      final result = await _contentService.getLessonDetails(lessonId.value);
      lesson.value = result;
      // الحالة قادمة من `viewing_window_state`، والحقل الغائب يصبح 'unknown'
      // وليس 'disabled' حتى لا يُفتح التشغيل أونلاين بدون تحقق.
      viewingWindowState.value = result.viewingWindowState;
      remainingSeconds.value = result.viewingWindowRemainingSeconds ?? 0;

      await _checkDownloadStatus();

      // If local download exists, prioritize it and ignore window restrictions
      if (isDownloaded.value) {
        await _initializePlayer();
        return;
      }

      // Handle viewing window logic for online playback
      switch (viewingWindowState.value) {
        case ViewingWindowStates.notStarted:
          isLoading.value = false;
          await _showStartWindowDialog();
          break;
        case ViewingWindowStates.active:
          _startCountdown();
          isLoading.value = false;
          await _showActiveWindowDialog();
          break;
        case ViewingWindowStates.expired:
          // Expired windows don't initialize online player
          await _initializePlayer();
          break;
        case ViewingWindowStates.disabled:
          // Restriction is explicitly OFF
          await _initializePlayer();
          break;
        default:
          // حالة غير معروفة: نمنع التشغيل أونلاين ونعرض سببًا واضحًا.
          debugPrint(
            'Viewing window state: ${viewingWindowState.value} - blocking online playback',
          );
          viewingWindowError.value =
              'تعذر التحقق من فترة المشاهدة: حالة غير معروفة من الخادم.';
          await _initializePlayer();
          break;
      }
    } on ApiException catch (e) {
      debugPrint('Error fetching lesson details: $e');
      viewingWindowState.value = ViewingWindowStates.error;
      viewingWindowError.value = e.message;
      await _initializePlayer();
    } catch (e) {
      debugPrint('Error fetching lesson details: $e');
      viewingWindowState.value = ViewingWindowStates.error;
      viewingWindowError.value = 'تعذر التحقق من فترة المشاهدة: $e';
      await _initializePlayer();
    } finally {
      isLoading.value = false;
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    if (remainingSeconds.value > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds.value > 0) {
          remainingSeconds.value--;
        } else {
          timer.cancel();
          viewingWindowState.value = ViewingWindowStates.expired;
          betterPlayerController?.pause();
          betterPlayerController?.dispose();
          betterPlayerController = null;
        }
      });
    }
  }

  Future<void> _showStartWindowDialog() async {
    final result = await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: Colors.cyanAccent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'بدء فترة مشاهدة المحاضرة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'بمجرد المتابعة، ستبدأ فترة مشاهدة هذه المحاضرة أونلاين لمدة 3 ساعات. بعد انتهاء المدة، يمكنك تحميل المحاضرة ومشاهدتها بدون إنترنت من خلال التطبيق.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'موافق، متابعة',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    if (result == true) {
      await _activateViewingWindow();
    } else {
      Get.back();
    }
  }

  Future<void> _showActiveWindowDialog() async {
    final result = await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    color: Colors.greenAccent,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'الوقت المتبقي للمشاهدة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'الوقت المتبقي: ${_formatDuration(remainingSeconds.value)}',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                Text(
                  'يمكنك متابعة المشاهدة الآن. لا يتم إعادة تعيين الوقت عند إغلاق التطبيق.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'متابعة المشاهدة',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    if (result == true) {
      await _initializePlayer();
    } else {
      Get.back();
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _activateViewingWindow() async {
    isLoading.value = true;
    viewingWindowError.value = null;
    try {
      // الاستجابة تحتوي `state` و`remaining_seconds`.
      final result = await _contentService.startViewingWindow(lessonId.value);

      if (result.state == ViewingWindowStates.active) {
        viewingWindowState.value = ViewingWindowStates.active;
        remainingSeconds.value = result.remainingSeconds ?? 0;
        _startCountdown();

        // تحديث الدرس للحصول على الروابط المصرح بها. فشل التحديث هنا
        // لا يجب أن يلغي فترة المشاهدة التي تم تفعيلها للتو.
        try {
          lesson.value = await _contentService.getLessonDetails(lessonId.value);
        } catch (e) {
          debugPrint('Failed to refresh lesson after starting window: $e');
        }

        await _initializePlayer();
      } else if (result.state == ViewingWindowStates.disabled) {
        // القيد مغلق من الخادم: تشغيل عادي.
        viewingWindowState.value = ViewingWindowStates.disabled;
        await _initializePlayer();
      } else {
        await _failActivation('تعذر بدء فترة المشاهدة: حالة غير متوقعة من الخادم.');
      }
    } on ApiException catch (e) {
      await _failActivation(e.message);
    } catch (e) {
      await _failActivation('تعذر بدء فترة المشاهدة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// عند فشل بدء النافذة نُبقي المستخدم في الصفحة ونعرض سبب الخطأ الفعلي
  /// بدل إغلاق الصفحة، مع استمرار حظر التشغيل أونلاين.
  Future<void> _failActivation(String message) async {
    viewingWindowState.value = ViewingWindowStates.error;
    viewingWindowError.value = message;
    LoggerService().error(message, title: 'خطأ');
    await _initializePlayer();
  }

  Future<void> _checkDownloadStatus() async {
    final info = await _downloadService.getDownloadInfo(lessonId.value);
    if (info != null) {
      currentTaskId = info['download_id'];
      downloadProgress.value = info['download_progress'] ?? 0;
      isDownloaded.value = info['download_status'] == 3;
      isDownloading.value = info['download_status'] == 1;
      isPaused.value = info['download_status'] == 5;
    }
  }

  Future<void> _initializePlayer() async {
    if (lesson.value == null) return;

    isVideoLoading.value = true;

    try {
      // Check if downloaded and file exists
      final downloadInfo = await _downloadService.getDownloadInfo(
        lessonId.value,
      );
      String? videoSource;
      bool isLocal = false;

      if (downloadInfo != null && downloadInfo['download_status'] == 3) {
        final rawPath = downloadInfo['local_video_path'];
        if (rawPath != null) {
          final file = await _downloadService.resolveVideoFile(rawPath);
          if (await file.exists()) {
            videoSource = file.path;
            isLocal = true;
          }
        }
      }

      // Phase 2: If streaming is locked and we don't have a local copy, 
      // do NOT initialize player with online URLs.
      // Phase 3: Also block if viewing window is expired or in an unauthorized state.
      // Unrestricted playback only if state is 'disabled' or 'active' (after confirmation).
      final isWindowValid =
          viewingWindowState.value == ViewingWindowStates.active ||
              viewingWindowState.value == ViewingWindowStates.disabled;
      if ((lesson.value!.streamingLocked ||
              viewingWindowState.value == ViewingWindowStates.expired ||
              !isWindowValid) &&
          !isLocal) {
        videoSource = null;
      } else {
        videoSource ??= lesson.value!.directHlsUrl ?? lesson.value!.videoUrl;
      }

      if (videoSource == null) {
        isVideoLoading.value = false;
        return;
      }

      BetterPlayerDataSource dataSource;
      if (isLocal) {
        final isLocalHls = videoSource.toLowerCase().endsWith('.m3u8');
        final localSource = isLocalHls
            ? await _createLocalHlsUrl(videoSource)
            : videoSource;
        dataSource = BetterPlayerDataSource(
          isLocalHls
              ? BetterPlayerDataSourceType.network
              : BetterPlayerDataSourceType.file,
          localSource,
          videoFormat: isLocalHls
              ? BetterPlayerVideoFormat.hls
              : BetterPlayerVideoFormat.other,
          cacheConfiguration: const BetterPlayerCacheConfiguration(
            useCache: false,
          ),
        );
      } else {
        dataSource = BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          videoSource,
          useAsmsTracks: true,
          useAsmsAudioTracks: true,
          videoFormat: BetterPlayerVideoFormat.hls,
        );
      }

      betterPlayerController = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          fit: BoxFit.contain,
          autoDetectFullscreenDeviceOrientation: true,
          autoDetectFullscreenAspectRatio: true,
          overlay: const VideoWatermarkOverlay(),
          controlsConfiguration: BetterPlayerControlsConfiguration(
            enableSkips: false,
            enableFullscreen: true,
            enableQualities: true,
            controlBarColor: const Color(0xCC1A1A2E),
          ),
        ),
        betterPlayerDataSource: dataSource,
      );

      isVideoLoading.value = false;
    } catch (e) {
      debugPrint('Error initializing player: $e');
      isVideoLoading.value = false;
    }
  }

  Future<void> startDownload() async {
    if (lesson.value == null) return;

    // Check internet connection first
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet');
      }
    } on SocketException catch (_) {
      LoggerService().error(
        'تأكد من اتصالك بالانترنت',
        title: 'خطأ في الاتصال',
      );
      return;
    }

    final taskId = await _downloadService.downloadLesson(lesson.value!);
    if (taskId != null) {
      currentTaskId = taskId;
      isDownloading.value = true;
      isPaused.value = false;
      LoggerService().info('بدأ تحميل الدرس في الخلفية', title: 'تحميل');
    }
  }

  Future<void> pauseDownload() async {
    await _downloadService.pauseDownload(lessonId.value);
    isDownloading.value = false;
    isPaused.value = true;
  }

  Future<void> markAsCompleted() async {
    if (lesson.value == null) return;

    try {
      final result = await _contentService.completeLesson(lessonId.value);
      if (result['ok'] == true) {
        // Update local lesson status
        lesson.value = Lesson(
          id: lesson.value!.id,
          title: lesson.value!.title,
          orderIndex: lesson.value!.orderIndex,
          durationSeconds: lesson.value!.durationSeconds,
          isFreePreview: lesson.value!.isFreePreview,
          isCompleted: true,
          videoUrl: lesson.value!.videoUrl,
          directHlsUrl: lesson.value!.directHlsUrl,
          downloadUrl: lesson.value!.downloadUrl,
          streamingLocked: lesson.value!.streamingLocked,
          viewingWindowState: lesson.value!.viewingWindowState,
          viewingWindowRemainingSeconds:
              lesson.value!.viewingWindowRemainingSeconds,
          viewingWindowExpiresAt: lesson.value!.viewingWindowExpiresAt,
          pdfUrl: lesson.value!.pdfUrl,
          externalExamUrl: lesson.value!.externalExamUrl,
        );
        LoggerService().success('تم تعليم الدرس كمكتمل', title: 'تم');

        // Notify SubjectDetailsController to refresh/update
        try {
          if (Get.isRegistered<SubjectDetailsController>()) {
            Get.find<SubjectDetailsController>().fetchSubjectDetails();
          }
        } catch (_) {}
      } else {
        LoggerService().error(result['detail'] ?? 'فشل العملية', title: 'خطأ');
      }
    } catch (e) {
      LoggerService().error('حدث خطأ ما', title: 'خطأ');
    }
  }

  // _monitorProgress removed as we use streams now

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    betterPlayerController?.dispose();
    _localHlsServer?.close(force: true);
    _timer?.cancel();
    super.onClose();
  }

  Future<String> _createLocalHlsUrl(String playlistPath) async {
    final playlistFile = await _downloadService.resolveVideoFile(playlistPath);
    if (!await playlistFile.exists()) {
      throw Exception('playlist_not_found');
    }

    await _localHlsServer?.close(force: true);
    final baseDirectory = playlistFile.parent.path;

    // Explicitly bind to 127.0.0.1 for consistency
    _localHlsServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

    _localHlsServer!.listen((request) async {
      final response = request.response;

      // Add CORS headers
      response.headers.add('Access-Control-Allow-Origin', '*');
      response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
      response.headers.add(
        'Access-Control-Allow-Headers',
        'Origin, X-Requested-With, Content-Type, Accept',
      );

      if (request.method == 'OPTIONS') {
        response.statusCode = HttpStatus.ok;
        await response.close();
        return;
      }

      final relative = request.uri.path.startsWith('/')
          ? request.uri.path.substring(1)
          : request.uri.path;

      if (relative.contains('..')) {
        response.statusCode = HttpStatus.forbidden;
        await response.close();
        return;
      }

      final targetPath = '$baseDirectory/${Uri.decodeComponent(relative)}';
      final targetFile = File(targetPath);

      if (!await targetFile.exists()) {
        response.statusCode = HttpStatus.notFound;
        await response.close();
        return;
      }

      if (targetPath.toLowerCase().endsWith('.m3u8')) {
        response.headers.contentType = ContentType(
          'application',
          'vnd.apple.mpegurl',
        );
      } else if (targetPath.toLowerCase().endsWith('.ts')) {
        response.headers.contentType = ContentType('video', 'mp2t');
      } else if (targetPath.toLowerCase().endsWith('.key')) {
        response.headers.contentType = ContentType(
          'application',
          'octet-stream',
        );
      }

      await response.addStream(targetFile.openRead());
      await response.close();
    });

    final fileName = playlistFile.uri.pathSegments.last;
    return 'http://127.0.0.1:${_localHlsServer!.port}/$fileName';
  }
}
