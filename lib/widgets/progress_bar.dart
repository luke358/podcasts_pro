import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final Duration duration;
  final Duration playbackPosition;
  final void Function(Duration newPosition) onSeek;

  const ProgressBar({
    super.key,
    required this.duration,
    required this.playbackPosition,
    required this.onSeek,
  });

  @override
  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  final ValueNotifier<Duration> _dragPositionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  Duration _currentDragPosition = Duration.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentDragPosition = widget.playbackPosition;
    _dragPositionNotifier.value = _currentDragPosition;
  }

  @override
  void didUpdateWidget(covariant ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playbackPosition != oldWidget.playbackPosition && !_isDragging) {
      // 更新播放进度
      _currentDragPosition = widget.playbackPosition;
      _dragPositionNotifier.value = _currentDragPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatDuration(Duration duration) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return SizedBox(
      height: 60,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(_isDragging
                    ? _dragPositionNotifier.value
                    : widget.playbackPosition),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                formatDuration(widget.duration),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          GestureDetector(
            onHorizontalDragStart: (details) {
              _isDragging = true;
            },
            onHorizontalDragUpdate: (details) {
              final width = context.size!.width; // 使用实际容器宽度
              final newProgress = (details.localPosition.dx / width)
                  .clamp(0.0, 1.0); // 使用相对进度计算
              final newDuration = Duration(
                  seconds: (widget.duration.inSeconds * newProgress).toInt());
              _dragPositionNotifier.value = newDuration;
            },
            onHorizontalDragEnd: (details) {
              _isDragging = false;
              final newPosition = _dragPositionNotifier.value;
              widget.onSeek(
                  newPosition); // Update playback position when drag ends
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth; // 获取容器最大宽度

                return Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: ValueListenableBuilder<Duration>(
                      valueListenable: _dragPositionNotifier,
                      builder: (context, dragPosition, child) {
                        final progress = widget.duration.inSeconds > 0
                            ? dragPosition.inSeconds / widget.duration.inSeconds
                            : 0.0;

                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 40,
                            width: maxWidth * progress, // 修正宽度计算
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.green],
                                stops: [0.0, 1.0],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dragPositionNotifier.dispose();
    super.dispose();
  }
}
