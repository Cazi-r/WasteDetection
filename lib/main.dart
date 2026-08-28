import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/routes/app_routes.dart';
import 'services/preferences_service.dart';
import 'services/history_service.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/new_home_screen.dart';
import 'ui/screens/camera_screen.dart';
import 'ui/screens/result_screen.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/info_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await PreferencesService.init();
  await HistoryService.init();

  // Initialize Turkish date formatting
  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atık Tanıma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.home: (context) => const NewHomeScreen(),
        AppRoutes.camera: (context) => const CameraScreen(),
        AppRoutes.result: (context) => const ResultScreen(),
        AppRoutes.history: (context) => const HistoryScreen(),
        AppRoutes.info: (context) => const InfoScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
      },
    );
  }
}
