import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/services/auth_service.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  final profile = Rxn<Profile>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final data = await _authService.getProfile();
      profile.value = data;
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'تأكيد تسجيل الخروج',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _authService.logout();
              Get.offAllNamed('/login');
            },
            child: Text(
              'تسجيل الخروج',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void deleteAccount() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'تأكيد حذف الحساب',
          style: GoogleFonts.cairo(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف الحساب بشكل نهائي؟ سيتم حذف كافة بياناتك وصلاحيات الوصول المرتبطة بحسابك ولا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _authService.logout();
              Get.offAllNamed('/login');
              Get.snackbar(
                'حذف الحساب',
                'تم تقديم طلب حذف الحساب وتسجيل الخروج بنجاح',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.redAccent,
                colorText: Colors.white,
              );
            },
            child: Text(
              'حذف الحساب نهائياً',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

