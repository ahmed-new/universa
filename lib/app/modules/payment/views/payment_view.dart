import 'dart:io';
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
          Platform.isIOS ? 'تفعيل الكورس - ${controller.subject.name}' : 'الدفع - ${controller.subject.name}',
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
        child: Obx(() {
          if (Platform.isIOS) {
            return _buildIOSActivationSection(primaryColor);
          } else if (controller.paymentDetails.value == null) {
            return _buildInitiatePaymentSection(primaryColor);
          } else {
            return _buildConfirmPaymentSection(primaryColor);
          }
        }),
      ),
    );
  }

  Widget _buildIOSActivationSection(Color primaryColor) {
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

  Widget _buildInitiatePaymentSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoCard(
          'المحاضر: ${controller.subject.instructor.fullName}',
          'السعر: ${controller.subject.priceEgp} ج.م',
        ),
        const SizedBox(height: 24),

        // Coupon Section
        Text(
          'كوبون الخصم (اختياري)',
          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: controller.isCheckingCoupon.value
                  ? null
                  : () => controller.checkCoupon(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                elevation: 0,
              ),
              child: controller.isCheckingCoupon.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('تحقق', style: GoogleFonts.cairo(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller.couponController,
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'مثال: SAVE20',
                  hintStyle: GoogleFonts.cairo(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1A1A2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
          ],
        ),

        // Coupon Result/Error
        if (controller.couponError.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              controller.couponError.value!,
              style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),

        const SizedBox(height: 24),

        // Price Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildPriceRow('السعر الأصلي', controller.subject.priceEgp),
              if (controller.couponResult.value != null) ...[
                const SizedBox(height: 8),
                _buildPriceRow(
                  'الخصم',
                  controller.couponResult.value!['discount'].toString(),
                  color: Colors.greenAccent,
                ),
                const Divider(color: Colors.white10, height: 24),
                _buildPriceRow(
                  'الإجمالي',
                  controller.couponResult.value!['final_price'].toString(),
                  isBold: true,
                ),
              ] else ...[
                const Divider(color: Colors.white10, height: 24),
                _buildPriceRow(
                  'الإجمالي',
                  controller.subject.priceEgp,
                  isBold: true,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),

        ElevatedButton.icon(
          onPressed: controller.isInitiatingPayment.value
              ? null
              : () => controller.initiatePayment(),
          icon: const Icon(Icons.payment),
          label: controller.isInitiatingPayment.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  Platform.isIOS
                      ? 'متابعة تفعيل الاشتراك'
                      : 'ابدأ الدفع والاشتراك',
                  style: GoogleFonts.cairo(),
                ),
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

  Widget _buildConfirmPaymentSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Instructions
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
                Platform.isIOS
                    ? 'خطوات تفعيل الكورس'
                    : 'خطوات تفعيل الاشتراك في الكورس',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 12),
              if (Platform.isIOS) ...[
                _buildStepItem(
                  '1. ادخل كود تفعيل الكورس الخاص بك في الخانة المخصصة.',
                ),
                _buildStepItem('2. اضغط على زر التحقق والتأكيد لتفعيل الكورس.'),
                _buildStepItem(
                  '3. يتم فتح وتفعيل المحتوى التعليمي مباشرة في حسابك.',
                ),
              ] else ...[
                _buildStepItem(
                  '1. ادخل كود التفعيل أو ادفع قيمة الكورس للمحاضر.',
                ),
                _buildStepItem(
                  '2. انسخ الكود المرجعي وضعه في ملاحظات التفعيل.',
                ),
                _buildStepItem('3. بعد إدخال الكود، ارجع هنا لتأكيد العملية.'),
                _buildStepItem(
                  '4. بعد اعتماد العملية، يتم تفعيل اشتراكك تلقائياً.',
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Amount to Pay Display
        if (controller.paymentDetails.value?['amount_to_pay'] != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${controller.paymentDetails.value!['amount_to_pay']} ج.م',
                  style: GoogleFonts.cairo(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'المبلغ المطلوب',
                  style: GoogleFonts.cairo(
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // External Link Button
        if (!Platform.isIOS)
          ElevatedButton.icon(
            onPressed: () => controller.openInstaPayLink(),
            icon: const Icon(Icons.open_in_new),
            label: Text('متابعة بوابة التحويل', style: GoogleFonts.cairo()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Ref Code to Copy
        if (controller.paymentDetails.value?['ref_code'] != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.amber, size: 20),
                  onPressed: () => controller.copyReferenceCode(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الكود المرجعي (ضعه في ملاحظات التحويل)',
                        style: GoogleFonts.cairo(
                          color: Colors.amber,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        controller.paymentDetails.value!['ref_code'],
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 32),

        Text(
          'تأكيد التحويل',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 16),

        // Gateway Ref Input
        TextField(
          controller: controller.gatewayRefController,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'مرجع العملية (من التطبيق)',
            labelStyle: GoogleFonts.cairo(color: Colors.white60),
            hintText: 'مثال: رقم/مرجع يظهر لك بعد التحويل',
            hintStyle: GoogleFonts.cairo(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Payer Note Input
        TextField(
          controller: controller.payerNoteController,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(color: Colors.white),
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'ملاحظة الطالب (اختياري)',
            labelStyle: GoogleFonts.cairo(color: Colors.white60),
            hintText: 'يفضل لصق كود المرجع هنا أيضاً',
            hintStyle: GoogleFonts.cairo(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Receipt Image Picker
        Text(
          'رفع صورة الإيصال (اختياري)',
          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => controller.pickImage(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Choose File',
                    style: GoogleFonts.cairo(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    controller.receiptImage.value != null
                        ? controller.receiptImage.value!.path.split('/').last
                        : 'No file chosen',
                    style: GoogleFonts.cairo(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        ElevatedButton.icon(
          onPressed: controller.isConfirmingPayment.value
              ? null
              : () => controller.confirmPayment(),
          icon: const Icon(Icons.send),
          label: controller.isConfirmingPayment.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('إرسال التأكيد', style: GoogleFonts.cairo()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'بعد الإرسال، سيقوم المحاضر بمراجعة العملية واعتمادها، ليتم تفعيل اشتراكك تلقائياً.',
          style: GoogleFonts.cairo(color: Colors.white38, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 50),
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

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            color: color ?? Colors.white,
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.white70,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
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
