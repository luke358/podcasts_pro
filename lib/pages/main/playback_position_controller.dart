import 'dart:convert';

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackPositionController extends GetxController {
  final playbackPositions = <String, Duration>{}.obs;

  @override
  void onInit() async {
    await loadPlaybackPositions();
    super.onInit();
  }

  Duration? getPlaybackPosition(String? url) {
    return playbackPositions[url];
  }

  Future<void> savePlaybackPosition(String url, Duration position) async {
    playbackPositions[url] = position;
    savePlaybackPositions();
  }

  Future<void> savePlaybackPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        json.encode(playbackPositions.map((k, v) => MapEntry(k, v.inSeconds)));
    await prefs.setString('playback_positions', jsonString);
  }

  Future<void> loadPlaybackPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('playback_positions');
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      playbackPositions.clear();
      jsonMap.forEach((key, value) {
        playbackPositions[key] = Duration(seconds: value);
      });
    }
  }
}
