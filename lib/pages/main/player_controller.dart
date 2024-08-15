import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:podcasts_pro/audio/my_audio_handler.dart';
import 'package:podcasts_pro/models/episode.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: constant_identifier_names
const int MAX_PLAYLIST_LENGTH = 100;

class PlayerController extends GetxController {
  late MyAudioHandler _audioHandler;

  var isPlaying = false.obs;
  var isLoading = false.obs; // 用于控制loading显示状态

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
    _initAudioService();
  }

  Timer? _debounceTimer;
  void _onPlaybackStateChanged(PlaybackState state) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      switch (state.processingState) {
        case AudioProcessingState.buffering:
        case AudioProcessingState.loading:
          isLoading.value = true;
          print("loading 加载中");
          break;
        case AudioProcessingState.ready:
        case AudioProcessingState.completed:
        case AudioProcessingState.error:
          isLoading.value = false;
          print("loading 加载完成");
          break;
        default:
          isLoading.value = false;
          print("loading 加载完成");
      }
    });
  }

  Future<void> _initAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.luke358.podcasts_pro.audio',
        androidNotificationChannelName: 'Podcasts Pro Audio Service',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    _audioHandler.playbackState.listen((state) {
      isPlaying.value = state.playing;
      playbackSpeed.value = state.speed;

      _onPlaybackStateChanged(state);

      if (state.processingState == AudioProcessingState.completed) {
        if (isPlaying.value) {
          _audioHandler.pause();
          _handlePlaybackCompletion();
        }
      }
    });
    AudioService.position.listen((position) {
      currentPosition.value = position;
      if (currentEpisode.value != null && isPlaying.value) {
        _savePlaybackPosition(currentEpisode.value!.audioUrl!, position);
      }
    });

    await Future.wait([
      loadPlaybackSpeed(),
      loadFavoriteEpisodes(),
      loadPlaylist(),
      loadPlaybackPositions(),
      loadListenHistory(),
      loadCurrentEpisode()
    ]);
    if (currentEpisode.value != null) {
      await _initializeAudioPlayer();
    }
  }

  Future<void> _initializeAudioPlayer() async {
    if (currentEpisode.value != null) {
      try {
        final episode = currentEpisode.value!;
        await _audioHandler.playMediaItem(mediaItemFromEpisode(episode));
        currentPosition.value =
            playbackPositions[episode.audioUrl] ?? Duration.zero;
        // 需要加一个 loading，否则在页面打开的时候，如果上面还没有完成，立即播放会出现错误
        await seek(currentPosition.value);
      } catch (e) {
        print('Error initializing audio player: $e');
      }
    }
  }

  void removeListenHistory(Episode episode) {
    listenHistory.remove(episode);
    saveListenHistory();
  }

  void removeFavoriteEpisode(Episode episode) {
    favoriteEpisodes.remove(episode);
    _saveFavoriteEpisodes();
  }

  Future<void> _savePlaybackSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playback_speed', speed);
  }

  Future<void> loadPlaybackSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    playbackSpeed.value = prefs.getDouble('playback_speed') ?? 1.0;
    await _audioHandler.setSpeed(playbackSpeed.value);
  }

  void playEpisode(Episode episode, {bool autoPlay = true}) async {
    final currentEpisodeUrl = currentEpisode.value?.audioUrl;
    final isSameEpisode = currentEpisodeUrl == episode.audioUrl;

    if (isSameEpisode) {
      var position = playbackPositions[episode.audioUrl] ?? Duration.zero;
      if (position.inSeconds >=
          episode.durationInSeconds - const Duration(seconds: 5).inSeconds) {
        position = Duration.zero;
      }

      await seek(position);
      if (!isPlaying.value) {
        await _audioHandler.play();
      }
      return;
    }

    await _audioHandler.pause();
    currentEpisode.value = episode;
    saveCurrentEpisode();

    try {
      var position = playbackPositions[episode.audioUrl] ?? Duration.zero;
      if (position.inSeconds >=
          episode.durationInSeconds - const Duration(seconds: 5).inSeconds) {
        position = Duration.zero;
      }

      addEpisodeToPlaylist(episode);
      addEpisodeToListenHistory(episode);

      if (_recentlyUsedUrls.contains(episode.audioUrl!)) {
        _recentlyUsedUrls.remove(episode.audioUrl!);
      }
      _recentlyUsedUrls.add(episode.audioUrl!);

      _savePlaybackPositions();

      await _audioHandler.playMediaItem(mediaItemFromEpisode(episode));
      await seek(position);

      if (autoPlay) {
        await _audioHandler.play();
      }
    } catch (e) {
      print('Error playing episode: $e');
    }
  }

  void addEpisodeToPlaylist(Episode episode) {
    if (playlist.isEmpty) {
      playEpisode(episode);
    } else {
      // 检查播放列表中是否已存在此集
      final existingIndex =
          playlist.indexWhere((e) => e.audioUrl == episode.audioUrl);

      // 如果集已经存在，则不需要进行任何操作
      if (existingIndex != -1) {
        return;
      }
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
    // _audioHandler.addQueueItem(mediaItemFromEpisode(episode));
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
    _audioHandler.stop();
    isPlaying.value = false;
  }

  void removeEpisodeFromPlaylist(Episode episode) {
    // 播放下一个集
    if (episode.audioUrl == currentEpisode.value?.audioUrl) {
      next();
    }
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
      playEpisode(prevEpisode, autoPlay: isPlaying.value);
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
      playEpisode(nextEpisode, autoPlay: isPlaying.value);
    }
  }

  void _handlePlaybackCompletion() {
    // 播放下一个集，并在播放完成后移除当前播放的集
    if (currentEpisode.value != null) {
      print("object ${currentEpisode.value!.title} 播放完成");
      removeEpisodeFromPlaylist(currentEpisode.value!);
    }
  }

  void play() {
    playEpisode(currentEpisode.value!);
  }

  void pause() => _audioHandler.pause();
  void stop() => _audioHandler.stop();
  Future<void> seek(Duration position) async {
    print("seeeeeee $position");
    if (position < Duration.zero ||
        position.inSeconds > currentEpisode.value!.durationInSeconds) {
      print('Seek position is out of bounds');
      return;
    }

    try {
      await _audioHandler.seek(position);
    } catch (e) {
      print('Error during seek: $e');
    }
  }

  Future<void> setSpeed(double speed) async {
    playbackSpeed.value = speed;
    await _audioHandler.setSpeed(speed);
    _savePlaybackSpeed(speed);
  }

  bool isCurrentEpisode(Episode episode) {
    return currentEpisode.value?.audioUrl == episode.audioUrl;
  }
}

MediaItem mediaItemFromEpisode(Episode episode) {
  return MediaItem(
    id: episode.audioUrl ?? '',
    album: episode.subscription.title,
    title: episode.title,
    artist: episode.subscription.author,
    duration: Duration(seconds: episode.durationInSeconds),
    artUri: Uri.parse(episode.imageUrl ?? ''),
    extras: {
      'description': episode.description,
      'pubDate': episode.pubDate.toIso8601String(),
    },
  );
}
