import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/core.dart';
import '../../../core/models/flashcard.dart';
import '../screens/anki_study_screen.dart';
import '../screens/notification_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final DataService _dataService = DataService();
  List<Flashcard> _overdueCards = [];
  List<Flashcard> _cardsDueToday = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotificationData();
    _setupPeriodicRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app becomes active (user returns to app)
    if (state == AppLifecycleState.resumed) {
      _loadNotificationData();
    }
  }

  void _setupPeriodicRefresh() {
    // Refresh every 15 minutes to check for new due cards
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (mounted) {
        _loadNotificationData();
      }
    });
  }

  Future<void> _startAutomaticStudy() async {
    try {
      // Dismiss widget for a shorter period (1 hour instead of full day)
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dismissUntil = now.add(const Duration(hours: 4));
      await prefs.setString('notification_widget_dismissed_until', dismissUntil.toIso8601String());
      
      if (mounted) {
        setState(() {
          _overdueCards = [];
          _cardsDueToday = [];
        });
      }

      // Decide target set: prefer overdue; else today's due
      final targetCards = _overdueCards.isNotEmpty ? _overdueCards : _cardsDueToday;
      if (targetCards.isEmpty) {
        // Fallback to My Decks if nothing to review
        Navigator.pushNamed(context, '/flashcards');
        return;
      }

      // Group by deckId and pick deck with most due cards
      final Map<String, List<Flashcard>> byDeck = {};
      for (final card in targetCards) {
        byDeck.putIfAbsent(card.deckId, () => []).add(card);
      }
      String bestDeckId = byDeck.keys.first;
      int bestCount = byDeck[bestDeckId]!.length;
      byDeck.forEach((deckId, cards) {
        if (cards.length > bestCount) {
          bestDeckId = deckId;
          bestCount = cards.length;
        }
      });

      // Load deck
      final decks = await _dataService.getDecks();
      final deck = decks.firstWhere((d) => d.id == bestDeckId, orElse: () => decks.isNotEmpty ? decks.first : throw Exception('No decks found'));

      // Use only due cards for that deck (overdue preferred; else today's due)
      final dueCardsForDeck = targetCards.where((c) => c.deckId == deck.id).toList();
      if (dueCardsForDeck.isEmpty) {
        // Fallback: if something went wrong, load all deck cards
        final fallback = await _dataService.getFlashcardsForDeck(deck.id);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnkiStudyScreen(deck: deck, flashcards: fallback),
          ),
        );
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnkiStudyScreen(deck: deck, flashcards: dueCardsForDeck),
        ),
      );
    } catch (e) {
      // Fallback navigation
      if (!mounted) return;
      Navigator.pushNamed(context, '/flashcards');
    }
  }

  Future<void> _loadNotificationData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Check if widget is dismissed until a specific time
      final prefs = await SharedPreferences.getInstance();
      final dismissedUntilString = prefs.getString('notification_widget_dismissed_until');
      
      if (dismissedUntilString != null) {
        try {
          final dismissedUntil = DateTime.parse(dismissedUntilString);
          final now = DateTime.now();
          
          print('Notification widget: Dismissed until $dismissedUntil, current time: $now');
          
          // If still within dismissal period, don't show widget
          if (now.isBefore(dismissedUntil)) {
            print('Notification widget: Still dismissed, hiding widget');
            if (mounted) {
              setState(() {
                _overdueCards = [];
                _cardsDueToday = [];
                _isLoading = false;
              });
            }
            return;
          } else {
            // Clear expired dismissal
            print('Notification widget: Dismissal expired, clearing');
            await prefs.remove('notification_widget_dismissed_until');
          }
        } catch (e) {
          // If parsing fails, clear the invalid dismissal
          print('Notification widget: Error parsing dismissal time, clearing: $e');
          await prefs.remove('notification_widget_dismissed_until');
        }
      }

      print('Notification widget: Loading overdue and due cards...');
      
      // First, let's check if there are any cards at all
      final allCards = await _dataService.getAllFlashcards();
      print('Notification widget: Total cards in database: ${allCards.length}');
      
      if (allCards.isNotEmpty) {
        // Log some sample cards to see their nextReview dates
        for (int i = 0; i < allCards.length && i < 3; i++) {
          final card = allCards[i];
          print('Notification widget: Card ${i + 1}: nextReview=${card.nextReview}, lastReviewed=${card.lastReviewed}');
        }
      }
      
      final overdueCards = await _notificationService.getOverdueCards();
      final cardsDueToday = await _notificationService.getCardsDueToday();
      
      print('Notification widget: Found ${overdueCards.length} overdue cards and ${cardsDueToday.length} due today');
      
      if (mounted) {
        setState(() {
          _overdueCards = overdueCards;
          _cardsDueToday = cardsDueToday;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading notification data: $e');
    }
  }

  // Method to manually refresh the widget (can be called from parent)
  Future<void> refreshWidget() async {
    print('Notification widget: Manual refresh requested');
    await _loadNotificationData();
  }

  // Debug method to force show the widget for testing
  void _forceShowWidget() {
    print('Notification widget: Force showing widget for testing');
    setState(() {
      _overdueCards = [
        Flashcard(
          id: 'test-overdue',
          deckId: 'test-deck',
          question: 'Test overdue card',
          answer: 'Test answer',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          nextReview: DateTime.now().subtract(const Duration(hours: 1)),
        )
      ];
      _cardsDueToday = [
        Flashcard(
          id: 'test-due-today',
          deckId: 'test-deck',
          question: 'Test due today card',
          answer: 'Test answer',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
          nextReview: DateTime.now(),
        )
      ];
      _isLoading = false;
    });
  }

  // Debug method to test the notification service directly
  Future<void> _testNotificationService() async {
    print('Notification widget: Testing notification service...');
    try {
      final overdueCards = await _notificationService.getOverdueCards();
      final cardsDueToday = await _notificationService.getCardsDueToday();
      final cardsDueSoon = await _notificationService.getCardsDueSoon();
      
      print('Notification widget: Test results:');
      print('  - Overdue cards: ${overdueCards.length}');
      print('  - Due today: ${cardsDueToday.length}');
      print('  - Due soon: ${cardsDueSoon.length}');
      
      if (overdueCards.isNotEmpty) {
        print('  - Sample overdue card: nextReview=${overdueCards.first.nextReview}');
      }
      if (cardsDueToday.isNotEmpty) {
        print('  - Sample due today card: nextReview=${cardsDueToday.first.nextReview}');
      }
    } catch (e) {
      print('Notification widget: Error testing notification service: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final hasOverdueCards = _overdueCards.isNotEmpty;
    final hasCardsDueToday = _cardsDueToday.isNotEmpty;

    if (!hasOverdueCards && !hasCardsDueToday) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasOverdueCards ? Icons.warning : Icons.notifications,
                    color: hasOverdueCards ? Colors.orange : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasOverdueCards ? 'Cards Need Review!' : 'Study Reminder',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    tooltip: 'Notification Settings',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasOverdueCards) ...[
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_overdueCards.length} cards overdue',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (hasCardsDueToday) ...[
                Row(
                  children: [
                    const Icon(Icons.today, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_cardsDueToday.length} cards due today',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startAutomaticStudy,
                      icon: const Icon(Icons.school),
                      label: const Text('Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasOverdueCards ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        // Dismiss for 1 hour instead of full day
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final now = DateTime.now();
                          final dismissUntil = now.add(const Duration(hours: 1));
                          await prefs.setString('notification_widget_dismissed_until', dismissUntil.toIso8601String());
                        } catch (_) {}
                        if (!mounted) return;
                        setState(() {
                          _overdueCards = [];
                          _cardsDueToday = [];
                        });
                      },
                      child: const Text('Not Now'),
                    ),
                  ),
                ],
              ),
              // Debug buttons (only show in debug mode)
           ],
          ),
        ),
      ),
    );
  }
}
