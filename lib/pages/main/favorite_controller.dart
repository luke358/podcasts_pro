import 'dart:convert';

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteController extends GetxController {
  var favoriteEpisodes = <Episode>[].obs;

  @override
  void onInit() async {
    await loadFavoriteEpisodes();
    super.onInit();
    print("FavoriteController onInit");
  }

  void removeFavoriteEpisode(Episode episode) {
    favoriteEpisodes.remove(episode);
    _saveFavoriteEpisodes();
  }

  void addEpisodeToFavorites(Episode episode) async {
    if (isFavorite(episode)) {
      favoriteEpisodes.removeWhere((e) => e.audioUrl == episode.audioUrl);
    } else {
      favoriteEpisodes.add(episode);
    }
    _saveFavoriteEpisodes();
  }

  Future<void> _saveFavoriteEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final episodeListJson =
        favoriteEpisodes.map((e) => json.encode(e.toMap())).toList();
    prefs.setStringList('favorite_episodes', episodeListJson);
  }

  Future<void> loadFavoriteEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final episodeListJson = prefs.getStringList('favorite_episodes') ?? [];
    favoriteEpisodes.value =
        episodeListJson.map((e) => Episode.fromMap(json.decode(e))).toList();
  }

  bool isFavorite(Episode episode) {
    return favoriteEpisodes.any((e) => e.audioUrl == episode.audioUrl);
  }
}
