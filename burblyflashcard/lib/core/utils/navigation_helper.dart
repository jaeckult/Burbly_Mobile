import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

/// Custom route transitions using Material Motion
class MaterialMotionRoute<T> extends PageRouteBuilder<T> {
  MaterialMotionRoute({
    required this.child,
    this.transitionType = MaterialMotionTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 250),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
        );

  final Widget child;
  final MaterialMotionTransitionType transitionType;
  final Duration duration;
  final Duration reverseDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Get transition curves based on theme
    final curve = isDark 
        ? Curves.easeInOutCubic 
        : Curves.easeOutCubic;
    
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: Curves.easeInCubic,
    );

    switch (transitionType) {
      case MaterialMotionTransitionType.fade:
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
        
      case MaterialMotionTransitionType.fadeThrough:
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
        
      case MaterialMotionTransitionType.sharedAxis:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
        
      case MaterialMotionTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
        
      case MaterialMotionTransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
    }
  }
}

/// Enum for different transition types
enum MaterialMotionTransitionType {
  fade,
  fadeThrough,
  sharedAxis,
  scale,
  slide,
}

/// Navigation helper class with Material Motion transitions
class NavigationHelper {
  /// Push a new screen with custom transition
  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget screen, {
    MaterialMotionTransitionType transitionType = MaterialMotionTransitionType.fade,
    Duration? duration,
  }) {
    return Navigator.of(context).push<T>(
      MaterialMotionRoute<T>(
        child: screen,
        transitionType: transitionType,
        duration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }

  /// Push and replace current screen
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget screen, {
    MaterialMotionTransitionType transitionType = MaterialMotionTransitionType.fade,
    Duration? duration,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      MaterialMotionRoute<T>(
        child: screen,
        transitionType: transitionType,
        duration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }

  /// Push and clear all previous routes
  static Future<T?> pushAndClearStack<T extends Object?>(
    BuildContext context,
    Widget screen, {
    MaterialMotionTransitionType transitionType = MaterialMotionTransitionType.fade,
    Duration? duration,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialMotionRoute<T>(
        child: screen,
        transitionType: transitionType,
        duration: duration ?? const Duration(milliseconds: 300),
      ),
      (route) => false,
    );
  }

  /// Pop current screen
  static void pop<T extends Object?>(
    BuildContext context, [
    T? result,
  ]) {
    Navigator.of(context).pop<T>(result);
  }

  /// Pop until specific route
  static void popUntil(
    BuildContext context,
    RoutePredicate predicate,
  ) {
    Navigator.of(context).popUntil(predicate);
  }

  /// Pop to first route
  static void popToFirst(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}

/// Hero animation wrapper for shared elements
class HeroWrapper extends StatelessWidget {
  const HeroWrapper({
    super.key,
    required this.tag,
    required this.child,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.transitionOnUserGestures = false,
  });

  final Object tag;
  final Widget child;
  final CreateRectTween? createRectTween;
  final HeroFlightShuttleBuilder? flightShuttleBuilder;
  final HeroPlaceholderBuilder? placeholderBuilder;
  final bool transitionOnUserGestures;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      createRectTween: createRectTween,
      flightShuttleBuilder: flightShuttleBuilder,
      placeholderBuilder: placeholderBuilder,
      transitionOnUserGestures: transitionOnUserGestures,
      child: child,
    );
  }
}

/// Extension methods for easier navigation
extension NavigationExtension on BuildContext {
  /// Push with fade transition
  Future<T?> pushFade<T extends Object?>(
    Widget screen, {
    Duration? duration,
  }) {
    return NavigationHelper.push<T>(
      this,
      screen,
      transitionType: MaterialMotionTransitionType.fade,
      duration: duration,
    );
  }

  /// Push with fade-through transition
  Future<T?> pushFadeThrough<T extends Object?>(
    Widget screen, {
    Duration? duration,
  }) {
    return NavigationHelper.push<T>(
      this,
      screen,
      transitionType: MaterialMotionTransitionType.fadeThrough,
      duration: duration,
    );
  }

  /// Push with shared axis transition
  Future<T?> pushSharedAxis<T extends Object?>(
    Widget screen, {
    Duration? duration,
  }) {
    return NavigationHelper.push<T>(
      this,
      screen,
      transitionType: MaterialMotionTransitionType.sharedAxis,
      duration: duration,
    );
  }

  /// Push with scale transition
  Future<T?> pushScale<T extends Object?>(
    Widget screen, {
    Duration? duration,
  }) {
    return NavigationHelper.push<T>(
      this,
      screen,
      transitionType: MaterialMotionTransitionType.scale,
      duration: duration,
    );
  }

  /// Push with slide transition
  Future<T?> pushSlide<T extends Object?>(
    Widget screen, {
    Duration? duration,
  }) {
    return NavigationHelper.push<T>(
      this,
      screen,
      transitionType: MaterialMotionTransitionType.slide,
      duration: duration,
    );
  }

  /// Pop current screen
  void pop<T extends Object?>([T? result]) {
    NavigationHelper.pop<T>(this, result);
  }

  /// Check if can pop
  bool get canPop => NavigationHelper.canPop(this);
}
