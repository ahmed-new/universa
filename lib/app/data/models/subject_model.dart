import 'category_model.dart';
import 'instructor_model.dart';

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
      pdfUrl: json['pdf_url'],
      externalExamUrl: json['external_exam_url'],
    );
  }
}
