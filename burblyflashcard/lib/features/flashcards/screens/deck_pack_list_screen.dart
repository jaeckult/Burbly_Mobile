import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/auth_service.dart';
import '../../../core/core.dart';
import 'create_deck_pack_screen.dart';
import 'deck_pack_detail_screen.dart';
import 'flashcard_home_screen.dart';
import 'notes_screen.dart';
import 'search_screen.dart';
import '../../stats/stats_page.dart';

class DeckPackListScreen extends StatefulWidget {
  const DeckPackListScreen({super.key});

  @override
  State<DeckPackListScreen> createState() => _DeckPackListScreenState();
}

class _DeckPackListScreenState extends State<DeckPackListScreen> {
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  List<DeckPack> _deckPacks = [];
  bool _isLoading = true;
  bool _isGuestMode = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Ensure DataService is initialized
      if (!_dataService.isInitialized) {
        await _dataService.initialize();
      }

      _isGuestMode = await _dataService.isGuestMode();
      await _loadDeckPacks();
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDeckPacks() async {
    try {
      final deckPacks = await _dataService.getDeckPacks();
      setState(() => _deckPacks = deckPacks);
    } catch (e) {
      print('Error loading deck packs: $e');
    }
  }

  void _createNewDeckPack() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDeckPackScreen(
          onDeckPackCreated: (deckPack) {
            setState(() => _deckPacks.add(deckPack));
          },
        ),
      ),
    );
  }

  void _showDeckPackOptions(DeckPack deckPack) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Deck Pack'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit deck pack
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Deck Pack',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteDeckPack(deckPack);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDeckPack(DeckPack deckPack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck Pack'),
        content: Text(
          'Are you sure you want to delete "${deckPack.name}"? This action cannot be undone.',
        ),
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
      try {
        await _dataService.deleteDeckPack(deckPack.id);
        setState(() => _deckPacks.removeWhere((d) => d.id == deckPack.id));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deck pack "${deckPack.name}" deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting deck pack: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        // Update guest mode status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isGuestMode', false);

        setState(() => _isGuestMode = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Successfully signed in! Use the backup button to sync your data.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _backupToCloud() async {
    try {
      await _dataService.backupToFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();

      // Update guest mode status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', true);

      setState(() => _isGuestMode = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-out failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Burbly Flashcard',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.school,
        size: 48,
        color: Theme.of(context).primaryColor,
      ),
      children: [
        const Text(
          'A smart flashcard app that works offline and syncs your data when you sign in.',
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              _isGuestMode ? 'Guest User' : (user?.displayName ?? 'User'),
            ),
            accountEmail: Text(
              _isGuestMode ? 'Offline mode' : (user?.email ?? ''),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: _isGuestMode
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : user?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoURL!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.person, size: 40, color: Colors.grey),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Deck Packs'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('My Decks'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FlashcardHomeScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.note),
                  title: const Text('Notes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotesScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Statistics'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StatsPage()),
                    );
                  },
                ),
                const Divider(),
                if (_isGuestMode) ...[
                  ListTile(
                    leading: const Icon(Icons.cloud_sync),
                    title: const Text('Sign in with Google'),
                    subtitle: const Text('Sync your data'),
                    onTap: () {
                      Navigator.pop(context);
                      _signInWithGoogle();
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Backup to Cloud'),
                    subtitle: const Text('Sync your data'),
                    onTap: () {
                      Navigator.pop(context);
                      _backupToCloud();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: () {
                      Navigator.pop(context);
                      _signOut();
                    },
                  ),
                ],
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Your Decks'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewDeckPack,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadDeckPacks,
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Content
          Expanded(
            child: _deckPacks.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _deckPacks.length,
                    itemBuilder: (context, index) {
                      final deckPack = _deckPacks[index];
                      return _buildDeckPackCard(deckPack);
                    },
                  ),
          ),

          // Swipe hint at bottom
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Swipe left to edit or delete a deck',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No deck packs yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first deck pack to organize your decks',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewDeckPack,
              icon: const Icon(Icons.add),
              label: const Text('Create Deck Pack'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckPackCard(DeckPack deckPack) {
    // Get first two letters of the deck pack name for avatar
    String initials = deckPack.name.length >= 2
        ? deckPack.name.substring(0, 2).toUpperCase()
        : deckPack.name.substring(0, 1).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(
                    int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}'),
                  ).withOpacity(0.85),
                  Color(int.parse('0xFF${deckPack.coverColor ?? '1E88E5'}')),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
                BoxShadow(
                  // soft outer glow
                  color: Color(
                    int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}'),
                  ).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),

        title: Text(
          deckPack.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          deckPack.description.isNotEmpty
              ? deckPack.description
              : '${deckPack.deckCount} ${deckPack.deckCount == 1 ? 'deck' : 'decks'}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onPressed: () => _showDeckPackOptions(deckPack),
        ),
        onTap: () => _openDeckPack(deckPack),
      ),
    );
  }

  void _openDeckPack(DeckPack deckPack) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeckPackDetailScreen(deckPack: deckPack),
      ),
    ).then((_) => _loadDeckPacks());
  }
}
