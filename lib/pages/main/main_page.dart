import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:podcasts_pro/pages/main/discover.dart';
import 'package:podcasts_pro/pages/main/feed.dart';
import 'package:podcasts_pro/pages/main/main_controller.dart';
import 'package:podcasts_pro/pages/main/me.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/widgets/player_bar.dart';

const List<Widget> pages = <Widget>[
  // DiscoverPage(),
  FeedPage(),
  MePage(),
];

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();

    return GetBuilder<MainController>(builder: (mainController) {
      return Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: mainController.selectedIndex,
              children: pages,
            ),
            Obx(() {
              final hasCurrentEpisode =
                  playerController.currentEpisode.value != null;
              return Padding(
                padding: EdgeInsets.only(bottom: hasCurrentEpisode ? 80 : 0),
                child: pages[mainController.selectedIndex],
              );
            }),
            // Positioned widget to place PlayerBar at the bottom
            Obx(() {
              final hasCurrentEpisode =
                  playerController.currentEpisode.value != null;
              return hasCurrentEpisode
                  ? Align(
                      alignment: Alignment.bottomCenter,
                      child: PlayerBar(), // Bottom playback menu
                    )
                  : const SizedBox
                      .shrink(); // Empty widget if no current episode
            }),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          onTap: (index) => mainController.changeIndex(index),
          currentIndex: mainController.selectedIndex,
          items: const [
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.wifi_tethering), label: '发现'),
            BottomNavigationBarItem(
                icon: Icon(Icons.control_point_duplicate_outlined),
                label: '订阅'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_alt_outlined), label: '我的'),
          ],
        ),
      );
    });
  }
}
