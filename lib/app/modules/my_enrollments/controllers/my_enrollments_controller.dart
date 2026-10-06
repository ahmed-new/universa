import 'package:get/get.dart';
import '../../../data/models/enrollment_model.dart';
import '../../../data/services/content_service.dart';

class MyEnrollmentsController extends GetxController {
  final ContentService _contentService = Get.find<ContentService>();

  final enrollments = <Enrollment>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchEnrollments();
  }

  Future<void> fetchEnrollments() async {
    isLoading.value = true;
    try {
      final list = await _contentService.getMyEnrollments();
      enrollments.assignAll(list);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل المواد المتاحة لحسابك');
    } finally {
      isLoading.value = false;
    }
  }
}
