part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const ONBOARDING = _Paths.ONBOARDING;
  static const REGISTER = _Paths.REGISTER;
  static const LOGIN = _Paths.LOGIN;
  static const DASHBOARD = _Paths.DASHBOARD;
  static const ABOUT = _Paths.ABOUT;
  static const SUBJECT_DETAILS = _Paths.SUBJECT_DETAILS;
  static const LESSON_DETAILS = _Paths.LESSON_DETAILS;
  static const DOWNLOADED_VIDEOS = _Paths.DOWNLOADED_VIDEOS;
  static const OFFLINE_PLAYER = _Paths.OFFLINE_PLAYER;
  static const MY_ENROLLMENTS = _Paths.MY_ENROLLMENTS;
}

abstract class _Paths {
  _Paths._();
  static const ONBOARDING = '/onboarding';
  static const REGISTER = '/register';
  static const LOGIN = '/login';
  static const DASHBOARD = '/dashboard';
  static const ABOUT = '/about';
  static const SUBJECT_DETAILS = '/subject-details';
  static const LESSON_DETAILS = '/lesson-details';
  static const DOWNLOADED_VIDEOS = '/downloaded-videos';
  static const OFFLINE_PLAYER = '/offline-player';
  static const MY_ENROLLMENTS = '/my-enrollments';
}
