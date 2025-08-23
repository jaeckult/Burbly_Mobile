import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/flashcard.dart';
import '../screens/notification_settings_screen.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  final NotificationService _notificationService = NotificationService();
  List<Flashcard> _overdueCards = [];
  List<Flashcard> _cardsDueToday = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationData();
  }

  Future<void> _loadNotificationData() async {
    setState(() => _isLoading = true);
    
    try {
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to study screen or deck list
                  Navigator.pushNamed(context, '/flashcards');
                },
                icon: const Icon(Icons.school),
                label: Text(
                  hasOverdueCards 
                    ? 'Review Overdue Cards' 
                    : 'Start Studying',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasOverdueCards ? Colors.orange : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
