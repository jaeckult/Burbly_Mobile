import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart';

/// Demo screen showcasing different transition types and Hero animations
class TransitionDemoScreen extends StatelessWidget {
  const TransitionDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transition Demo'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero animation demo section
            _buildHeroSection(context, theme),
            const SizedBox(height: 24),
            
            // Transition types section
            _buildTransitionSection(context, theme),
            const SizedBox(height: 24),
            
            // Navigation examples section
            _buildNavigationExamples(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hero Animations',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: HeroWrapper(
                    tag: 'demo_hero',
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tap to see Hero animation',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showHeroDetail(context),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionSection(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transition Types',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildTransitionButton(
              context,
              'Fade Transition',
              Icons.opacity,
              MaterialMotionTransitionType.fade,
              theme,
            ),
            const SizedBox(height: 8),
            _buildTransitionButton(
              context,
              'Fade Through',
              Icons.animation,
              MaterialMotionTransitionType.fadeThrough,
              theme,
            ),
            const SizedBox(height: 8),
            _buildTransitionButton(
              context,
              'Shared Axis',
              Icons.swap_horiz,
              MaterialMotionTransitionType.sharedAxis,
              theme,
            ),
            const SizedBox(height: 8),
            _buildTransitionButton(
              context,
              'Scale Transition',
              Icons.zoom_in,
              MaterialMotionTransitionType.scale,
              theme,
            ),
            const SizedBox(height: 8),
            _buildTransitionButton(
              context,
              'Slide Transition',
              Icons.arrow_forward,
              MaterialMotionTransitionType.slide,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionButton(
    BuildContext context,
    String label,
    IconData icon,
    MaterialMotionTransitionType transitionType,
    ThemeData theme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showTransitionDemo(context, transitionType),
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _buildNavigationExamples(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Navigation Examples',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.pushFade(
                      const TransitionDemoScreen(),
                    ),
                    icon: const Icon(Icons.opacity),
                    label: const Text('Fade'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.pushSharedAxis(
                      const TransitionDemoScreen(),
                    ),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Shared Axis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.pushScale(
                      const TransitionDemoScreen(),
                    ),
                    icon: const Icon(Icons.zoom_in),
                    label: const Text('Scale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.pushSlide(
                      const TransitionDemoScreen(),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Slide'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHeroDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialMotionRoute(
        child: const HeroDetailScreen(),
        transitionType: MaterialMotionTransitionType.fadeThrough,
      ),
    );
  }

  void _showTransitionDemo(
    BuildContext context,
    MaterialMotionTransitionType transitionType,
  ) {
    NavigationHelper.push(
      context,
      TransitionDemoScreen(),
      transitionType: transitionType,
    );
  }
}

/// Detail screen for Hero animation demo
class HeroDetailScreen extends StatelessWidget {
  const HeroDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Detail'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HeroWrapper(
              tag: 'demo_hero',
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                      theme.colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Hero Animation Demo',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This screen demonstrates how Hero animations work with shared elements between screens.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
