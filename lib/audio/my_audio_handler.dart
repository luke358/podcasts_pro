import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:get/instance_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';
import 'package:podcasts_pro/utils/episode.dart';
import 'package:rxdart/rxdart.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.audio',
      androidNotificationChannelName: 'Audio Service Demo',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final PlayerController playerController = Get.find<PlayerController>();
  final _mediaItemSubject = BehaviorSubject<MediaItem?>();
  final _playbackStateSubject = BehaviorSubject<PlaybackState>();

  int _currentIndex = 0;

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // 初始化播放器状态
    _updatePlaybackState(stopped: true);

    // 监听播放器事件
    _player.playbackEventStream.listen(_broadcastState);

    // 监听播放完成事件
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        handlePlaybackCompletion();
      }
    });

    // 同步 mediaItem 和 playbackState
    _mediaItemSubject.stream.listen((item) => mediaItem.add(item));
    _playbackStateSubject.stream.listen((state) => playbackState.add(state));
  }

  void _updateMediaItem(MediaItem? item) {
    print('Updating MediaItem: ${item?.title}');
    _mediaItemSubject.add(item);
  }

  void _updatePlaybackState({bool stopped = false}) {
    final state = PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState:
          stopped ? AudioProcessingState.idle : _getProcessingState(),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
    print(
        'Updating PlaybackState: ${state.processingState}, Playing: ${state.playing}');
    _playbackStateSubject.add(state);
  }

  AudioProcessingState _getProcessingState() {
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  Future<void> _broadcastState(PlaybackEvent event) async {
    print('Broadcasting state: ${event.processingState}');
    _updatePlaybackState();
    if (playerController.playlist.isNotEmpty &&
        _currentIndex < playerController.playlist.length) {
      _updateMediaItem(
          mediaItemFromEpisode(playerController.playlist[_currentIndex]));
    } else {
      _updateMediaItem(null);
    }
  }

  Future<void> handlePlaybackCompletion() async {
    print('Handling playback completion');
    if (playerController.playlist.isEmpty) {
      await _player.stop();
      _updateMediaItem(null);
      _updatePlaybackState(stopped: true);
      return;
    }

    playerController.playlist.removeAt(_currentIndex);
    if (playerController.playlist.isEmpty) {
      await _player.stop();
      _updateMediaItem(null);
      _updatePlaybackState(stopped: true);
    } else {
      if (_currentIndex >= playerController.playlist.length) {
        _currentIndex = 0;
      }
      _updateMediaItem(
          mediaItemFromEpisode(playerController.playlist[_currentIndex]));
      await playFromPlaylist();
    }
    _notifyQueueChanges();
  }

  Future<void> playFromPlaylist() async {
    if (playerController.playlist.isEmpty) {
      _updateMediaItem(null);
      _updatePlaybackState(stopped: true);
      return;
    }

    if (_currentIndex >= playerController.playlist.length) {
      _currentIndex = 0;
    }

    final episode = playerController.playlist[_currentIndex];
    _updateMediaItem(mediaItemFromEpisode(episode));

    try {
      await _player
          .setAudioSource(AudioSource.uri(Uri.parse(episode.audioUrl!)));
      play();
      playerController.currentEpisode.value = episode;
    } catch (e) {
      print('Error setting audio source: $e');
      _handlePlaybackError();
    }
  }

  void _handlePlaybackError() {
    // 处理播放错误，例如跳到下一曲或停止播放
    skipToNext();
  }

  @override
  Future<void> play() async {
    print('Playing');
    await _player.play();
    _updatePlaybackState();
  }

  @override
  Future<void> pause() async {
    print('Pausing');
    await _player.pause();
    _updatePlaybackState();
  }

  @override
  Future<void> stop() async {
    print('Stopping');
    await _player.stop();
    _updatePlaybackState(stopped: true);
  }

  @override
  Future<void> skipToNext() async {
    print('Skipping to next');
    if (playerController.playlist.isEmpty) return;

    _currentIndex = (_currentIndex + 1) % playerController.playlist.length;
    _updateMediaItem(
        mediaItemFromEpisode(playerController.playlist[_currentIndex]));
    await playFromPlaylist();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToPrevious() async {
    print('Skipping to previous');
    if (playerController.playlist.isEmpty) return;

    if (_currentIndex - 1 < 0) {
      _currentIndex = playerController.playlist.length - 1;
    } else {
      _currentIndex--;
    }
    _updateMediaItem(
        mediaItemFromEpisode(playerController.playlist[_currentIndex]));
    await playFromPlaylist();
  }

  void remove(int index) async {
    // 删除前面的
    if (index < _currentIndex) {
      _currentIndex--;
    }
    playerController.playlist.removeAt(index);
  }

  void _notifyQueueChanges() {
    queue.add(playerController.playlist
        .map((episode) => mediaItemFromEpisode(episode))
        .toList());
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  @override
  Future<void> onNotificationDeleted() async {
    await stop();
  }
}
