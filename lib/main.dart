import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      1024 * 1024 * 300; //最大300M

  await SharedPreferences
      .getInstance(); // Ensure SharedPreferences is initialized
  runApp(const MyApp());

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // 状态栏透明
    systemNavigationBarColor: Colors.white, // 导航栏颜色
    // systemNavigationBarIconBrightness: Brightness.light, // 导航栏图标亮度
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final String initRoute = mainScreenRoute;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 重新设置导航栏颜色
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white, // 设置为你想要的颜色
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Podcasts Pro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            primary: Colors.black,
            background: Colors.white),
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
