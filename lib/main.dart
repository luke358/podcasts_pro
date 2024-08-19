import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/constants/routes.dart';
import 'package:podcasts_pro/pages/main/favorite_controller.dart';
import 'package:podcasts_pro/pages/main/listen_history_controller.dart';
import 'package:podcasts_pro/pages/main/main_page.dart';
import 'package:podcasts_pro/pages/main/playback_position_controller.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/pages/main/subscription_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/main/main_controller.dart';

void main() async {
  await initializeGetX();

  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences
      .getInstance(); // Ensure SharedPreferences is initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  final String initRoute = mainScreenRoute;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Podcasts Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0.0,
          backgroundColor: Colors.white, // 固定颜色
        ),
        useMaterial3: true,
      ),
      initialRoute: initRoute,
      routes: {mainScreenRoute: (context) => const MainPage()},
    );
  }
}

Future? initializeGetX() async {
  // Initialize the controllers
  Get.put(MainController());
  Get.put(SubscriptionController());
  Get.put(ListenHistoryController());
  Get.put(FavoriteController());
  Get.put(PlaybackPositionController());
  Get.put(PlayerController());
}
