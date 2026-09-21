import 'package:flutter/material.dart';

/// Tactile Scale on Press (Principle 12 of make-interfaces-feel-better: scale 0.96)
class TactileTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final HitTestBehavior behavior;

  const TactileTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<TactileTap> createState() => _TactileTapState();
}

class _TactileTapState extends State<TactileTap> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Apple Design §1 (Response) & §4 (Spring Defaults):
    // Instant pointer-down response (80ms forward), smooth critically damped return (130ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
