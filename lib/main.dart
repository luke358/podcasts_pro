import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:podcasts_pro/config/theme.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ));
    }
  }

  final ThemeData _themeData = ThemeData(
    primaryColor: ThemeColor.active, // 主题色
    scaffoldBackgroundColor: ThemeColor.page, // 脚手架下的页面背景色
    indicatorColor: ThemeColor.active, // 选项卡栏中所选选项卡指示器的颜色。
    // ElevatedButton 主题
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        // 文字颜色
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return ThemeColor.page;
        }),
        // 背景色
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return ThemeColor.primary.withOpacity(0.5);
          } else {
            return ThemeColor.primary;
          }
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            foregroundColor:
                WidgetStateProperty.resolveWith((states) => ThemeColor.text),
            textStyle: WidgetStateProperty.resolveWith(
              (states) {
                return const TextStyle(color: ThemeColor.text);
              },
            ),
            iconColor: WidgetStateProperty.resolveWith((states) {
              return ThemeColor.text;
            }))),
    hintColor: ThemeColor.primary, // 小部件的前景色（旋钮，文本，过度滚动边缘效果等）
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.white.withOpacity(0.5),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: ThemeColor.text,
      ),
    ),
    tabBarTheme: const TabBarTheme(
      unselectedLabelColor: ThemeColor.unactive,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontSize: 18,
      ),
      labelPadding: EdgeInsets.symmetric(horizontal: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ThemeColor.nav,
      scrolledUnderElevation: 0,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ThemeColor.nav,
      selectedItemColor: ThemeColor.active,
      unselectedItemColor: ThemeColor.unactive,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
      ),
    ),
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Podcasts Pro',
      theme: _themeData,
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
