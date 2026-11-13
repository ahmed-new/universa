import 'category_model.dart';
import 'instructor_model.dart';

/// الحالات التي يعيدها الـ API لنافذة المشاهدة.
///
/// عقد الـ API:
/// - `GET /api/mobile/lessons/<id>/` → `viewing_window_state`
/// - `GET /api/mobile/lessons/<id>/viewing-window/` → `state`
///
/// الحقل الغائب أو القيمة غير المعروفة تُترجم إلى [unknown] وليست [disabled]،
/// حتى لا يُفتح التشغيل أونلاين عند فشل التحقق.
class ViewingWindowStates {
  const ViewingWindowStates._();

  static const notStarted = 'not_started';
  static const active = 'active';
  static const expired = 'expired';
  static const disabled = 'disabled';
  static const unknown = 'unknown';
  static const error = 'error';

  /// يحوّل قيمة الحالة الخام إلى إحدى الحالات المعروفة أو [unknown].
  static String normalize(Object? raw) {
    if (raw is! String) return unknown;
    final value = raw.trim().toLowerCase();
    switch (value) {
      case notStarted:
      case active:
      case expired:
      case disabled:
        return value;
      default:
        return unknown;
    }
  }

  /// يقرأ عدد الثواني المتبقية بأمان (int/num/String)، ويرجع `null` عند التلف.
  static int? parseSeconds(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  /// يقرأ تاريخ الانتهاء بصيغة ISO-8601، ويرجع `null` عند التلف.
  static DateTime? parseDate(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }
}

/// استجابة `GET /api/mobile/lessons/<id>/viewing-window/`.
class ViewingWindowInfo {
  final String state;
  final bool? restrictionEnabled;
  final int? remainingSeconds;
  final int? viewingWindowDurationSeconds;
  final DateTime? expiresAt;

  const ViewingWindowInfo({
    required this.state,
    this.restrictionEnabled,
    this.remainingSeconds,
    this.viewingWindowDurationSeconds,
    this.expiresAt,
  });

  factory ViewingWindowInfo.fromJson(Map<String, dynamic> json) {
    return ViewingWindowInfo(
      state: json.containsKey('state')
          ? (json['state'] == null
              ? ViewingWindowStates.unknown
              : ViewingWindowStates.normalize(json['state']))
          : ViewingWindowStates.unknown,
      restrictionEnabled: json['restriction_enabled'] is bool
          ? json['restriction_enabled'] as bool
          : null,
      remainingSeconds:
          ViewingWindowStates.parseSeconds(json['remaining_seconds']),
      viewingWindowDurationSeconds:
          ViewingWindowStates.parseSeconds(json['viewing_window_duration_seconds']),
      expiresAt: ViewingWindowStates.parseDate(json['expires_at']),
    );
  }
}

class Subject {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String coverImage;
  final bool isEnrolled;
  final String enrollmentStatus;
  final Instructor instructor;
  final Category category;
  final List<Course> courses;

  Subject({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.coverImage,
    required this.isEnrolled,
    required this.enrollmentStatus,
    required this.instructor,
    required this.category,
    this.courses = const [],
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    var coursesList = <Course>[];
    if (json['courses'] != null) {
      coursesList = (json['courses'] as List)
          .map((courseJson) => Course.fromJson(courseJson))
          .toList();
    }

    return Subject(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      coverImage: json['cover_image'] != null 
          ? json['cover_image'].toString().trim() 
          : '',
      isEnrolled: json['is_enrolled'] ?? false,
      enrollmentStatus: json['enrollment_status']?.toString() ?? '',
      instructor: json['instructor'] != null
          ? Instructor.fromJson(json['instructor'])
          : Instructor(id: 0, username: '', fullName: ''),
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : Category(id: 0, name: '', slug: ''),
      courses: coursesList,
    );
  }
}

class Course {
  final int id;
  final String title;
  final int orderIndex;
  final List<Lesson> lessons;

  Course({
    required this.id,
    required this.title,
    required this.orderIndex,
    required this.lessons,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    var lessonsList = <Lesson>[];
    if (json['lessons'] != null) {
      lessonsList = (json['lessons'] as List)
          .map((lessonJson) => Lesson.fromJson(lessonJson))
          .toList();
    }
    return Course(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      lessons: lessonsList,
    );
  }
}

class Lesson {
  final int id;
  final String title;
  final int orderIndex;
  final int? durationSeconds;
  final bool isFreePreview;
  final bool isCompleted;
  final String? videoUrl;
  final String? directHlsUrl;
  final String? downloadUrl;
  final bool streamingLocked;

  /// الحالة المعيارية لنافذة المشاهدة، انظر [ViewingWindowStates].
  final String viewingWindowState;
  final int? viewingWindowRemainingSeconds;
  final int? viewingWindowDurationSeconds;
  final DateTime? viewingWindowExpiresAt;
  final String? pdfUrl;
  final String? externalExamUrl;

  Lesson({
    required this.id,
    required this.title,
    required this.orderIndex,
    this.durationSeconds,
    required this.isFreePreview,
    required this.isCompleted,
    this.videoUrl,
    this.directHlsUrl,
    this.downloadUrl,
    this.streamingLocked = false,
    this.viewingWindowState = ViewingWindowStates.unknown,
    this.viewingWindowRemainingSeconds,
    this.viewingWindowDurationSeconds,
    this.viewingWindowExpiresAt,
    this.pdfUrl,
    this.externalExamUrl,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      orderIndex: json['order_index'] ?? 0,
      durationSeconds: json['duration_seconds'],
      isFreePreview: json['is_free_preview'] ?? false,
      isCompleted: json['is_completed'] ?? false,
      videoUrl: json['video_url'],
      directHlsUrl: json['direct_hls_url'],
      downloadUrl: json['download_url'],
      streamingLocked: json['streaming_locked'] ?? false,
      // العقد الفعلي: viewing_window_state. الحقل الغائب => unknown
      // الحقل الموجود بقيمة null => unknown (خطأ/غير محدد).
      viewingWindowState: json.containsKey('viewing_window_state')
          ? (json['viewing_window_state'] == null
              ? ViewingWindowStates.unknown
              : ViewingWindowStates.normalize(json['viewing_window_state']))
          : ViewingWindowStates.unknown,
      viewingWindowRemainingSeconds: ViewingWindowStates.parseSeconds(
        json['viewing_window_remaining_seconds'],
      ),
      viewingWindowDurationSeconds: ViewingWindowStates.parseSeconds(
        json['viewing_window_duration_seconds'],
      ),
      viewingWindowExpiresAt:
          ViewingWindowStates.parseDate(json['viewing_window_expires_at']),
      pdfUrl: json['pdf_url'],
      externalExamUrl: json['external_exam_url'],
    );
  }
}
