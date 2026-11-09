import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart' hide Response;
import 'package:uuid/uuid.dart';
import '../models/subject_model.dart';
import '../local/offline_database.dart';
import 'logger_service.dart';

class DownloadService extends GetxService {
  final OfflineDatabase _db = OfflineDatabase.instance;
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  // Stream for progress updates
  final _progressStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get progressStream =>
      _progressStreamController.stream;

  Future<String?> downloadLesson(Lesson lesson) async {
    // Phase 2 logic: Use downloadUrl with legacy fallback
    // Do NOT fall back to streaming URLs if streaming is locked.
    String? url;
    if (lesson.streamingLocked) {
      url = lesson.downloadUrl;
    } else {
      url = lesson.downloadUrl ?? lesson.directHlsUrl ?? lesson.videoUrl;
    }

    if (url == null) {
      LoggerService().error('لا يوجد رابط فيديو متاح للتحميل', title: 'خطأ');
      return null;
    }

    // Check if download already exists
    final existingDownload = await _db.getDownloadByLessonId(lesson.id);
    String taskId;

    if (existingDownload != null) {
      // Resume
      taskId = existingDownload['download_id'];

      // If it's already running, do nothing
      if (existingDownload['download_status'] == 1) {
        return taskId;
      }

      // Update status to Running
      await _db.updateDownloadStatus(
        taskId,
        1,
        existingDownload['download_progress'] ?? 0,
      );

      // Emit update
      _progressStreamController.add({
        'lesson_id': lesson.id,
        'download_id': taskId,
        'status': 1,
        'progress': existingDownload['download_progress'] ?? 0,
      });
    } else {
      // New download
      if (Platform.isAndroid) {
        if (await Permission.storage.request().isDenied) {
          // Proceeding anyway
        }
      }

      taskId = const Uuid().v4();

      await _db.insertDownload({
        'lesson_id': lesson.id,
        'title': lesson.title,
        'local_video_path': '',
        'direct_hls_url': url,
        'is_completed': 0,
        'download_id': taskId,
        'download_status': 1, // 1 = Running
        'download_progress': 0,
        'file_size': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Emit update
      _progressStreamController.add({
        'lesson_id': lesson.id,
        'download_id': taskId,
        'status': 1,
        'progress': 0,
      });
    }

    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    // Start download in background
    _startDownload(taskId, lesson, url, cancelToken);

    return taskId;
  }

  Future<void> pauseDownload(int lessonId) async {
    final download = await _db.getDownloadByLessonId(lessonId);
    if (download != null) {
      final taskId = download['download_id'];
      if (_cancelTokens.containsKey(taskId)) {
        _cancelTokens[taskId]?.cancel();
        _cancelTokens.remove(taskId);
      }
      // Update status to 5 (Paused)
      await _db.updateDownloadStatus(
        taskId,
        5,
        download['download_progress'] ?? 0,
      );

      // Emit update
      _progressStreamController.add({
        'lesson_id': lessonId,
        'download_id': taskId,
        'status': 5,
        'progress': download['download_progress'] ?? 0,
      });
    }
  }

  Future<void> _startDownload(
    String taskId,
    Lesson lesson,
    String masterUrl,
    CancelToken cancelToken,
  ) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      // Create a specific directory for this lesson
      final lessonDir = Directory('${appDocDir.path}/downloads/${lesson.id}');
      if (!await lessonDir.exists()) {
        await lessonDir.create(recursive: true);
      }

      String currentUrl = masterUrl;

      // 1. Fetch the m3u8 content
      Response response = await _dio.get(currentUrl, cancelToken: cancelToken);
      String m3u8Content = response.data.toString();

      // 2. Check if it's a Master Playlist (contains variant streams)
      if (m3u8Content.contains('#EXT-X-STREAM-INF')) {
        final lines = m3u8Content.split('\n');
        String? selectedVariantUrl;
        int selectedBandwidth = -1;
        int selectedHeight = -1;

        debugPrint(
          'DownloadService: Parsing master playlist for 720p preference...',
        );

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('#EXT-X-STREAM-INF')) {
            // Parse BANDWIDTH
            final bandwidthMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
            final bandwidth = bandwidthMatch != null
                ? int.tryParse(bandwidthMatch.group(1)!) ?? 0
                : 0;

            // Parse RESOLUTION
            final resolutionMatch = RegExp(
              r'RESOLUTION=(\d+)x(\d+)',
            ).firstMatch(line);
            int height = -1;
            if (resolutionMatch != null) {
              height = int.tryParse(resolutionMatch.group(2)!) ?? -1;
            }

            if (i + 1 < lines.length && !lines[i + 1].startsWith('#')) {
              String variantUri = lines[i + 1].trim();
              if (variantUri.isNotEmpty) {
                if (!variantUri.startsWith('http')) {
                  variantUri = Uri.parse(
                    currentUrl,
                  ).resolve(variantUri).toString();
                }

                debugPrint(
                  'DownloadService: Found variant height: $height, Bandwidth: $bandwidth',
                );

                // 720p Selection Logic:
                // 1. Prefer height <= 720. Among those, pick highest height.
                // 2. If height is unknown (-1), treat it as a candidate if no height <= 720 found.
                // 3. If only height > 720 found, pick the lowest height among them.
                
                bool isBetter = false;
                if (selectedVariantUrl == null) {
                  isBetter = true;
                } else {
                  if (height != -1 && height <= 720) {
                    if (selectedHeight == -1 || selectedHeight > 720 || height > selectedHeight || (height == selectedHeight && bandwidth > selectedBandwidth)) {
                      isBetter = true;
                    }
                  } else if (height == -1) {
                    if (selectedHeight == -1 && bandwidth > selectedBandwidth) {
                      isBetter = true;
                    } else if (selectedHeight > 720) {
                      isBetter = true;
                    }
                  } else if (height > 720) {
                    if (selectedHeight == -1 || (selectedHeight > 720 && height < selectedHeight)) {
                      isBetter = true;
                    }
                  }
                }

                if (isBetter) {
                  selectedVariantUrl = variantUri;
                  selectedBandwidth = bandwidth;
                  selectedHeight = height;
                }
              }
            }
          }
        }

        if (selectedVariantUrl != null) {
          debugPrint(
            'DownloadService: Selected variant with height: $selectedHeight, bandwidth: $selectedBandwidth',
          );
          currentUrl = selectedVariantUrl;
          response = await _dio.get(currentUrl, cancelToken: cancelToken);
          m3u8Content = response.data.toString();
        }
      }

      // 3. Parse Segments and Prepare Local m3u8
      final lines = m3u8Content.split('\n');
      final newM3u8Lines = <String>[];
      final segmentsToDownload = <String>[];

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('#EXT-X-KEY:')) {
          // Handle encryption key
          final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(trimmed);
          if (uriMatch != null) {
            final originalUri = uriMatch.group(1)!;
            final absoluteKeyUrl = originalUri.startsWith('http')
                ? originalUri
                : Uri.parse(currentUrl).resolve(originalUri).toString();

            final keyFileName = 'encryption.key';
            final keySavePath = '${lessonDir.path}/$keyFileName';

            try {
              await _dio.download(
                absoluteKeyUrl,
                keySavePath,
                cancelToken: cancelToken,
              );
              final newLine = trimmed.replaceFirst(originalUri, keyFileName);
              newM3u8Lines.add(newLine);
            } catch (e) {
              debugPrint('Error downloading HLS key: $e');
              continue;
            }
          } else {
            newM3u8Lines.add(trimmed);
          }
        } else if (trimmed.startsWith('#')) {
          // Pass other tags through
          newM3u8Lines.add(trimmed);
        } else {
          // It's a segment URI
          final segmentUri = trimmed;
          String absoluteSegmentUrl = segmentUri;

          if (!segmentUri.startsWith('http')) {
            absoluteSegmentUrl = Uri.parse(
              currentUrl,
            ).resolve(segmentUri).toString();
          }

          final segmentFileName = 'segment_${segmentsToDownload.length}.ts';
          segmentsToDownload.add(absoluteSegmentUrl);
          newM3u8Lines.add(segmentFileName); // Point to local file
        }
      }

      // 4. Save the new local m3u8 file
      final localM3u8Path = '${lessonDir.path}/index.m3u8';
      await File(localM3u8Path).writeAsString(newM3u8Lines.join('\n'));

      // 5. Download Segments in Parallel
      int completedCount = 0;
      final totalSegments = segmentsToDownload.length;
      final batchSize = 5; // Download 5 segments at a time

      for (int i = 0; i < totalSegments; i += batchSize) {
        if (cancelToken.isCancelled) {
          throw DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          );
        }

        final end = (i + batchSize < totalSegments)
            ? i + batchSize
            : totalSegments;
        final batch = segmentsToDownload.sublist(i, end);

        await Future.wait(
          batch.asMap().entries.map((entry) async {
            final index = i + entry.key;
            final url = entry.value;
            final savePath = '${lessonDir.path}/segment_$index.ts';

            // Resume check: if file exists and has size > 0, skip
            // Ideally check size match, but we don't know expected size without HEAD request.
            final file = File(savePath);
            if (await file.exists() && await file.length() > 0) {
              return;
            }

            await _dio.download(url, savePath, cancelToken: cancelToken);
          }),
        );

        completedCount += batch.length;
        final progress = ((completedCount / totalSegments) * 100).toInt();
        await _db.updateDownloadStatus(taskId, 1, progress); // 1 = Running

        _progressStreamController.add({
          'lesson_id': lesson.id,
          'download_id': taskId,
          'status': 1,
          'progress': progress,
        });
      }

      // 6. Finalize — only if still in DB (not deleted while downloading)
      final stillExists = await _db.getDownloadByLessonId(lesson.id);
      if (stillExists == null) {
        debugPrint(
          'DownloadService: Download was deleted while running. Skipping finalization.',
        );
        return;
      }
      await _db.updateDownloadStatus(taskId, 3, 100); // 3 = Success
      _progressStreamController.add({
        'lesson_id': lesson.id,
        'download_id': taskId,
        'status': 3,
        'progress': 100,
      });

      // Update the path in DB using a safe relative path with forward slashes
      final db = await _db.database;
      // Always use forward slashes to ensure cross-platform compatibility
      final relativeM3u8Path = 'downloads/${lesson.id}/index.m3u8';
      await db.update(
        'downloaded_lessons',
        {'local_video_path': relativeM3u8Path},
        where: 'download_id = ?',
        whereArgs: [taskId],
      );
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        // Just cancelled, don't update to failed if we paused (status 5)
        // But if it was a true cancel, we might want to update.
        // The pause method already updates status to 5.
        // The cancel method updates status to 4.
        // So we can check current status in DB? Or just rely on the caller setting the status.

        // Actually, if we are here, it means the token was cancelled.
        // If it was cancelled by pauseDownload, the DB status is already 5.
        // If it was cancelled by cancelDownload, the DB status is 4.

        // Let's check DB status just to be sure what happened?
        // Or simpler: The pause/cancel methods remove the token from _cancelTokens.
        // If it's still there, it wasn't manual? No.

        // Let's trust the method that cancelled it handled the DB update.
        // But wait, pauseDownload updates DB THEN cancels token.
        // So here we might overwrite status 5 with 4 if we are not careful.

        // Let's assume pauseDownload handles its own DB update.
        // We should only update to 4 if it's NOT 5.

        final current = await _db.getDownloadByLessonId(lesson.id);
        if (current != null && current['download_status'] != 5) {
          await _db.updateDownloadStatus(
            taskId,
            4,
            current['download_progress'] ?? 0,
          );
          _progressStreamController.add({
            'lesson_id': lesson.id,
            'download_id': taskId,
            'status': 4,
            'progress': current['download_progress'] ?? 0,
          });
        }
      } else {
        debugPrint('Download error: $e');
        await _db.updateDownloadStatus(taskId, 4, 0);
        _progressStreamController.add({
          'lesson_id': lesson.id,
          'download_id': taskId,
          'status': 4,
          'progress': 0,
        });
      }
    } finally {
      _cancelTokens.remove(taskId);
    }
  }

  Future<void> cancelDownload(String taskId) async {
    if (_cancelTokens.containsKey(taskId)) {
      _cancelTokens[taskId]?.cancel();
      _cancelTokens.remove(taskId);
    }
    await _db.updateDownloadStatus(taskId, 4, 0);
  }

  Future<void> deleteDownload(int lessonId) async {
    final download = await _db.getDownloadByLessonId(lessonId);
    if (download != null) {
      // 1. Cancel running download first (await to ensure it stops)
      final taskId = download['download_id'] as String?;
      if (taskId != null && _cancelTokens.containsKey(taskId)) {
        _cancelTokens[taskId]?.cancel();
        _cancelTokens.remove(taskId);
      }

      // 2. Delete from DB immediately so that _startDownload finalization aborts
      await _db.deleteDownload(lessonId);

      // 3. Delete the lesson directory on disk
      final appDocDir = await getApplicationDocumentsDirectory();
      final lessonDir = Directory('${appDocDir.path}/downloads/$lessonId');
      if (await lessonDir.exists()) {
        try {
          await lessonDir.delete(recursive: true);
          debugPrint('DownloadService: Deleted lesson dir: ${lessonDir.path}');
        } catch (e) {
          debugPrint('DownloadService: Error deleting directory: $e');
        }
      }
    }
  }

  Future<Map<String, dynamic>?> getDownloadInfo(int lessonId) async {
    return await _db.getDownloadByLessonId(lessonId);
  }

  Future<File> resolveVideoFile(String inputPath) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final appDocPath = appDocDir.path;

    // --- Strategy 1: Direct absolute path check ---
    if (p.isAbsolute(inputPath)) {
      final absFile = File(inputPath);
      if (await absFile.exists()) return absFile;

      // The absolute path doesn't exist. Try to salvage it by
      // extracting the 'downloads/<id>/index.m3u8' portion.
      final match = RegExp(
        r'downloads[/\\](\d+)[/\\]([^/\\]+)$',
      ).firstMatch(inputPath);
      if (match != null) {
        final salvaged = File(
          '$appDocPath/downloads/${match.group(1)}/${match.group(2)}',
        );
        if (await salvaged.exists()) return salvaged;
      }
    }

    // --- Strategy 2: Relative path with forward slashes (new format) ---
    // Replace any backslashes with forward slashes for safety
    final normalized = inputPath.replaceAll('\\', '/');
    final fromDocDir = File('$appDocPath/$normalized');
    if (await fromDocDir.exists()) return fromDocDir;

    // --- Strategy 3: Fallback: return what we have (caller will check exists()) ---
    return fromDocDir;
  }
}
