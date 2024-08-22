import 'package:flutter/material.dart';
import 'package:podcasts_pro/config/route.dart';
import 'package:podcasts_pro/pages/add_subscription.dart';
import 'package:podcasts_pro/pages/favorites.dart';
import 'package:podcasts_pro/pages/listen_history.dart';
import 'package:podcasts_pro/pages/playlist.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  _MePageState createState() => _MePageState();
}

class _MePageState extends State<MePage>
    with AutomaticKeepAliveClientMixin<MePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              title: const Text('收听记录'),
              onTap: () {
                Navigator.push(
                  context,
                  Right2LeftPageRoute(page: ListenHistoryPage()),
                );
              },
            ),
            ListTile(
              title: const Text('我的收藏'),
              onTap: () {
                Navigator.push(
                  context,
                  Right2LeftPageRoute(page: FavoritesPage()),
                );
              },
            ),
            ListTile(
              title: const Text('RSS地址订阅'),
              onTap: () {
                Navigator.push(
                  context,
                  Right2LeftPageRoute(page: AddSubscriptionPage()),
                );
              },
            ),
            ListTile(
              title: const Text('播放列表'),
              onTap: () {
                Navigator.push(
                  context,
                  Right2LeftPageRoute(page: PlaylistPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
