import 'package:flutter/material.dart';
import '../../../core/core.dart';

class MySchedulesScreen extends StatefulWidget {
  const MySchedulesScreen({super.key});

  @override
  State<MySchedulesScreen> createState() => _MySchedulesScreenState();
}

class _MySchedulesScreenState extends State<MySchedulesScreen> {
  final DataService _dataService = DataService();
  List<Flashcard> _allFlashcards = [];
  List<Deck> _allDecks = [];
  List<CalendarEvent> _events = [];
  bool _isLoading = true;
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all decks and flashcards
      _allDecks = await _dataService.getDecks();
      _allFlashcards.clear();
      
      for (final deck in _allDecks) {
        final deckCards = await _dataService.getFlashcardsForDeck(deck.id);
        _allFlashcards.addAll(deckCards);
      }
      
      // Convert flashcards to calendar events
      _events = _convertFlashcardsToEvents();
      
    } catch (e) {
      print('Error loading calendar data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<CalendarEvent> _convertFlashcardsToEvents() {
    final List<CalendarEvent> events = [];
    final now = DateTime.now();
    
    // Add card-level review events
    for (final card in _allFlashcards) {
      if (card.nextReview != null) {
        // Create event for next review
        final reviewDate = card.nextReview!;
        final isOverdue = reviewDate.isBefore(now);
        
        events.add(CalendarEvent(
          date: reviewDate,
          title: card.question.length > 30 
              ? '${card.question.substring(0, 30)}...' 
              : card.question,
          color: _getEventColor(card, isOverdue),
          deckName: _getDeckName(card.deckId),
          interval: card.interval,
          isOverdue: isOverdue,
          cardId: card.id,
          eventType: CalendarEventType.cardReview,
        ));
      } else if (card.lastReviewed == null) {
        // New cards that haven't been studied yet - show them as due today
        events.add(CalendarEvent(
          date: now,
          title: card.question.length > 30 
              ? '${card.question.substring(0, 30)}...' 
              : card.question,
          color: Colors.orange, // Learning color for new cards
          deckName: _getDeckName(card.deckId),
          interval: 1,
          isOverdue: false,
          cardId: card.id,
          eventType: CalendarEventType.cardReview,
          isNewCard: true,
        ));
      }
      
      // Add events for future reviews (next 3 reviews)
      if (card.interval > 1) {
        DateTime nextReview = card.nextReview ?? now;
        for (int i = 1; i <= 3; i++) {
          nextReview = nextReview.add(Duration(days: card.interval));
          
          if (nextReview.isAfter(now) && nextReview.isBefore(now.add(const Duration(days: 90)))) {
            events.add(CalendarEvent(
              date: nextReview,
              title: card.question.length > 30 
                  ? '${card.question.substring(0, 30)}...' 
                  : card.question,
              color: _getEventColor(card, false),
              deckName: _getDeckName(card.deckId),
              interval: card.interval,
              isOverdue: false,
              cardId: card.id,
              isFutureReview: true,
              eventType: CalendarEventType.cardReview,
            ));
          }
        }
      }
    }
    
    // Add deck-level scheduled review events
    for (final deck in _allDecks) {
      if (deck.scheduledReviewEnabled == true && deck.scheduledReviewTime != null) {
        final scheduledDate = deck.scheduledReviewTime!;
        final isOverdue = scheduledDate.isBefore(now);
        
        events.add(CalendarEvent(
          date: scheduledDate,
          title: 'Deck Review: ${deck.name}',
          color: isOverdue ? Colors.red : Colors.indigo,
          deckName: deck.name,
          interval: 0, // Not applicable for deck reviews
          isOverdue: isOverdue,
          cardId: '', // Not applicable for deck reviews
          eventType: CalendarEventType.deckReview,
          deckId: deck.id,
        ));
      }
    }
    
    return events;
  }

  Color _getEventColor(Flashcard card, bool isOverdue) {
    if (isOverdue) return Colors.red;
    
    // Color based on interval
    if (card.interval <= 1) return Colors.orange; // Learning
    if (card.interval <= 7) return Colors.blue; // Short term
    if (card.interval <= 30) return Colors.green; // Medium term
    return Colors.purple; // Long term
  }

  String _getDeckName(String deckId) {
    try {
      final deck = _allDecks.firstWhere((deck) => deck.id == deckId);
      return deck.name;
    } catch (e) {
      return 'Deck ${deckId.substring(0, 8)}...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedules'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCalendarData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendarHeader(),
                Expanded(
                  child: _buildCalendar(),
                ),
                _buildLegend(),
              ],
            ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Study Schedule',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_events.length} reviews scheduled',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Tap on dates to see events',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        _buildCalendarNavigation(),
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  Widget _buildCalendarNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    // Calculate the first day to show (including previous month's days)
    final firstDayToShow = firstDayOfMonth.subtract(Duration(days: firstWeekday - 1));
    
    return Column(
      children: [
        // Day headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final date = firstDayToShow.add(Duration(days: index));
              final isCurrentMonth = date.month == _focusedDate.month;
              final isToday = _isSameDay(date, DateTime.now());
              final isSelected = _selectedDate != null && _isSameDay(date, _selectedDate!);
              final dayEvents = _getEventsForDate(date);
              
              return _buildCalendarDay(date, isCurrentMonth, isToday, isSelected, dayEvents);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime date, bool isCurrentMonth, bool isToday, bool isSelected, List<CalendarEvent> events) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        if (events.isNotEmpty) {
          _showEventsForDate(date, events);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : isToday
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : isToday
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1)
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Date number
            Container(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isCurrentMonth
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            // Event indicators
            if (events.isNotEmpty) ...[
              const SizedBox(height: 2),
              ...events.take(3).map((event) => Container(
                width: 6,
                height: 2,
                margin: const EdgeInsets.only(bottom: 1),
                decoration: BoxDecoration(
                  color: event.color,
                  borderRadius: BorderRadius.circular(1),
                ),
              )),
              if (events.length > 3)
                Container(
                  width: 6,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return _events.where((event) => _isSameDay(event.date, date)).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _showEventsForDate(DateTime date, List<CalendarEvent> events) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.event,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text('${_getMonthName(date.month)} ${date.day}, ${date.year}'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${events.length} review${events.length == 1 ? '' : 's'} scheduled',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ...events.map((event) => _buildEventItem(event)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: event.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: event.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: event.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Deck: ${event.deckName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (event.eventType == CalendarEventType.cardReview) ...[
            if (event.isNewCard) ...[
              Text(
                'New Card - Ready to Study',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Text(
                'Interval: ${event.interval} days${event.isOverdue ? ' (Overdue)' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: event.isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ] else ...[
            Text(
              'Scheduled Deck Review${event.isOverdue ? ' (Overdue)' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: event.isOverdue ? Colors.red : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Overdue', Colors.red),
              _buildLegendItem('Learning', Colors.orange),
              _buildLegendItem('Short Term', Colors.blue),
              _buildLegendItem('Medium Term', Colors.green),
              _buildLegendItem('Long Term', Colors.purple),
              _buildLegendItem('Deck Review', Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

enum CalendarEventType {
  cardReview,
  deckReview,
}

class CalendarEvent {
  final DateTime date;
  final String title;
  final Color color;
  final String deckName;
  final int interval;
  final bool isOverdue;
  final String cardId;
  final bool isFutureReview;
  final CalendarEventType eventType;
  final String? deckId;
  final bool isNewCard;

  CalendarEvent({
    required this.date,
    required this.title,
    required this.color,
    required this.deckName,
    required this.interval,
    required this.isOverdue,
    required this.cardId,
    this.isFutureReview = false,
    required this.eventType,
    this.deckId,
    this.isNewCard = false,
  });
}
