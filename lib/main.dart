import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/content_service.dart';
import 'app/data/services/download_service.dart';
import 'app/data/services/ad_service.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Services
  final authService = Get.put(AuthService(), permanent: true);
  Get.put(ContentService(), permanent: true);
  Get.put(DownloadService(), permanent: true);
  await Get.putAsync(() => AdService().init(), permanent: true);

  // Check login status and first time
  final isFirstTime = await authService.isFirstTime();
  final isLoggedIn = await authService.isLoggedIn();

  String initialRoute;
  if (isFirstTime) {
    initialRoute = Routes.ONBOARDING;
  } else {
    initialRoute = isLoggedIn ? Routes.DASHBOARD : Routes.LOGIN;
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    // Website colors from image
    const backgroundColor = Color(0xFF13111C); // Deep Dark Blue/Purple
    const primaryPurple = Color(0xFF8B5CF6); // Bright Purple
    const secondaryCyan = Color(0xFF2DD4BF); // Teal/Cyan
    const surfaceColor = Color(0xFF1E1B2E); // Slightly lighter purple/dark

    return GetMaterialApp(
      title: 'Universa Academy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primaryPurple,
          secondary: secondaryCyan,
          surface: surfaceColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: Colors.white.withOpacity(0.9),
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      locale: const Locale('ar', 'SA'),
      fallbackLocale: const Locale('ar', 'SA'),
      defaultTransition: Transition.cupertino,
    );
  }
}

