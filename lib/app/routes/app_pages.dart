import 'package:get/get.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/onboarding/controllers/onboarding_controller.dart';
import '../modules/register/views/register_view.dart';
import '../modules/register/controllers/register_controller.dart';
import '../modules/login/views/login_view.dart';
import '../modules/login/controllers/login_controller.dart';
import '../modules/home/controllers/home_controller.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/profile/controllers/profile_controller.dart';
import '../modules/about/views/about_view.dart';
import '../modules/about/controllers/about_controller.dart';
import '../modules/subject_details/views/subject_details_view.dart';
import '../modules/subject_details/controllers/subject_details_controller.dart';
import '../modules/lesson_details/views/lesson_details_view.dart';
import '../modules/lesson_details/controllers/lesson_details_controller.dart';
import '../modules/downloaded_videos/views/downloaded_videos_view.dart';
import '../modules/downloaded_videos/controllers/downloaded_videos_controller.dart';
import '../modules/offline_player/views/offline_player_view.dart';
import '../modules/offline_player/controllers/offline_player_controller.dart';
import '../modules/my_enrollments/views/my_enrollments_view.dart';
import '../modules/my_enrollments/bindings/my_enrollments_binding.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.ONBOARDING;

  static final routes = [
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OnboardingController());
      }),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => RegisterController());
      }),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LoginController());
      }),
    ),
    GetPage(
      name: _Paths.DASHBOARD,
      page: () => const DashboardView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DashboardController());
        Get.lazyPut(() => HomeController());
        Get.lazyPut(() => ProfileController());
        Get.lazyPut(() => DownloadedVideosController());
      }),
    ),
    GetPage(
      name: _Paths.ABOUT,
      page: () => const AboutView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => AboutController());
      }),
    ),
    GetPage(
      name: _Paths.SUBJECT_DETAILS,
      page: () => const SubjectDetailsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => SubjectDetailsController());
      }),
    ),
    GetPage(
      name: _Paths.LESSON_DETAILS,
      page: () => const LessonDetailsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => LessonDetailsController());
      }),
    ),
    GetPage(
      name: _Paths.DOWNLOADED_VIDEOS,
      page: () => const DownloadedVideosView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => DownloadedVideosController());
      }),
    ),
    GetPage(
      name: _Paths.OFFLINE_PLAYER,
      page: () => const OfflinePlayerView(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => OfflinePlayerController());
      }),
    ),
    GetPage(
      name: _Paths.MY_ENROLLMENTS,
      page: () => const MyEnrollmentsView(),
      binding: MyEnrollmentsBinding(),
    ),
  ];
}

