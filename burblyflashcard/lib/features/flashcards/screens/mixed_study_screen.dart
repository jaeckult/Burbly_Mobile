import 'package:flutter/material.dart';
import '../../../core/core.dart';
import 'anki_study_screen.dart';
import 'dart:async';

class MixedStudyScreen extends StatefulWidget {
  const MixedStudyScreen({super.key});

  @override
  State<MixedStudyScreen> createState() => _MixedStudyScreenState();
}

class _MixedStudyScreenState extends State<MixedStudyScreen> {
  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  
  List<Flashcard> _overdueCards = [];
  List<Flashcard> _cardsDueToday = [];
  List<Deck> _allDecks = [];
  bool _isLoading = true;
  bool _isStartingStudy = false;

  @override
  void initState() {
    super.initState();
    _loadMixedStudyData();
    
    // Testing mode: auto-refresh based on testing mode service
    if (TestingModeService().isTestingMode) {
      Timer.periodic(TestingModeService().mixedStudyRefreshInterval, (timer) {
        if (mounted) {
          _loadMixedStudyData();
        } else {
          timer.cancel();
        }
      });
    }
  }

  Future<void> _loadMixedStudyData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all decks first
      final decks = await _dataService.getDecks();
      
      // Load overdue and due cards
      final overdueCards = await _notificationService.getOverdueCards();
      final cardsDueToday = await _notificationService.getCardsDueToday();
      
      // Combine all cards that need review
      final allCardsToReview = [...overdueCards, ...cardsDueToday];
      
      // Remove duplicates (in case a card appears in both lists)
      final uniqueCards = <String, Flashcard>{};
      for (final card in allCardsToReview) {
        uniqueCards[card.id] = card;
      }
      
      if (mounted) {
        setState(() {
          _allDecks = decks;
          _overdueCards = overdueCards;
          _cardsDueToday = cardsDueToday;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading mixed study data: $e');
    }
  }

  void _startMixedStudy() async {
    setState(() => _isStartingStudy = true);
    
    try {
      // Combine all cards that need review
      final allCardsToReview = [..._overdueCards, ..._cardsDueToday];
      
      // Remove duplicates
      final uniqueCards = <String, Flashcard>{};
      for (final card in allCardsToReview) {
        uniqueCards[card.id] = card;
      }
      
      final cardsToStudy = uniqueCards.values.toList();
      
      if (cardsToStudy.isEmpty) {
        if (mounted) {
          SnackbarUtils.showWarningSnackbar(
            context,
            'No cards need review at the moment!',
          );
        }
        return;
      }

      // Create a virtual "Mixed Study" deck for the study session
      final mixedDeck = Deck(
        id: 'mixed_study_session',
        name: 'Mixed Study',
        description: 'Cards from all decks that need review',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        coverColor: '9C27B0', // Purple color for mixed study
        spacedRepetitionEnabled: true,
        showStudyStats: true,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnkiStudyScreen(
              deck: mixedDeck,
              flashcards: cardsToStudy,
            ),
          ),
        ).then((_) {
          // Refresh data when returning from study
          _loadMixedStudyData();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Error starting mixed study: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingStudy = false);
      }
    }
  }

  Color _getDeckColor(String deckId) {
    try {
      final deck = _allDecks.firstWhere((d) => d.id == deckId);
      return Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}'));
    } catch (e) {
      return Colors.blue; // Default color
    }
  }

  String _getDeckName(String deckId) {
    try {
      final deck = _allDecks.firstWhere((d) => d.id == deckId);
      return deck.name;
    } catch (e) {
      return 'Unknown Deck';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mixed Study'),
        backgroundColor: const Color(0xFF9C27B0), // Purple theme
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMixedStudyData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final totalCardsToReview = _overdueCards.length + _cardsDueToday.length;
    
    if (totalCardsToReview == 0) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Header with study info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF9C27B0),
                Color(0xFF7B1FA2),
              ],
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.school,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Mixed Study Session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalCardsToReview cards need review',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
                             Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: Colors.white.withOpacity(0.2),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: const Row(
                   children: [
                     Icon(Icons.info_outline, color: Colors.white, size: 20),
                     SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         'This session includes cards from all your decks that need review. Cards will be shown using spaced repetition (Anki-style).',
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: 14,
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
               // Testing mode indicator
               if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                 const SizedBox(height: 8),
                 Container(
                   padding: const EdgeInsets.all(8),
                   decoration: BoxDecoration(
                     color: Colors.orange.withOpacity(0.3),
                     borderRadius: BorderRadius.circular(8),
                   ),
                   child: const Row(
                     children: [
                       Icon(Icons.bug_report, color: Colors.white, size: 16),
                       SizedBox(width: 8),
                                               const Text(
                          'Testing Mode: Auto-refresh enabled',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                     ],
                   ),
                 ),
               ],
            ],
          ),
        ),

        // Study button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isStartingStudy ? null : _startMixedStudy,
              icon: _isStartingStudy 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow, size: 24),
              label: Text(
                _isStartingStudy ? 'Starting Study...' : 'Start Mixed Study',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // Cards breakdown
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cards Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Overdue cards section
                if (_overdueCards.isNotEmpty) ...[
                  _buildCardSection(
                    'Overdue Cards',
                    _overdueCards,
                    Colors.orange,
                    Icons.warning,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Due today cards section
                if (_cardsDueToday.isNotEmpty) ...[
                  _buildCardSection(
                    'Due Today',
                    _cardsDueToday,
                    Colors.blue,
                    Icons.today,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardSection(String title, List<Flashcard> cards, Color color, IconData icon) {
    // Group cards by deck
    final Map<String, List<Flashcard>> cardsByDeck = {};
    for (final card in cards) {
      cardsByDeck.putIfAbsent(card.deckId, () => []).add(card);
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$title (${cards.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ...cardsByDeck.entries.map((entry) {
            final deckId = entry.key;
            final deckCards = entry.value;
            final deckColor = _getDeckColor(deckId);
            final deckName = _getDeckName(deckId);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: deckColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: deckColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deckName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${deckCards.length} cards',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'All Caught Up! 🎉',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No cards need review at the moment.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMixedStudyData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
