import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/payment_controller.dart';

class PaymentView extends GetView<PaymentController> {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF12121A),
      appBar: AppBar(
        title: Text(
          'تفعيل الكورس - ${controller.subject.name}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() => _buildActivationSection(primaryColor)),
      ),
    );
  }

  Widget _buildActivationSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoCard(
          'المحاضر: ${controller.subject.instructor.fullName}',
          'الكورس: ${controller.subject.name}',
        ),
        const SizedBox(height: 24),

        // Activation Code Section
        Text(
          'إدخال كود تفعيل الكورس',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.couponController,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'ادخل كود التفعيل هنا (مثال: CODE2026)',
            hintStyle: GoogleFonts.cairo(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            prefixIcon: const Icon(Icons.vpn_key_rounded, color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        if (controller.couponError.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              controller.couponError.value!,
              style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),

        const SizedBox(height: 24),

        // Instructions Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'خطوات تفعيل الكورس',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              _buildStepItem('1. ادخل كود تفعيل الكورس الخاص بك في الخانة أعلاه.'),
              _buildStepItem('2. اضغط على زر "تأكيد تفعيل الكورس" بالأسفل.'),
              _buildStepItem('3. يتم فتح وتفعيل المحتوى التعليمي مباشرة في حسابك.'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        ElevatedButton.icon(
          onPressed: controller.isCheckingCoupon.value
              ? null
              : () => controller.activateWithCode(),
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: controller.isCheckingCoupon.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('تأكيد تفعيل الكورس', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String line1, String line2) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            line1,
            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            line2,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: Colors.white70,
          fontSize: 12,
          height: 1.5,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}

