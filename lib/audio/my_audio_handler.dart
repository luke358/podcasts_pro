import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:podcasts_pro/pages/main/player_controller.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  final _mediaItemExpando = Expando<MediaItem>();

  PlayerController playerController = Get.find<PlayerController>();

  MyAudioHandler() {
    _loadPlaylist();
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  Future<void> _loadPlaylist() async {
    playerController.playlist
        .map((e) => _itemToSource(mediaItemFromEpisode(e)))
        .toList();
    _playlist.addAll(queue.value.map(_itemToSource).toList());
    await _player.setAudioSource(_playlist);
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      print("$playing sdfsdfsdfds");
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      var index = _player.currentIndex;
      final newQueue = queue.value;
      if (index == null || newQueue.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      final oldMediaItem = newQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      if (_player.shuffleModeEnabled) {
        index = _player.shuffleIndices!.indexOf(index);
      }
      mediaItem.add(playlist[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
      final items = sequence.map((source) => source.tag as MediaItem);
      queue.add(items.toList());
    });
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSource = mediaItems.map((item) => AudioSource.uri(
          Uri.parse(item.id),
          tag: item,
        ));
    _playlist.addAll(audioSource.toList());

    final newQueue = queue.value..addAll(mediaItems);
    queue.add(newQueue);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final audioSource = AudioSource.uri(
      Uri.parse(mediaItem.id),
      tag: mediaItem,
    );
    _playlist.add(audioSource);

    final newQueue = queue.value..add(mediaItem);
    queue.add(newQueue);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    _playlist.removeAt(index);

    final newQueue = queue.value..removeAt(index);
    queue.add(newQueue);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) async {
    print("Seeking to position: $position");
    try {
      await _player.seek(position);
    } catch (e) {
      print("Error seeking: $e");
    }
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> skipToNext() async {
    playerController.next();
  }

  @override
  Future<void> skipToPrevious() async {
    playerController.prev();
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem),
    );
  }

  AudioSource _itemToSource(MediaItem mediaItem) {
    final audioSource = AudioSource.uri(Uri.parse(mediaItem.id));
    _mediaItemExpando[audioSource] = mediaItem;
    return audioSource;
  }

  @override
  Future<void> skipToQueueItem(int index, {Duration? position}) async {
    if (index < 0 || index >= _playlist.children.length) return;
    // This jumps to the beginning of the queue item at [index].
    _player.seek(position ?? Duration.zero,
        index: _player.shuffleModeEnabled
            ? _player.shuffleIndices![index]
            : index);
  }

  // @override
  // Future<dynamic> customAction(String name,
  //     [Map<String, dynamic>? extras]) async {
  //   switch (name) {
  //     case 'getPosition':
  //       return _player.position;
  //     default:
  //       return super.customAction(name, extras);
  //   }
  // }
}
