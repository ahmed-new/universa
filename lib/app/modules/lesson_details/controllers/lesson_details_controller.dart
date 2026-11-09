import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'dart:io';
import '../../../data/models/subject_model.dart';
import 'package:universa/app/data/services/content_service.dart';
import 'package:universa/app/data/services/download_service.dart';
import 'package:universa/app/data/services/logger_service.dart';

import 'package:universa/app/data/services/ad_service.dart';
import '../../subject_details/controllers/subject_details_controller.dart';
import '../views/widgets/video_watermark_overlay.dart';

class LessonDetailsController extends GetxController {
  final ContentService _contentService = Get.find<ContentService>();
  final DownloadService _downloadService = Get.find<DownloadService>();
  final AdService _adService = Get.find<AdService>();
  HttpServer? _localHlsServer;

  final RxInt lessonId = 0.obs;
  final RxnInt nextLessonId = RxnInt();
  final RxnInt prevLessonId = RxnInt();

  final isLocked = false.obs;
  final RxnInt suggestedLessonId = RxnInt();

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

    // Reset state
    lessonId.value = newId;
    lesson.value = null;
    isLoading.value = true;
    isVideoLoading.value = true;
    isDownloading.value = false;
    isPaused.value = false;
    isDownloaded.value = false;
    downloadProgress.value = 0;

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
    isLocked.value = false;
    try {
      final result = await _contentService.getLessonDetails(lessonId.value);
      if (result != null) {
        lesson.value = result;
        await _checkDownloadStatus();
        await _initializePlayer();
      }
    } on LessonLockedException catch (e) {
      isLocked.value = true;
      suggestedLessonId.value = e.suggestedLessonId;
    } catch (e) {
      debugPrint('Error fetching lesson details: $e');
    } finally {
      isLoading.value = false;
    }
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
      if (lesson.value!.streamingLocked && !isLocal) {
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
    betterPlayerController?.dispose();
    _localHlsServer?.close(force: true);
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
