import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/core.dart';
import '../../../core/models/flashcard.dart';
import '../screens/anki_study_screen.dart';
import '../screens/notification_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  final NotificationService _notificationService = NotificationService();
  final DataService _dataService = DataService();
  List<Flashcard> _overdueCards = [];
  List<Flashcard> _cardsDueToday = [];
  bool _isLoading = true;

  Future<void> _startAutomaticStudy() async {
    try {
      // Dismiss widget for today
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('notification_widget_dismissed_date', '${now.year}-${now.month}-${now.day}');
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

      // Load deck and its flashcards for study
      final decks = await _dataService.getDecks();
      final deck = decks.firstWhere((d) => d.id == bestDeckId, orElse: () => decks.isNotEmpty ? decks.first : throw Exception('No decks found'));
      final allDeckCards = await _dataService.getFlashcardsForDeck(deck.id);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnkiStudyScreen(deck: deck, flashcards: allDeckCards),
        ),
      );
    } catch (e) {
      // Fallback navigation
      if (!mounted) return;
      Navigator.pushNamed(context, '/flashcards');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationData();
  }

  Future<void> _loadNotificationData() async {
    setState(() => _isLoading = true);
    
    try {
      // Respect dismissal for today
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final dismissedDate = prefs.getString('notification_widget_dismissed_date');
      if (dismissedDate == todayKey) {
        setState(() {
          _overdueCards = [];
          _cardsDueToday = [];
          _isLoading = false;
        });
        return;
      }

      final overdueCards = await _notificationService.getOverdueCards();
      final cardsDueToday = await _notificationService.getCardsDueToday();
      
      setState(() {
        _overdueCards = overdueCards;
        _cardsDueToday = cardsDueToday;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading notification data: $e');
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
                        // Persist dismissal for today and hide
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final now = DateTime.now();
                          await prefs.setString('notification_widget_dismissed_date', '${now.year}-${now.month}-${now.day}');
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
            ],
          ),
        ),
      ),
    );
  }
}
