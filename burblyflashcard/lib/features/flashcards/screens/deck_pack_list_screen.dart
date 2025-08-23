import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/auth_service.dart';
import '../../../core/core.dart';
import '../../../core/services/adaptive_theme_service.dart';
import 'create_deck_pack_screen.dart';
import 'deck_detail_screen.dart';
import 'create_deck_screen.dart';
import 'notes_screen.dart';
import 'search_screen.dart';
import '../../stats/stats_page.dart';
import 'notification_settings_screen.dart';
import '../widgets/notification_widget.dart';
import '../../pets/widgets/pet_companion_widget.dart';
import '../../pets/screens/pet_management_screen.dart';

class DeckPackListScreen extends StatefulWidget {
  const DeckPackListScreen({super.key});

  @override
  State<DeckPackListScreen> createState() => _DeckPackListScreenState();
}

class _DeckPackListScreenState extends State<DeckPackListScreen> {
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  List<DeckPack> _deckPacks = [];
  List<Deck> _allDecks = [];
  Map<String, List<Deck>> _decksInPacks = {};
  Map<String, bool> _expandedPacks = {};
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
      await _loadAllDecks();
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

  Future<void> _loadAllDecks() async {
    try {
      final allDecks = await _dataService.getDecks();
      setState(() => _allDecks = allDecks);
      
      // Organize decks by pack
      final decksInPacks = <String, List<Deck>>{};
      for (final deckPack in _deckPacks) {
        decksInPacks[deckPack.id] = allDecks.where((deck) => deck.packId == deckPack.id).toList();
      }
      setState(() => _decksInPacks = decksInPacks);
    } catch (e) {
      print('Error loading decks: $e');
    }
  }

  void _createNewDeckPack() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDeckPackScreen(
          onDeckPackCreated: (deckPack) {
            setState(() {
              _deckPacks.add(deckPack);
              _decksInPacks[deckPack.id] = [];
              _expandedPacks[deckPack.id] = false;
            });
          },
        ),
      ),
    );
  }

  void _createNewDeck(DeckPack deckPack) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDeckScreen(
          onDeckCreated: (deck) async {
            try {
              await _dataService.addDeckToPack(deck.id, deckPack.id);
              await _loadAllDecks();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding deck to pack: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _togglePackExpansion(String packId) {
    setState(() {
      _expandedPacks[packId] = !(_expandedPacks[packId] ?? false);
    });
  }

  void _openDeck(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeckDetailScreen(deck: deck),
      ),
    ).then((_) => _loadAllDecks());
  }

  void _removeDeckFromPack(Deck deck, DeckPack deckPack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Deck from Pack'),
        content: Text('Are you sure you want to remove "${deck.name}" from this pack?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dataService.removeDeckFromPack(deck.id, deckPack.id);
        await _loadAllDecks();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deck "${deck.name}" removed from pack'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing deck: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
              leading: const Icon(Icons.add),
              title: const Text('Add New Deck'),
              onTap: () {
                Navigator.pop(context);
                _createNewDeck(deckPack);
              },
            ),
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
        setState(() {
          _deckPacks.removeWhere((d) => d.id == deckPack.id);
          _decksInPacks.remove(deckPack.id);
          _expandedPacks.remove(deckPack.id);
        });

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

  void _showPetManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PetManagementScreen(),
      ),
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
                  onTap: () => Navigator.pop(context),
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
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notification Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(AdaptiveThemeService.isDarkMode(context) ? Icons.light_mode : Icons.dark_mode),
                  title: Text(AdaptiveThemeService.isDarkMode(context) ? 'Light Mode' : 'Dark Mode'),
                  onTap: () {
                    Navigator.pop(context);
                    AdaptiveThemeService.toggleTheme(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pets),
                  title: const Text('Pet Management'),
                  onTap: () {
                    Navigator.pop(context);
                    _showPetManagement();
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
      appBar: AppBar(
        title: const Text('Your Decks'),
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          // Notification settings button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
            icon: Icon(Icons.notifications, color: Theme.of(context).appBarTheme.foregroundColor),
            tooltip: 'Notification Settings',
          ),
          // Theme toggle button
          IconButton(
            onPressed: () {
              AdaptiveThemeService.toggleTheme(context);
            },
            icon: Icon(
              AdaptiveThemeService.isDarkMode(context) ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            tooltip: AdaptiveThemeService.isDarkMode(context) ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewDeckPack,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Pack'),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDeckPacks();
        await _loadAllDecks();
      },
      child: Column(
        children: [
          
          
          // Notification widget
          const NotificationWidget(),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(
                    color: Theme.of(context).hintColor,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search, 
                    color: Theme.of(context).hintColor,
                  ),
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
                : Column(
                    children: [
                      // Header with total count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_deckPacks.length} ${_deckPacks.length == 1 ? 'Deck Pack' : 'Deck Packs'}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_allDecks.length} total decks',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Deck Packs List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _deckPacks.length,
                          itemBuilder: (context, index) {
                            final deckPack = _deckPacks[index];
                            return _buildDeckPackCard(deckPack);
                          },
                        ),
                      ),
                    ],
                  ),
          ),

          // Swipe hint at bottom
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Tap to expand deck packs and view decks',
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

    final decks = _decksInPacks[deckPack.id] ?? [];
    final expanded = _expandedPacks[deckPack.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: expanded 
              ? Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.3)
              : Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
          width: expanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Deck Pack Header
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.1),
                  Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.05),
                ],
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')),
                      Color(int.parse('0xFF${deckPack.coverColor ?? '1E88E5'}')),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              title: Text(
                deckPack.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (deckPack.description.isNotEmpty) ...[
                    Text(
                      deckPack.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.folder,
                        size: 16,
                        color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${decks.length} ${decks.length == 1 ? 'deck' : 'decks'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: expanded 
                          ? Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: expanded 
                          ? Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}'))
                          : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onPressed: () => _showDeckPackOptions(deckPack),
                  ),
                ],
              ),
              onTap: () => _togglePackExpansion(deckPack.id),
            ),
          ),
          
          // Expanded content showing decks
          if (expanded) ...[
            Container(
              padding: const EdgeInsets.all(20),
              child: _buildDeckPackDetails(deckPack),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeckPackDetails(DeckPack deckPack) {
    final decks = _decksInPacks[deckPack.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (decks.isNotEmpty) ...[
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  size: 20,
                  color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')),
                ),
                const SizedBox(width: 8),
                Text(
                  'Decks in this pack (${decks.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')),
                  ),
                ),
              ],
            ),
          ),
          
          // Decks List
          ...decks.map((deck) => _buildDeckCard(deck, deckPack)).toList(),
          const SizedBox(height: 16),
        ],
        
        // Add New Deck Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.1),
                Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')).withOpacity(0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _createNewDeck(deckPack),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Deck',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(int.parse('0xFF${deckPack.coverColor ?? '42A5F5'}')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckCard(Deck deck, DeckPack deckPack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[700]!
              : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDeck(deck),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Deck Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}')),
                        Color(int.parse('0xFF${deck.coverColor ?? '1976D2'}')),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}')).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Deck Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      if (deck.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          deck.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.style,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${deck.cardCount} ${deck.cardCount == 1 ? 'card' : 'cards'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(deck.updatedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _removeDeckFromPack(deck, deckPack),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red[400],
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
