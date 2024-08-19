import 'dart:convert';

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListenHistoryController extends GetxController {
  // 新增：收听记录列表
  var listenHistory = <Episode>[].obs;

  @override
  void onInit() async {
    await loadListenHistory();
    super.onInit();
  }

  // 新增：将播放的集添加到收听记录
  void addEpisodeToListenHistory(Episode episode) {
    listenHistory.removeWhere((e) => e.audioUrl == episode.audioUrl);
    listenHistory.insert(0, episode); // 最新的放在最前面

    if (listenHistory.length > 100) {
      listenHistory.removeLast(); // 保持记录不超过100条
    }

    saveListenHistory();
  }

  Future<void> saveListenHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        json.encode(listenHistory.map((e) => e.toMap()).toList());
    await prefs.setString('listen_history', jsonString);
  }

  Future<void> loadListenHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('listen_history');
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      listenHistory.value = jsonList.map((jsonItem) {
        return Episode.fromMap(jsonItem as Map<String, dynamic>);
      }).toList();
    }
  }

  void removeListenHistory(Episode episode) {
    listenHistory.remove(episode);
    saveListenHistory();
  }
}
