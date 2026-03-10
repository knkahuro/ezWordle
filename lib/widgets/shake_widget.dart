import 'dart:math';
import 'package:flutter/material.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeCount;
  final double shakeOffset;
  final Stream<void>? shakeSignal;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.shakeCount = 3,
    this.shakeOffset = 10,
    this.shakeSignal,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    widget.shakeSignal?.listen((_) => _shake());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _shake() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double sineValue = sin(widget.shakeCount * 2 * pi * _controller.value);
        return Transform.translate(
          offset: Offset(sineValue * widget.shakeOffset * (1 - _controller.value), 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
