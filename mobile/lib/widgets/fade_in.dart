import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Wraps a list item so it fades/slides in shortly after the list first
/// builds, each item a little later than the one before it — the "cards
/// drop in one by one" rhythm instead of the whole list appearing at once.
/// Delay is capped so a long list doesn't make the last rows wait forever.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

/// Like [IndexedStack], but crossfades between children on index change
/// instead of swapping instantly — every *visited* child stays mounted
/// (state, scroll position, in-flight loads all survive a tab switch)
/// since only opacity/hit-testing changes, not the widget tree. A tab's
/// child isn't built at all until its index is first selected, so opening
/// a shell with several tabs doesn't pay the build cost of every one of
/// them up front — only the active tab builds on the first frame.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  late final Set<int> _builtIndices = {widget.index};

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _builtIndices.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (_builtIndices.contains(i))
            Positioned.fill(
              child: IgnorePointer(
                ignoring: widget.index != i,
                child: AnimatedOpacity(
                  opacity: widget.index == i ? 1 : 0,
                  duration: AppDurations.fast,
                  curve: AppCurves.standard,
                  child: widget.children[i],
                ),
              ),
            ),
      ],
    );
  }
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppDurations.medium);
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: AppCurves.enter);
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.enter));

  @override
  void initState() {
    super.initState();
    final delayMs = (widget.index * AppDurations.staggerStep.inMilliseconds).clamp(0, 360);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
