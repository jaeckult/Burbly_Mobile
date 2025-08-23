import 'package:flutter/material.dart';
import '../../../core/core.dart';
import 'study_screen.dart';
import 'enhanced_study_screen.dart';
import 'anki_study_screen.dart';

class StudyModeSelectionScreen extends StatelessWidget {
  final Deck deck;
  final List<Flashcard> flashcards;

  const StudyModeSelectionScreen({
    super.key,
    required this.deck,
    required this.flashcards,
  });

  @override
  Widget build(BuildContext context) {
    final deckColor = Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}'));

    return Scaffold(
      appBar: AppBar(
        title: Text('Study: ${deck.name}'),
        backgroundColor: deckColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              deckColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: deckColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose Study Mode',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: deckColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${flashcards.length} cards available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Study Mode Options
                _buildStudyModeCard(
                  context,
                  title: 'Anki-Style Spaced Repetition',
                  subtitle: 'Recommended for long-term learning',
                  description:
                      'Uses SM2 algorithm to schedule cards optimally. Cards appear based on your performance.',
                  icon: Icons.psychology,
                  color: Colors.blue,
                  isRecommended: true,
                  onTap: () => _navigateToStudyMode(context, StudyMode.anki),
                ),
                const SizedBox(height: 12),
                _buildStudyModeCard(
                  context,
                  title: 'Enhanced Study Mode',
                  subtitle: 'Interactive learning with navigation',
                  description:
                      'Study cards with navigation controls and spaced repetition info.',
                  icon: Icons.touch_app,
                  color: Colors.green,
                  isRecommended: false,
                  onTap: () => _navigateToStudyMode(context, StudyMode.enhanced),
                ),
                const SizedBox(height: 12),
                _buildStudyModeCard(
                  context,
                  title: 'Basic Study Mode',
                  subtitle: 'Simple and straightforward',
                  description:
                      'Traditional flashcard study with basic progress tracking.',
                  icon: Icons.flip_to_front,
                  color: Colors.orange,
                  isRecommended: false,
                  onTap: () => _navigateToStudyMode(context, StudyMode.basic),
                ),
                const SizedBox(height: 20),

                // Study Tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Study Tips',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Try to recall answers before revealing them\n'
                        '• Be honest with your self-assessment\n'
                        '• Study regularly for best results\n'
                        '• Use spaced repetition for long-term retention',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyModeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecommended ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: const Color.fromARGB(255, 28, 27, 27),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToStudyMode(BuildContext context, StudyMode mode) {
    Widget studyScreen;

    switch (mode) {
      case StudyMode.anki:
        studyScreen = AnkiStudyScreen(deck: deck, flashcards: flashcards);
        break;
      case StudyMode.enhanced:
        studyScreen = EnhancedStudyScreen(deck: deck, flashcards: flashcards);
        break;
      case StudyMode.basic:
        studyScreen = StudyScreen(deck: deck, flashcards: flashcards);
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => studyScreen),
    );
  }
}

enum StudyMode {
  anki,
  enhanced,
  basic,
}
