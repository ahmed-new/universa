import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/logger_service.dart';
import '../../../data/models/subject_model.dart';

class PaymentController extends GetxController {
  final PaymentService _paymentService = Get.find<PaymentService>();

  final Subject subject = Get.arguments as Subject;
  
  // Coupon / Activation Code
  final couponController = TextEditingController();
  final isCheckingCoupon = false.obs;
  final couponResult = Rxn<Map<String, dynamic>>();
  final couponError = RxnString();

  @override
  void onClose() {
    couponController.dispose();
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
          couponError.value = 'كود غير صالح';
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
        Get.back(result: true);
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
}

