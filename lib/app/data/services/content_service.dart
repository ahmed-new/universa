import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/subject_model.dart';
import '../models/category_model.dart';
import '../models/instructor_model.dart';
import '../models/enrollment_model.dart';

class ContentService extends GetxService {
  final String _baseUrl = 'https://universa-academy.site';
  final AuthService _authService = Get.find<AuthService>();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Subject>> getSubjects({
    String? categorySlug,
    int? instructorId,
  }) async {
    String url = '$_baseUrl/api/mobile/subjects/';

    // Build query parameters
    List<String> queryParams = [];
    if (categorySlug != null && categorySlug.isNotEmpty) {
      queryParams.add('category=$categorySlug');
    }
    if (instructorId != null) {
      queryParams.add('instructor=$instructorId');
    }

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Subject.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      debugPrint('Error fetching subjects: $e');
      return [];
    }
  }

  Future<List<Category>> getCategories() async {
    final url = '$_baseUrl/api/mobile/categories/';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Instructor>> getInstructors() async {
    final url = '$_baseUrl/api/mobile/instructors/';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Instructor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load instructors');
      }
    } catch (e) {
      debugPrint('Error fetching instructors: $e');
      return [];
    }
  }

  Future<Subject?> getSubjectDetails(String slug) async {
    final url = '$_baseUrl/api/mobile/subjects/$slug';
    final headers = await _getHeaders();

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return Subject.fromJson(data);
      } else {
        throw Exception('Failed to load subject details');
      }
    } catch (e) {
      debugPrint('Error fetching subject details: $e');
      return null;
    }
  }

  Future<Lesson?> getLessonDetails(int lessonId) async {
    final url = '$_baseUrl/api/mobile/lessons/$lessonId/';
    final headers = await _getHeaders();
    headers['X-Video-Capabilities'] = 'separate-download-v1';

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
        return Lesson.fromJson(data);
      } else {
        throw Exception('Failed to load lesson details');
      }
    } catch (e) {
      debugPrint('Error fetching lesson details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getViewingWindowStatus(int lessonId) async {
    final url = '$_baseUrl/api/mobile/lessons/$lessonId/viewing-window/';
    final headers = await _getHeaders();

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to get viewing window status');
      }
    } catch (e) {
      debugPrint('Error getting viewing window status: $e');
      return {'status': 'error'};
    }
  }

  Future<Map<String, dynamic>> startViewingWindow(int lessonId) async {
    final url = '$_baseUrl/api/mobile/lessons/$lessonId/viewing-window/';
    final headers = await _getHeaders();

    try {
      final response = await http.post(Uri.parse(url), headers: headers);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to start viewing window');
      }
    } catch (e) {
      debugPrint('Error starting viewing window: $e');
      return {'ok': false, 'detail': 'حدث خطأ غير متوقع'};
    }
  }

  Future<Map<String, dynamic>> completeLesson(int lessonId) async {
    final url = '$_baseUrl/api/mobile/lessons/$lessonId/complete/';
    final headers = await _getHeaders();

    try {
      final response = await http.post(Uri.parse(url), headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint('Error completing lesson: $e');
      return {'ok': false, 'detail': 'حدث خطأ غير متوقع'};
    }
  }

  Future<List<Enrollment>> getMyEnrollments() async {
    final url = '$_baseUrl/api/mobile/my-enrollments/';
    final headers = await _getHeaders();

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Enrollment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load enrollments');
      }
    } catch (e) {
      debugPrint('Error fetching enrollments: $e');
      return [];
    }
  }
}
