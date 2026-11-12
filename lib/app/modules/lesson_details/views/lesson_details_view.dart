import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../../../data/models/subject_model.dart';
import '../controllers/lesson_details_controller.dart';

class LessonDetailsView extends GetView<LessonDetailsController> {
  const LessonDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.lesson.value?.title ?? 'تفاصيل الدرس',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final lesson = controller.lesson.value;
        if (lesson == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.viewingWindowError.value ??
                      'فشل في تحميل بيانات الدرس',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchLessonDetails(),
                  child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Video Section
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: Obx(() {
                    if (controller.isVideoLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.betterPlayerController != null) {
                      return BetterPlayer(
                        controller: controller.betterPlayerController!,
                      );
                    }

                    // Phase 3: Show message if viewing window is expired or has an error/unknown state
                    final windowStatus = controller.viewingWindowState.value;
                    final isWindowError = windowStatus == ViewingWindowStates.error ||
                        windowStatus == ViewingWindowStates.unknown;
                    if ((windowStatus == ViewingWindowStates.expired ||
                            isWindowError) &&
                        !controller.isDownloaded.value) {
                      IconData icon = Icons.timer_off_outlined;
                      Color color = Colors.redAccent;
                      String message = "انتهت فترة المشاهدة أونلاين لهذه المحاضرة. يمكنك تحميلها ومشاهدتها بدون إنترنت.";

                      if (isWindowError) {
                        icon = Icons.error_outline;
                        color = Colors.orangeAccent;
                        // نعرض رسالة الخطأ الفعلية القادمة من طبقة الـ API إن وُجدت.
                        message = controller.viewingWindowError.value ??
                            "تعذر التحقق من فترة المشاهدة. يرجى إعادة المحاولة أو التواصل مع الدعم.";
                      }

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                color: color,
                                size: 50,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isWindowError) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => controller.fetchLessonDetails(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white10,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.white)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    // Phase 2: Show message if streaming is locked and not downloaded
                    if (lesson.streamingLocked && !controller.isDownloaded.value) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_clock_outlined,
                                color: Colors.orangeAccent,
                                size: 50,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "تم إكمال هذه المحاضرة. يمكنك تحميلها ومشاهدتها من التطبيق.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam_off_outlined,
                            color: Colors.white24,
                            size: 50,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'الفيديو غير متاح حالياً',
                            style: GoogleFonts.cairo(color: Colors.white38),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lesson.title,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (lesson.durationSeconds != null) ...[
                          Text(
                            '${(lesson.durationSeconds! / 60).floor()} دقيقة',
                            style: GoogleFonts.cairo(color: Colors.white70),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: Colors.cyanAccent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Viewing Window Timer UI
                    Obx(() {
                      if (controller.viewingWindowState.value ==
                          ViewingWindowStates.active) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                controller.viewingWindowRemainingSecondsStr,
                                style: GoogleFonts.cairo(
                                  color: Colors.cyanAccent,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'الوقت المتبقي للمشاهدة',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.timer_outlined,
                                    color: Colors.cyanAccent,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    // Actions Section (Complete & Navigation)
                    Column(
                      children: [
                        // Mark as Completed Button
                        Obx(() {
                          final isCompleted =
                              controller.lesson.value?.isCompleted ?? false;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isCompleted
                                  ? null
                                  : () => controller.markAsCompleted(),
                              icon: Icon(
                                isCompleted
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: isCompleted
                                    ? Colors.greenAccent
                                    : Colors.white,
                              ),
                              label: Text(
                                isCompleted ? 'تم إكمال الدرس' : 'تحديد كمكتمل',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Colors.greenAccent
                                      : Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCompleted
                                    ? Colors.green.withOpacity(0.1)
                                    : primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isCompleted
                                      ? const BorderSide(
                                          color: Colors.greenAccent,
                                        )
                                      : BorderSide.none,
                                ),
                                disabledBackgroundColor: Colors.green
                                    .withOpacity(0.1),
                                disabledForegroundColor: Colors.greenAccent,
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 16),

                        // Completion Hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'تأكد من إكمال الدرس لتتمكن من الانتقال للدرس التالى',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Navigation Buttons
                        Obx(() {
                          final hasNext = controller.nextLessonId.value != null;
                          final hasPrev = controller.prevLessonId.value != null;

                          if (!hasNext && !hasPrev) {
                            return const SizedBox.shrink();
                          }

                          return Row(
                            children: [
                              if (hasPrev)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => controller.loadLesson(
                                      controller.prevLessonId.value!,
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'الدرس السابق',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(
                                        color: Colors.white24,
                                      ),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              if (hasNext && hasPrev) const SizedBox(width: 12),
                              if (hasNext)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => controller.loadLesson(
                                      controller.nextLessonId.value!,
                                    ),
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'الدرس التالي',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white10,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Download Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Obx(() {
                                if (controller.isDownloaded.value) {
                                  return const Icon(
                                    Icons.check_circle,
                                    color: Colors.greenAccent,
                                  );
                                }
                                if (controller.isDownloading.value) {
                                  return Text(
                                    '${controller.downloadProgress.value}%',
                                    style: GoogleFonts.cairo(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                                return const Icon(
                                  Icons.download_for_offline_outlined,
                                  color: Colors.white24,
                                );
                              }),
                              Text(
                                'مشاهدة بدون إنترنت',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Obx(() {
                              if (controller.isDownloaded.value) {
                                return OutlinedButton.icon(
                                  onPressed:
                                      () {}, // Already handled by player initialization
                                  icon: const Icon(Icons.play_circle_outline),
                                  label: Text(
                                    'تشغيل من المحملات',
                                    style: GoogleFonts.cairo(),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.greenAccent,
                                    side: const BorderSide(
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                );
                              }

                              if (controller.isDownloading.value) {
                                return Column(
                                  children: [
                                    LinearProgressIndicator(
                                      value:
                                          controller.downloadProgress.value /
                                          100,
                                      backgroundColor: Colors.white10,
                                      color:
                                          Colors.blueAccent, // Changed to blue
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'جاري التحميل...',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.white38,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () =>
                                              controller.pauseDownload(),
                                          icon: const Icon(
                                            Icons.pause,
                                            size: 16,
                                            color: Colors.orangeAccent,
                                          ),
                                          label: Text(
                                            'إيقاف مؤقت',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              color: Colors.orangeAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              if (controller.isPaused.value) {
                                return Column(
                                  children: [
                                    LinearProgressIndicator(
                                      value:
                                          controller.downloadProgress.value /
                                          100,
                                      backgroundColor: Colors.white10,
                                      color: Colors.orangeAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'تم الإيقاف المؤقت',
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.white38,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => controller
                                              .startDownload(), // Resume
                                          icon: const Icon(
                                            Icons.play_arrow,
                                            size: 16,
                                            color: Colors.blueAccent,
                                          ),
                                          label: Text(
                                            'استئناف',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return ElevatedButton.icon(
                                onPressed: () => controller.startDownload(),
                                icon: const Icon(Icons.download),
                                label: Text(
                                  'تحميل الدرس الآن',
                                  style: GoogleFonts.cairo(),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  foregroundColor: primaryColor,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: primaryColor.withOpacity(0.5),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
