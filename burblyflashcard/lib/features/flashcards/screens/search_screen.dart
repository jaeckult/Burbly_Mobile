import 'package:flutter/material.dart';
import '../../../core/core.dart';
import 'deck_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();
  
  Map<String, dynamic> _searchResults = {};
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = {};
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _dataService.searchAll(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
                     // Search Bar
           Container(
             padding: const EdgeInsets.all(16),
             child: TextField(
               controller: _searchController,
               autofocus: false,
               decoration: InputDecoration(
                 hintText: 'Search decks, flashcards, and notes...',
                 prefixIcon: Icon(
                   Icons.search,
                   color: Theme.of(context).primaryColor,
                 ),
                 suffixIcon: _searchController.text.isNotEmpty
                     ? IconButton(
                         icon: const Icon(Icons.clear),
                         onPressed: () {
                           _searchController.clear();
                           _performSearch('');
                         },
                       )
                     : null,
               ),
               textInputAction: TextInputAction.search,
               onChanged: (value) {
                 if (value.length >= 2) {
                   _performSearch(value);
                 } else if (value.isEmpty) {
                   _performSearch('');
                 }
               },
               onSubmitted: (value) {
                 if (value.isNotEmpty) {
                   _performSearch(value);
                 }
               },
             ),
           ),

          // Search Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Search for decks, flashcards, and notes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final decks = _searchResults['decks'] as List<Deck>? ?? [];
    final flashcards = _searchResults['flashcards'] as List<Flashcard>? ?? [];
    final notes = _searchResults['notes'] as List<Note>? ?? [];

    if (decks.isEmpty && flashcards.isEmpty && notes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Decks Section
        if (decks.isNotEmpty) ...[
          _buildSectionHeader('Decks', decks.length),
          const SizedBox(height: 8),
          ...decks.map((deck) => _buildDeckCard(deck)),
          const SizedBox(height: 16),
        ],

        // Flashcards Section
        if (flashcards.isNotEmpty) ...[
          _buildSectionHeader('Flashcards', flashcards.length),
          const SizedBox(height: 8),
          ...flashcards.map((flashcard) => _buildFlashcardCard(flashcard)),
          const SizedBox(height: 16),
        ],

        // Notes Section
        if (notes.isNotEmpty) ...[
          _buildSectionHeader('Notes', notes.length),
          const SizedBox(height: 8),
          ...notes.map((note) => _buildNoteCard(note)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckCard(Deck deck) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}')),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.school,
            color: Colors.white,
          ),
        ),
        title: Text(
          deck.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          deck.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${deck.cardCount} cards',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeckDetailScreen(deck: deck),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlashcardCard(Flashcard flashcard) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.quiz,
            color: Colors.blue,
          ),
        ),
        title: Text(
          flashcard.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          flashcard.answer,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Review: ${flashcard.reviewCount}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
            if (flashcard.nextReview != null)
              Text(
                'Due: ${_formatDate(flashcard.nextReview!)}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.note,
            color: Colors.green,
          ),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          note.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: note.tags.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  note.tags.first,
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
