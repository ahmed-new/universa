import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:universa/app/data/services/logger_service.dart';
import '../controllers/subject_details_controller.dart';
import '../../../data/models/subject_model.dart';
import '../../../routes/app_pages.dart';

class SubjectDetailsView extends GetView<SubjectDetailsController> {
  const SubjectDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingState();
        }

        final subject = controller.subject.value;
        if (subject == null) {
          return _buildErrorState();
        }

        return CustomScrollView(
          slivers: [
            _buildSliverAppBar(subject, primaryColor, secondaryColor),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildSubjectInfo(subject),
                    const SizedBox(height: 30),
                    Text(
                      'محتوى المادة',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCoursesList(subject.courses, primaryColor, secondaryColor),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        if (controller.isLoading.value || controller.subject.value == null) {
          return const SizedBox.shrink();
        }
        return _buildBottomAction(controller.subject.value!);
      }),
    );
  }

  Widget _buildSliverAppBar(Subject subject, Color primaryColor, Color secondaryColor) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (subject.coverImage.isNotEmpty)
              Image.network(
                subject.coverImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1A1A2E)),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF12121A).withOpacity(0.8),
                    const Color(0xFF12121A),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectInfo(Subject subject) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4A148C).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF4A148C).withOpacity(0.5)),
          ),
          child: Text(
            subject.category.name,
            style: GoogleFonts.cairo(color: const Color(0xFFB39DDB), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subject.name,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'المحاضر: ${subject.instructor.fullName}',
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.person_outline, color: Colors.cyanAccent, size: 20),
          ],
        ),
        if (subject.description.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            subject.description,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(color: Colors.white60, fontSize: 14, height: 1.6),
          ),
        ],
      ],
    );
  }

  Widget _buildCoursesList(List<Course> courses, Color primaryColor, Color secondaryColor) {
    if (courses.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد محتوى متاح حالياً',
          style: GoogleFonts.cairo(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final course = courses[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ExpansionTile(
            collapsedIconColor: Colors.white70,
            iconColor: primaryColor,
            title: Text(
              course.title,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            children: course.lessons.map((lesson) => _buildLessonItem(lesson, primaryColor)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildLessonItem(Lesson lesson, Color primaryColor) {
    final isEnrolled = controller.subject.value?.isEnrolled ?? false;
    final isUnlocked = lesson.isFreePreview || isEnrolled;
    final isCompleted = lesson.isCompleted;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: isUnlocked
        ? (isCompleted
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                ),
                child: const Icon(Icons.check, color: Colors.greenAccent, size: 16),
              )
            : (lesson.isFreePreview 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Text(
                      'مجاني',
                      style: GoogleFonts.cairo(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                : const Icon(Icons.play_circle_outline_rounded, color: Colors.blueAccent, size: 22)))
        : const Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 18),
      title: Text(
        lesson.title,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          color: isCompleted ? Colors.greenAccent : Colors.white70,
          decoration: isCompleted ? TextDecoration.none : null, // Optional: lineThrough if desired, but green is usually enough
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: isUnlocked ? Colors.white54 : Colors.white12,
        size: 16,
      ),
      onTap: () {
        if (isUnlocked) {
          Get.toNamed(Routes.LESSON_DETAILS, arguments: lesson.id);
        } else {
          LoggerService().warning('يجب الاشتراك في المادة لمشاهدة هذا الدرس', title: 'عفواً');
        }
      },
    );
  }

  Widget _buildBottomAction(Subject subject) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: subject.isEnrolled 
          ? Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'أنت مشترك في هذه المادة',
                      style: GoogleFonts.cairo(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.greenAccent
                      ),
                    ),
                  ],
                ),
              ),
            )
          : (subject.enrollmentStatus == 'pending'
              ? Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hourglass_empty_rounded, color: Colors.orangeAccent, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'طلب الاشتراك قيد المراجعة',
                          style: GoogleFonts.cairo(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.orangeAccent
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Get.toNamed(Routes.PAYMENT, arguments: subject);
                    if (result == true) {
                      controller.fetchSubjectDetails();
                    }
                  },
                  icon: const Icon(Icons.vpn_key_rounded, color: Colors.white),
                  label: Text(
                    'تفعيل الكورس بكود التفعيل',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[800]!,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 300, color: Colors.black),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(5, (index) => Container(
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ في تحميل البيانات',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.fetchSubjectDetails(),
            child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}
