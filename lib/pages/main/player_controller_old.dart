import 'dart:collection';
import 'dart:convert';

import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: constant_identifier_names
const int MAX_PLAYLIST_LENGTH = 100;

class PlayerController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();
  var isPlaying = false.obs;
  var playlist = <Episode>[].obs;
  var currentEpisode = Rxn<Episode>();

  var currentPosition = Duration.zero.obs;
  var playbackSpeed = 1.0.obs; // 默认为1.0x速度

  final playbackPositions = <String, Duration>{}.obs;
  final ListQueue<String> _recentlyUsedUrls = ListQueue<String>(100);

  // 新增：收听记录列表
  var listenHistory = <Episode>[].obs;
  var favoriteEpisodes = <Episode>[].obs;

  PlayerController() {
    _audioPlayer.positionStream.listen((position) {
      currentPosition.value = position;
      if (currentEpisode.value != null && isPlaying.value) {
        _savePlaybackPosition(currentEpisode.value!.audioUrl!, position);
      }
    });

    _audioPlayer.playbackEventStream.listen((event) {
      isPlaying.value = _audioPlayer.playing;
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompletion();
      }
    });

    // 加载播放速度
    loadPlaybackSpeed();
    loadFavoriteEpisodes();

    loadPlaylist();
    loadPlaybackPositions();
    loadListenHistory(); // 加载收听记录
    loadCurrentEpisode().then((_) {
      if (currentEpisode.value != null) {
        _initializeAudioPlayer();
      }
    });
  }

  void removeListenHistory(Episode episode) {
    listenHistory.remove(episode);
    saveListenHistory();
  }

  void removeFavoriteEpisode(Episode episode) {
    favoriteEpisodes.remove(episode);
    _saveFavoriteEpisodes();
  }

  Future<void> setSpeed(double speed) async {
    playbackSpeed.value = speed;
    await _audioPlayer.setSpeed(speed);
    // 保存播放速度
    _savePlaybackSpeed(speed);
  }

  Future<void> _savePlaybackSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playback_speed', speed);
  }

  Future<void> loadPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    playbackSpeed.value = prefs.getDouble('playback_speed') ?? 1.0;
    await _audioPlayer.setSpeed(playbackSpeed.value);
  }

  Future<void> _initializeAudioPlayer() async {
    if (currentEpisode.value != null) {
      try {
        final episode = currentEpisode.value!;
        await _audioPlayer.setUrl(episode.audioUrl!);

        var position = playbackPositions[episode.audioUrl] ?? Duration.zero;
        if (position.inSeconds >=
            episode.durationInSeconds - const Duration(seconds: 5).inSeconds) {
          position = Duration.zero; // 播放位置接近结束时重置为从头开始
        }

        _audioPlayer.seek(position);

        if (isPlaying.value) {
          _audioPlayer.play();
        } else {
          _audioPlayer.pause();
        }
      } catch (e) {
        print('Error initializing audio player: $e');
      }
    }
  }

  void playEpisode(Episode episode) async {
    final currentEpisodeUrl = currentEpisode.value?.audioUrl;
    final isSameEpisode = currentEpisodeUrl == episode.audioUrl;

    if (currentEpisodeUrl != null && !isSameEpisode) {
      final currentPosition = _audioPlayer.position;
      _savePlaybackPosition(currentEpisodeUrl, currentPosition);
    }

    if (isSameEpisode) {
      var position = playbackPositions[episode.audioUrl] ?? Duration.zero;
      if (position.inSeconds >=
          episode.durationInSeconds - const Duration(seconds: 5).inSeconds) {
        position = Duration.zero; // 播放位置接近结束时重置为从头开始
      }

      _audioPlayer.seek(position);
      if (!isPlaying.value) {
        _audioPlayer.play();
      }
      return;
    }

    currentEpisode.value = episode;
    saveCurrentEpisode(); // Save the current episode

    try {
      await _audioPlayer.setUrl(episode.audioUrl!);

      var position = playbackPositions[episode.audioUrl] ?? Duration.zero;
      if (position.inSeconds >=
          episode.durationInSeconds - const Duration(seconds: 5).inSeconds) {
        position = Duration.zero; // 播放位置接近结束时重置为从头开始
      }

      _audioPlayer.seek(position);
      _audioPlayer.play();
      isPlaying.value = true;

      addEpisodeToPlaylist(episode);
      addEpisodeToListenHistory(episode); // 新增：将播放的集添加到收听记录

      if (_recentlyUsedUrls.contains(episode.audioUrl!)) {
        _recentlyUsedUrls.remove(episode.audioUrl!);
      }
      _recentlyUsedUrls.add(episode.audioUrl!);

      _savePlaybackPositions();
    } catch (e) {
      print('Error playing episode: $e');
    }
  }

  void addEpisodeToPlaylist(Episode episode) {
    // 检查播放列表中是否已存在此集
    final existingIndex =
        playlist.indexWhere((e) => e.audioUrl == episode.audioUrl);

    // 如果集已经存在，则不需要进行任何操作
    if (existingIndex != -1) {
      return;
    }

    // 如果播放列表已满，则移除最早添加的集（但优先保留正在播放的集）
    if (playlist.length == MAX_PLAYLIST_LENGTH) {
      // 找到正在播放的集的索引
      final currentlyPlaying = currentEpisode.value;
      if (currentlyPlaying != null) {
        final currentlyPlayingIndex =
            playlist.indexWhere((e) => e.audioUrl == currentlyPlaying.audioUrl);

        if (currentlyPlayingIndex != -1) {
          // 如果正在播放的集在播放列表的开头，移除下一个集
          if (currentlyPlayingIndex == 0) {
            playlist.removeAt(1); // 移除第二个集
          } else {
            playlist.removeAt(0); // 移除第一个集
          }
        } else {
          // 如果没有正在播放的集，移除第一个集
          playlist.removeAt(0);
        }
      } else {
        // 如果没有正在播放的集，移除第一个集
        playlist.removeAt(0);
      }
    }
    // 将新集添加到播放列表的末尾
    playlist.add(episode);
    // 保存播放列表
    savePlaylist();
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

  Future<void> _savePlaybackPosition(String url, Duration position) async {
    playbackPositions[url] = position;
    _savePlaybackPositions();
  }

  Future<void> _savePlaybackPositions() async {
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

  Future<void> savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(playlist.map((e) => e.toMap()).toList());
    await prefs.setString('playlist', jsonString);
  }

  Future<void> loadPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('playlist');
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      playlist.value = jsonList.map((jsonItem) {
        return Episode.fromMap(jsonItem as Map<String, dynamic>);
      }).toList();
    }
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
        currentEpisode.value = Episode.fromMap(jsonMap);
      } else {
        currentEpisode.value = null;
      }
    } catch (e) {
      print('Failed to load current episode: $e');
      currentEpisode.value = null;
    }
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

  void clearPlaylist() {
    playlist.clear();
    savePlaylist();
    currentEpisode.value = null;
    saveCurrentEpisode();
    _audioPlayer.stop();
    isPlaying.value = false;
  }

  void removeEpisodeFromPlaylist(Episode episode) {
    // 播放下一个集
    next();
    // 移除播放列表中的集
    _handleEpisodeRemoval(episode);
  }

  void _handleEpisodeRemoval(Episode episode) {
    final index = playlist.indexWhere((e) => e.audioUrl == episode.audioUrl);
    if (index != -1) {
      playlist.removeAt(index);
      savePlaylist();
    }
  }

  void prev() {
    if (playlist.isEmpty) {
      return;
    }
    final currentIndex = playlist.indexWhere(
      (episode) => episode.audioUrl == currentEpisode.value?.audioUrl,
    );
    final prevIndex = (currentIndex - 1) % playlist.length;
    final prevEpisode = playlist[prevIndex];
    if (prevEpisode.audioUrl == currentEpisode.value?.audioUrl) {
      return;
    } else {
      playEpisode(prevEpisode);
    }
  }

  void next() {
    if (playlist.isEmpty) {
      return;
    }
    final currentIndex = playlist.indexWhere(
      (episode) => episode.audioUrl == currentEpisode.value?.audioUrl,
    );
    final nextIndex = (currentIndex + 1) % playlist.length;
    final nextEpisode = playlist[nextIndex];

    if (nextEpisode.audioUrl == currentEpisode.value?.audioUrl) {
      return;
    } else {
      playEpisode(nextEpisode);
    }
  }

  void _handlePlaybackCompletion() {
    // 播放下一个集，并在播放完成后移除当前播放的集
    if (currentEpisode.value != null) {
      removeEpisodeFromPlaylist(currentEpisode.value!);
    }
  }

  void play() => _audioPlayer.play();
  void pause() => _audioPlayer.pause();
  void stop() => _audioPlayer.stop();
  void seek(Duration position) => _audioPlayer.seek(position);

  bool isEpisodePlaying(Episode episode) {
    return currentEpisode.value?.audioUrl == episode.audioUrl &&
        isPlaying.value;
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
