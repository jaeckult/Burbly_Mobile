import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/data_service.dart';
import 'add_flashcard_screen.dart';
import 'study_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailScreen({
    super.key,
    required this.deck,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final DataService _dataService = DataService();
  List<Flashcard> _flashcards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    final flashcards = await _dataService.getFlashcardsForDeck(widget.deck.id);
    setState(() {
      _flashcards = flashcards;
      _isLoading = false;
    });
  }

  void _addFlashcard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFlashcardScreen(deckId: widget.deck.id),
      ),
    ).then((_) => _loadFlashcards());
  }

  void _startStudy() {
    if (_flashcards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some flashcards to start studying!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyScreen(
          deck: widget.deck,
          flashcards: _flashcards,
        ),
      ),
    ).then((_) => _loadFlashcards());
  }

  void _showFlashcardOptions(Flashcard flashcard) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Flashcard'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit flashcard
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Flashcard', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteFlashcard(flashcard);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFlashcard(Flashcard flashcard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flashcard'),
        content: const Text('Are you sure you want to delete this flashcard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.deleteFlashcard(flashcard.id);
      await _loadFlashcards();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.name),
        backgroundColor: Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _startStudy,
            tooltip: 'Start Studying',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFlashcard,
        backgroundColor: Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Deck Info Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
                Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.deck.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.deck.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.deck.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.style,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_flashcards.length} flashcards',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (_flashcards.isNotEmpty) ...[
                    Icon(
                      Icons.timer,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_flashcards.length * 0.5).ceil()} min',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Flashcards List
        Expanded(
          child: _flashcards.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _flashcards.length,
                  itemBuilder: (context, index) {
                    final flashcard = _flashcards[index];
                    return _buildFlashcardCard(flashcard);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No flashcards yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first flashcard to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addFlashcard,
            icon: const Icon(Icons.add),
            label: const Text('Add Flashcard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardCard(Flashcard flashcard) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showFlashcardOptions(flashcard),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Q: ${flashcard.question}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showFlashcardOptions(flashcard),
                    icon: const Icon(Icons.more_vert),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A: ${flashcard.answer}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Difficulty: ${flashcard.difficulty}/5',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (flashcard.lastReviewed != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(flashcard.lastReviewed!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
