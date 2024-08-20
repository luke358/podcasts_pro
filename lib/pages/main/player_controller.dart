import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:podcasts_pro/audio/my_audio_handler.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: constant_identifier_names
const int MAX_PLAYLIST_LENGTH = 100;

enum PlayingState {
  paused,
  playing,
  loading,
}

class PlayerController extends GetxController {
  late MyAudioHandler _audioHandler;

  var playingState = PlayingState.paused.obs;
  var isShuffleMode = false.obs;

  var playlist = <Episode>[].obs;
  var currentEpisode = Rxn<Episode>();

  var currentPosition = Duration.zero.obs;
  var playbackSpeed = 1.0.obs; // 默认为1.0x速度

  @override
  void onInit() async {
    super.onInit();

    await _loadPlaylist();
    await loadCurrentEpisode();

    _audioHandler = await initAudioService() as MyAudioHandler;

    _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);

    await _audioHandler.playFromPlaylist(autoPlay: false);

    await loadPlaybackSpeed();

    playlist.listen((newList) {
      print('List changed: $newList');
      savePlaylist();
    });
    currentEpisode.listen((episode) {
      print("Current episode changed: ${episode?.title}");
      saveCurrentEpisode();
    });
    playbackSpeed.listen((speed) {
      print('Playback speed changed: $speed');
      _savePlaybackSpeed();
    });
  }

  Future<void> add(Episode episode) async {
    if (playlist.indexWhere((e) => e.audioUrl == episode.audioUrl) == -1) {
      _audioHandler.add(episode);
    }
  }

  Future<void> next() async {
    await _audioHandler.skipToNext();
  }

  Future<void> prev() async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(playlist.map((e) => e.toMap()).toList());
    await prefs.setString('playlist', jsonString);
  }

  Future<void> clearPlaylist() async {
    await _audioHandler.clearPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('playlist');
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      playlist.value = jsonList.map((jsonItem) {
        return Episode.fromMap(jsonItem as Map<String, dynamic>);
      }).toList();
    }
  }

  void remove(Episode episode) {
    _audioHandler.remove(episode);
  }

  Future<void> seek(Duration position) async {
    print("object $position");
    await _audioHandler.seek(position);
  }

  void pause() {
    _audioHandler.pause();
  }

  void play(
    Episode episode, {
    bool autoPlay = true,
  }) {
    int index = playlist.indexWhere((e) => e.audioUrl == episode.audioUrl);
    if (index == -1) {
      playlist.add(episode);
      index = playlist.length - 1;
    }
    _audioHandler.playFromPlaylist(index: index, autoPlay: autoPlay);
  }

  bool isCurrentEpisode(Episode episode) {
    return currentEpisode.value?.audioUrl == episode.audioUrl;
  }

  @override
  void dispose() {
    super.dispose();
    _audioHandler.customAction('dispose');
  }

  void stop() {
    _audioHandler.stop();
  }

  Future<void> saveCurrentEpisode() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(currentEpisode.value?.toMap());
    await prefs.setString('current_episode', jsonString);
  }

  Future<void> loadCurrentEpisode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('current_episode');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        final episode = Episode.fromMap(jsonMap);
        if (playlist.indexWhere((e) => e.audioUrl == episode.audioUrl) != -1) {
          currentEpisode.value = episode;
        } else {
          currentEpisode.value = playlist.isEmpty ? null : playlist.first;
        }
      } else {
        currentEpisode.value = null;
      }
    } catch (e) {
      print('Failed to load current episode: $e');
      currentEpisode.value = null;
    }
  }

  Future<void> setSpeed(double speed) async {
    playbackSpeed.value = speed;
    await _audioHandler.setSpeed(speed);
  }

  Future<void> _savePlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playback_speed', playbackSpeed.value);
  }

  Future<void> loadPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    playbackSpeed.value = prefs.getDouble('playback_speed') ?? 1.0;
    await _audioHandler.setSpeed(playbackSpeed.value);
  }
}



  // Future<void> loadCurrentEpisode() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final jsonString = prefs.getString('current_episode');
  //     if (jsonString != null) {
  //       final Map<String, dynamic> jsonMap = json.decode(jsonString);
  //       currentEpisode.value = Episode.fromMap(jsonMap);
  //     } else {
  //       currentEpisode.value = null;
  //     }
  //   } catch (e) {
  //     print('Failed to load current episode: $e');
  //     currentEpisode.value = null;
  //   }
  // }
