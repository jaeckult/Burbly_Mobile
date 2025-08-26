# Navigation Improvements for Burbly Flashcard

This document outlines the new navigation system that provides smooth Material Motion transitions and improved user experience.

## 🚀 Features

- **Material Motion Transitions**: Fade, fade-through, shared axis, scale, and slide transitions
- **Theme-Aware**: Automatically adjusts transition curves based on light/dark mode
- **Hero Animations**: Easy-to-use wrapper for shared element transitions
- **Extension Methods**: Clean, readable navigation calls using context extensions
- **Customizable**: Control transition duration, type, and behavior

## 📱 Transition Types

### 1. Fade Transition
```dart
context.pushFade(NextScreen());
```
- Simple opacity transition
- Best for: Modal dialogs, overlays, simple screen changes

### 2. Fade Through Transition
```dart
context.pushFadeThrough(NextScreen());
```
- Smooth fade between screens with shared axis movement
- Best for: Related content, sequential screens

### 3. Shared Axis Transition
```dart
context.pushSharedAxis(NextScreen());
```
- Horizontal slide with fade
- Best for: Navigation between related screens, tabs

### 4. Scale Transition
```dart
context.pushScale(NextScreen());
```
- Scale up from center with fade
- Best for: Detail screens, expanding content

### 5. Slide Transition
```dart
context.pushSlide(NextScreen());
```
- Slide in from right
- Best for: Forward navigation, new content

## 🎨 Hero Animations

### Basic Hero Animation
```dart
// In source screen
HeroWrapper(
  tag: 'item_${item.id}',
  child: Image.network(item.imageUrl),
)

// In destination screen
HeroWrapper(
  tag: 'item_${item.id}',
  child: Image.network(item.imageUrl),
)
```

### Advanced Hero Animation
```dart
HeroWrapper(
  tag: 'item_${item.id}',
  createRectTween: (begin, end) {
    return RectTween(begin: begin, end: end);
  },
  flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: fromHeroContext.widget,
        );
      },
    );
  },
  child: YourWidget(),
)
```

## 🔧 Advanced Usage

### Custom Transition Duration
```dart
context.pushFade(
  NextScreen(),
  duration: const Duration(milliseconds: 500),
);
```

### Fullscreen Dialog
```dart
context.pushFade(
  NextScreen(),
  fullscreenDialog: true,
);
```

### Direct NavigationHelper Usage
```dart
NavigationHelper.push(
  context,
  NextScreen(),
  transitionType: MaterialMotionTransitionType.fadeThrough,
  duration: const Duration(milliseconds: 400),
  fullscreenDialog: false,
);
```

### Navigation with Replacement
```dart
NavigationHelper.pushReplacement(
  context,
  HomeScreen(),
  transitionType: MaterialMotionTransitionType.fadeThrough,
);
```

### Clear Navigation Stack
```dart
NavigationHelper.pushAndClearStack(
  context,
  HomeScreen(),
  transitionType: MaterialMotionTransitionType.scale,
);
```

## 🎯 Refactoring Existing Code

### Before (Old Way)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CreateDeckPackScreen(
      onDeckPackCreated: (deckPack) {
        // Handle callback
      },
    ),
  ),
);
```

### After (New Way)
```dart
// Simple fade transition
context.pushFade(
  CreateDeckPackScreen(
    onDeckPackCreated: (deckPack) {
      // Handle callback
    },
  ),
);

// Or with shared axis for related content
context.pushSharedAxis(
  CreateDeckPackScreen(
    onDeckPackCreated: (deckPack) {
      // Handle callback
    },
  ),
);
```

## 🌓 Theme-Aware Transitions

The navigation system automatically detects your app's theme and adjusts transition curves:

- **Light Mode**: Faster, snappier transitions using `Curves.easeOutCubic`
- **Dark Mode**: Slower, more elegant transitions using `Curves.easeInOutCubic`

### Custom Theme-Based Navigation
```dart
if (Theme.of(context).brightness == Brightness.light) {
  context.pushFade(
    NextScreen(),
    duration: const Duration(milliseconds: 250),
  );
} else {
  context.pushFade(
    NextScreen(),
    duration: const Duration(milliseconds: 350),
  );
}
```

## 📋 Best Practices

### 1. Choose Appropriate Transitions
- **Fade**: Simple overlays, modals
- **Fade Through**: Related content, sequential screens
- **Shared Axis**: Navigation between related screens
- **Scale**: Detail screens, expanding content
- **Slide**: Forward navigation, new content

### 2. Consistent Navigation Patterns
```dart
// Use consistent transitions for related screens
class StudyFlow {
  static Future<void> navigateToStudy(BuildContext context) async {
    await context.pushFade(StudyModeSelectionScreen());
    await context.pushSharedAxis(StudyScreen());
    await context.pushScale(StudyResultsScreen());
  }
}
```

### 3. Hero Animation Tags
- Use unique, descriptive tags
- Include IDs when possible: `'deck_${deck.id}'`
- Avoid generic tags like `'image'` or `'card'`

### 4. Performance Considerations
- Keep transition durations between 200-500ms
- Use lighter transitions for frequently accessed screens
- Consider user preferences for accessibility

## 🧪 Testing Transitions

Use the `TransitionDemoScreen` to test all transition types:

```dart
// Add to your navigation
context.pushFade(const TransitionDemoScreen());
```

## 🔄 Migration Guide

### Step 1: Import the Navigation Helper
```dart
import 'package:your_app/core/core.dart';
// This automatically imports navigation_helper.dart
```

### Step 2: Replace Navigator.push Calls
```dart
// Old
Navigator.push(context, MaterialPageRoute(builder: (context) => NextScreen()));

// New
context.pushFade(NextScreen());
```

### Step 3: Add Hero Animations
```dart
// Wrap shared elements with HeroWrapper
HeroWrapper(
  tag: 'unique_tag',
  child: YourWidget(),
)
```

### Step 4: Test and Refine
- Test transitions on both light and dark themes
- Adjust durations based on user feedback
- Ensure Hero animations work smoothly

## 🐛 Troubleshooting

### Common Issues

1. **Transition not working**
   - Ensure you're using the context extension methods
   - Check that the screen widget is properly constructed

2. **Hero animation not working**
   - Verify both screens use the same tag
   - Ensure HeroWrapper is properly imported

3. **Performance issues**
   - Reduce transition duration
   - Use simpler transitions for complex screens

### Debug Mode
```dart
// Enable debug information
NavigationHelper.push(
  context,
  NextScreen(),
  transitionType: MaterialMotionTransitionType.fade,
  duration: const Duration(milliseconds: 1000), // Slower for debugging
);
```

## 📚 Additional Resources

- [Material Motion Guidelines](https://m2.material.io/design/motion/the-motion-system.html)
- [Flutter Hero Animations](https://docs.flutter.dev/ui/animations/hero-animations)
- [Flutter Navigation](https://docs.flutter.dev/ui/navigation)

## 🤝 Contributing

When adding new transition types or modifying existing ones:

1. Update the `MaterialMotionTransitionType` enum
2. Add the transition logic in `MaterialMotionRoute.buildTransitions`
3. Update the demo screen to showcase the new transition
4. Add examples to the navigation examples file
5. Update this documentation

---

**Happy Coding! 🎉**
