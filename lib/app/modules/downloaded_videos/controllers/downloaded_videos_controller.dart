import 'package:get/get.dart';
import '../../../data/local/offline_database.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/download_service.dart';
import '../../../data/services/logger_service.dart';
import '../../../routes/app_pages.dart';

class DownloadedVideosController extends GetxController {
  final OfflineDatabase _db = OfflineDatabase.instance;
  final DownloadService _downloadService = Get.find<DownloadService>();
  final AuthService _authService = Get.find<AuthService>();

  final downloads = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final username = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUsername();
    loadDownloads();
    
    // Listen to global progress updates
    _downloadService.progressStream.listen((event) {
       final lessonId = event['lesson_id'];
       final index = downloads.indexWhere((d) => d['lesson_id'] == lessonId);
       
       if (index != -1) {
         final updatedDownload = Map<String, dynamic>.from(downloads[index]);
         updatedDownload['download_status'] = event['status'];
         updatedDownload['download_progress'] = event['progress'];
         downloads[index] = updatedDownload;
       } else {
         // If not found (maybe new download started elsewhere), reload list
         loadDownloads();
       }
    });
  }

  Future<void> _loadUsername() async {
    final name = await _authService.getUsername();
    username.value = name ?? '';
  }

  Future<void> loadDownloads() async {
    isLoading.value = true;
    final list = await _db.getAllDownloads();
    downloads.assignAll(list);
    isLoading.value = false;
  }

  Future<void> pauseDownload(int lessonId) async {
    await _downloadService.pauseDownload(lessonId);
  }

  Future<void> resumeDownload(int lessonId, String title, String videoUrl) async {
    // We need Lesson object to resume. 
    // Ideally we should store enough info in DB to reconstruct Lesson object or pass it.
    // The DB stores 'direct_hls_url' which is what downloadLesson needs.
    // Let's create a minimal Lesson object.
    
    final lesson = Lesson(
      id: lessonId,
      title: title,
      orderIndex: 0,
      isFreePreview: false,
      isCompleted: false,
      directHlsUrl: videoUrl,
      videoUrl: videoUrl,
      downloadUrl: videoUrl,
      streamingLocked: false,
    );
    
    await _downloadService.downloadLesson(lesson);
  }

  Future<void> deleteDownload(int lessonId) async {
    await _downloadService.deleteDownload(lessonId);
    await loadDownloads();
  }

  void playVideo(Map<String, dynamic> download) {
    final rawPath = download['local_video_path'] as String?;
    final lessonId = download['lesson_id'];
    final title = download['title'] as String? ?? 'فيديو';

    String? path = (rawPath != null && rawPath.isNotEmpty) ? rawPath : null;

    // If path is empty/null, reconstruct it from lesson_id
    if (path == null && lessonId != null) {
      path = 'downloads/$lessonId/index.m3u8';
    }

    if (path != null) {
      // OfflinePlayerController handles path resolution (absolute, relative, or legacy)
      Get.toNamed(Routes.OFFLINE_PLAYER, arguments: {'path': path, 'title': title});
    } else {
      LoggerService().error('مسار الفيديو غير صالح', title: 'خطأ');
    }
  }
}
