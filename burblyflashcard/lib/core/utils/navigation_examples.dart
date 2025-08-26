import 'package:flutter/material.dart';
import 'navigation_helper.dart';

/// This file shows practical examples of how to refactor existing navigation calls
/// to use the new Material Motion transitions and navigation helpers.

/// Example 1: Refactoring a simple push navigation
/// BEFORE:
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => CreateDeckPackScreen(),
///   ),
/// );
/// 
/// AFTER:
/// context.pushFade(CreateDeckPackScreen());
/// OR
/// context.pushSharedAxis(CreateDeckPackScreen());
/// OR
/// context.pushScale(CreateDeckPackScreen());

/// Example 2: Refactoring navigation with callbacks
/// BEFORE:
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => CreateDeckPackScreen(
///       onDeckPackCreated: (deckPack) {
///         // Handle callback
///       },
///     ),
///   ),
/// );
/// 
/// AFTER:
/// final result = await context.pushFade(
///   CreateDeckPackScreen(
///     onDeckPackCreated: (deckPack) {
///       // Handle callback
///     },
///   ),
/// );
/// 
/// // Or use the NavigationHelper directly for more control:
/// final result = await NavigationHelper.push(
///   context,
///   CreateDeckPackScreen(
///     onDeckPackCreated: (deckPack) {
///       // Handle callback
///     },
///   ),
///   transitionType: MaterialMotionTransitionType.fadeThrough,
///   duration: const Duration(milliseconds: 400),
/// );

/// Example 3: Refactoring navigation with replacement
/// BEFORE:
/// Navigator.pushReplacement(
///   context,
///   MaterialPageRoute(
///     builder: (context) => HomeScreen(),
///   ),
/// );
/// 
/// AFTER:
/// NavigationHelper.pushReplacement(
///   context,
///   HomeScreen(),
///   transitionType: MaterialMotionTransitionType.fadeThrough,
/// );

/// Example 4: Refactoring navigation with stack clearing
/// BEFORE:
/// Navigator.pushAndRemoveUntil(
///   context,
///   MaterialPageRoute(
///     builder: (context) => HomeScreen(),
///   ),
///   (route) => false,
/// );
/// 
/// AFTER:
/// NavigationHelper.pushAndClearStack(
///   context,
///   HomeScreen(),
///   transitionType: MaterialMotionTransitionType.scale,
/// );

/// Example 5: Using Hero animations with navigation
/// BEFORE:
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => DetailScreen(item: item),
///   ),
/// );
/// 
/// AFTER:
/// context.pushFadeThrough(
///   DetailScreen(item: item),
/// );
/// 
/// // And wrap the shared element with HeroWrapper:
/// HeroWrapper(
///   tag: 'item_${item.id}',
///   child: Image.network(item.imageUrl),
/// )

/// Example 6: Theme-aware navigation with custom durations
/// 
/// // For light mode - faster, snappier transitions
/// if (Theme.of(context).brightness == Brightness.light) {
///   context.pushFade(
///     NextScreen(),
///     duration: const Duration(milliseconds: 250),
///   );
/// } else {
///   // For dark mode - slower, more elegant transitions
///   context.pushFade(
///     NextScreen(),
///     duration: const Duration(milliseconds: 350),
///   );
/// }

/// Example 7: Batch navigation operations
/// 
/// // Navigate to multiple screens with different transitions
/// Future<void> navigateToStudyFlow() async {
///   // Start with fade transition
///   await context.pushFade(StudyModeSelectionScreen());
///   
///   // Then use shared axis for related screens
///   await context.pushSharedAxis(StudyScreen());
///   
///   // Finally use scale transition for results
///   await context.pushScale(StudyResultsScreen());
/// }

/// Example 8: Conditional navigation based on user preferences
/// 
/// Future<void> navigateWithUserPreference() async {
///   final userPrefersFastTransitions = await getUserPreference();
///   
///   if (userPrefersFastTransitions) {
///     context.pushFade(
///       NextScreen(),
///       duration: const Duration(milliseconds: 200),
///     );
///   } else {
///     context.pushFadeThrough(
///       NextScreen(),
///       duration: const Duration(milliseconds: 400),
///     );
///   }
/// }

/// Example 9: Error handling with navigation
/// 
/// Future<void> navigateWithErrorHandling() async {
///   try {
///     final result = await context.pushFade(NextScreen());
///     // Handle successful navigation result
///   } catch (e) {
///     // Handle navigation errors
///     print('Navigation error: $e');
///   }
/// }

/// Example 10: Custom transition combinations
/// 
/// // Create a custom transition by combining multiple effects
/// class CustomTransitionRoute extends MaterialMotionRoute {
///   CustomTransitionRoute({required super.child});
///   
///   @override
///   Widget buildTransitions(
///     BuildContext context,
///     Animation<double> animation,
///     Animation<double> secondaryAnimation,
///     Widget child,
///   ) {
///     return SlideTransition(
///       position: Tween<Offset>(
///         begin: const Offset(0.0, 1.0),
///         end: Offset.zero,
///       ).animate(CurvedAnimation(
///         parent: animation,
///         curve: Curves.elasticOut,
///       )),
///       child: ScaleTransition(
///         scale: Tween<double>(
///           begin: 0.5,
///           end: 1.0,
///         ).animate(animation),
///         child: child,
///       ),
///     );
///   }
/// }
/// 
/// // Usage:
/// Navigator.of(context).push(
///   CustomTransitionRoute(
///     child: NextScreen(),
///   ),
/// );
