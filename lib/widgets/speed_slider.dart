import 'package:flutter/material.dart';

class CustomTickMarkShape extends SliderTickMarkShape {
  final double width;
  final double height;
  final double tickMarkRadius;

  CustomTickMarkShape({
    this.width = 3.0,
    this.height = 15.0,
    this.tickMarkRadius = 1.5,
  });

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) {
    return Size(width, height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool? isEnabled,
    bool? isDiscrete,
  }) {
    final Paint paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: width,
          height: height,
        ),
        Radius.circular(tickMarkRadius),
      ),
      paint,
    );
  }
}

class CustomThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double width;
  final double height;

  CustomThumbShape({
    this.thumbRadius = 12.0,
    this.width = 3.0,
    this.height = 20.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(width, height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: width,
          height: height,
        ),
        Radius.circular(thumbRadius),
      ),
      paint,
    );
  }
}

class SpeedSlider extends StatelessWidget {
  final double initialSpeed;
  final ValueChanged<double> onSpeedChanged;

  const SpeedSlider({
    super.key,
    required this.initialSpeed,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 0.0,
            trackShape: const RectangularSliderTrackShape(),
            activeTrackColor: Colors.transparent,
            // inactiveTrackColor: Colors.transparent,
            inactiveTickMarkColor: Colors.grey,
            thumbShape: CustomThumbShape(),
            tickMarkShape: CustomTickMarkShape(),
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: initialSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            label: '${initialSpeed.toStringAsFixed(1)}x',
            onChanged: onSpeedChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTickLabel('0.5'),
              _buildTickLabel('1.0'),
              _buildTickLabel('1.5'),
              _buildTickLabel('2.0'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTickLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}
