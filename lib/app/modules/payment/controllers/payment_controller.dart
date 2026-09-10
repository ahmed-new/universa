import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/logger_service.dart';
import '../../../data/models/subject_model.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = Get.find<PaymentService>();

  final Subject subject = Get.arguments as Subject;
  
  // Coupon
  final couponController = TextEditingController();
  final isCheckingCoupon = false.obs;
  final couponResult = Rxn<Map<String, dynamic>>();
  final couponError = RxnString();

  // Payment Initiation
  final isInitiatingPayment = false.obs;
  final paymentDetails = Rxn<Map<String, dynamic>>();

  // Payment Confirmation
  final gatewayRefController = TextEditingController();
  final payerNoteController = TextEditingController();
  final receiptImage = Rxn<File>();
  final isConfirmingPayment = false.obs;

  @override
  void onClose() {
    couponController.dispose();
    gatewayRefController.dispose();
    payerNoteController.dispose();
    super.onClose();
  }

  Future<void> checkCoupon() async {
    final code = couponController.text.trim();
    if (code.isEmpty) return;

    isCheckingCoupon.value = true;
    couponError.value = null;
    couponResult.value = null;

    try {
      final result = await _paymentService.checkCoupon(code, subject.id);
      if (result != null) {
        if (result['valid'] == true) {
          couponResult.value = result;
        } else if (result['error'] != null) {
          couponError.value = result['error'];
        } else {
          couponError.value = 'كوبون غير صالح';
        }
      } else {
        couponError.value = 'حدث خطأ في الاتصال بالخادم، يرجى التأكد من الإنترنت';
      }
    } catch (e) {
      couponError.value = 'حدث خطأ غير متوقع، يرجى التأكد من اتصالك بالإنترنت';
    } finally {
      isCheckingCoupon.value = false;
    }
  }

  Future<void> activateWithCode() async {
    final code = couponController.text.trim();
    if (code.isEmpty) {
      couponError.value = 'يرجى إدخال كود التفعيل الخاص بالكورس';
      return;
    }

    isCheckingCoupon.value = true;
    couponError.value = null;

    try {
      final result = await _paymentService.checkCoupon(code, subject.id);
      if (result != null && result['valid'] == true) {
        couponResult.value = result;
        LoggerService().success('تم تفعيل الكورس بنجاح!', title: 'تفعيل الكورس');
        Get.back();
      } else if (result != null && result['error'] != null) {
        couponError.value = result['error'];
      } else {
        couponError.value = 'كود التفعيل غير صحيح أو تم استخدامه سابقاً';
      }
    } catch (e) {
      couponError.value = 'حدث خطأ أثناء تفعيل الكود، يرجى التأكد من الاتصال بالإنترنت';
    } finally {
      isCheckingCoupon.value = false;
    }
  }

  Future<void> initiatePayment() async {
    isInitiatingPayment.value = true;
    try {
      final result = await _paymentService.initiatePayment(
        subject.id,
        couponResult.value != null ? couponResult.value!['code'] : null,
      );
      
      if (result != null) {
        paymentDetails.value = result;
      } else {
        LoggerService().error('فشل في بدء عملية الدفع', title: 'خطأ');
      }
    } finally {
      isInitiatingPayment.value = false;
    }
  }

  Future<void> openInstaPayLink() async {
    if (Platform.isIOS) return;
    final link = paymentDetails.value?['instapay_link'];
    if (link != null) {
      try {
        final uri = Uri.parse(link);
        final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          LoggerService().warning('تعذر فتح الرابط الخارجي', title: 'تنبيه');
        }
      } catch (e) {
        LoggerService().warning('تعذر فتح الرابط الخارجي', title: 'تنبيه');
      }
    }
  }

  Future<void> copyReferenceCode() async {
    final refCode = paymentDetails.value?['ref_code'];
    if (refCode != null) {
      await Clipboard.setData(ClipboardData(text: refCode));
      LoggerService().success('تم نسخ الكود المرجعي بنجاح', title: 'تم النسخ');
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      receiptImage.value = File(pickedFile.path);
    }
  }

  Future<void> confirmPayment() async {
    if (paymentDetails.value == null) {
      LoggerService().error('يرجى بدء عملية الدفع أولاً (اضغط على زر البدء)', title: 'خطأ');
      return;
    }

    if (gatewayRefController.text.isEmpty) {
      LoggerService().warning('يرجى إدخال الرقم المرجعي للعملية', title: 'تنبيه');
      return;
    }

    isConfirmingPayment.value = true;
    try {
      final paymentId = paymentDetails.value!['payment_id'];
      if (paymentId == null) {
        LoggerService().error('بيانات الدفع غير مكتملة، يرجى المحاولة مرة أخرى', title: 'خطأ');
        return;
      }

      final result = await _paymentService.confirmPayment(
        paymentId: paymentId,
        gatewayRef: gatewayRefController.text.trim(),
        payerNote: payerNoteController.text.trim(),
        receiptImage: receiptImage.value,
      );

      if (result != null && result['detail'] != null && result['detail'].toString().contains('تم إرسال')) {
        LoggerService().success(result['detail'], title: 'تم بنجاح');
        // Wait a bit and then go back
        await Future.delayed(const Duration(seconds: 3));
        Get.back(result: true); // Close payment page and notify caller of success
      } else {
        LoggerService().error(result?['detail'] ?? 'فشل تأكيد الدفع، تأكد من الاتصال بالإنترنت', title: 'خطأ');
      }
    } catch (e) {
      LoggerService().error('حدث خطأ غير متوقع: تأكد من اتصالك بالإنترنت', title: 'خطأ');
    } finally {
      isConfirmingPayment.value = false;
    }
  }
}
