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
import 'flashcard_home_screen.dart';
import '../../stats/stats_page.dart';
import 'notification_settings_screen.dart';
import '../widgets/notification_widget.dart';
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
  bool _isDarkMode = false;

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

      // Skip cloud load here; restore happens only after sign-in/fresh install

      _isGuestMode = await _dataService.isGuestMode();
      _isDarkMode = AdaptiveThemeService.isDarkMode(context);
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
    context.pushScale(
      CreateDeckPackScreen(
        onDeckPackCreated: (deckPack) {
          setState(() {
            _deckPacks.add(deckPack);
            _decksInPacks[deckPack.id] = [];
            _expandedPacks[deckPack.id] = false;
          });
        },
      ),
    );
  }

  void _createNewDeck(DeckPack deckPack) {
    context.pushScale(
      CreateDeckScreen(
        onDeckCreated: (deck) async {
          try {
            await _dataService.addDeckToPack(deck.id, deckPack.id);
            await _loadAllDecks();
          } catch (e) {
            if (mounted) {
              SnackbarUtils.showErrorSnackbar(
                context,
                'Error adding deck to pack: ${e.toString()}',
              );
            }
          }
        },
      ),
    );
  }

  void _togglePackExpansion(String packId) {
    setState(() {
      // If the pack is already expanded, collapse it
      if (_expandedPacks[packId] == true) {
        _expandedPacks[packId] = false;
      } else {
        // Collapse all other packs first, then expand the selected one
        _expandedPacks.forEach((key, value) {
          _expandedPacks[key] = false;
        });
        _expandedPacks[packId] = true;
      }
    });
  }

  void _openDeck(Deck deck) {
    context.pushSharedAxis(
      DeckDetailScreen(deck: deck),
    ).then((_) => _loadAllDecks());
  }

  Future<void> _confirmDeleteDeck(Deck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text('Are you sure you want to delete "${deck.name}" and all its flashcards?'),
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
        // Delete deck locally (and its flashcards via service)
        await _dataService.deleteDeck(deck.id);
        await _loadDeckPacks();
        await _loadAllDecks();

        if (mounted) {
          SnackbarUtils.showWarningSnackbar(
            context,
            'Deck "${deck.name}" deleted',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            'Error deleting deck: ${e.toString()}',
          );
        }
      }
    }
  }

  // Removed stale _removeDeckFromPack in favor of delete flow

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

        // After sign-in, pull cloud data and refresh lists
        try {
          await _dataService.initialize();
          await _dataService.loadDataFromFirestore();
          await _loadDeckPacks();
          await _loadAllDecks();
        } catch (e) {}

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
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.school, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Burbly Flashcard'),
        ],
      ),
      content: const Text(
        'Version 1.0.0\n\n'
        'A smart flashcard app that works offline and syncs your data when you sign in.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

  void _showPetManagement() {
    context.pushSlide(
      const PetManagementScreen(),
    );
  }

  // Method to refresh the notification widget by rebuilding the screen
  void _refreshNotificationWidget() {
    setState(() {
      // This will rebuild the screen and refresh the notification widget
    });
  }

Widget _buildDrawer() {
  final user = FirebaseAuth.instance.currentUser;

  return Drawer(
    width: MediaQuery.of(context).size.width * 0.75, // 75% of screen width
    child: SafeArea(
      child: Column(
        children: [
          // --- Header ---
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            margin: EdgeInsets.zero,
            currentAccountPicture: CircleAvatar(
              radius: 36,
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
            accountName: Text(
              _isGuestMode ? 'Guest User' : (user?.displayName ?? 'User'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              _isGuestMode ? 'Offline mode' : (user?.email ?? ''),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // --- Drawer items ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    "Study",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: const Icon(Icons.home_outlined, size: 22, color: Colors.blue),
                  title:
                      const Text('Deck Packs', style: TextStyle(fontSize: 14)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: const Icon(Icons.school_outlined, size: 22, color: Colors.green),
                  title: const Text('My Decks', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushFade(
                      const FlashcardHomeScreen(),
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: const Icon(Icons.note_outlined, size: 22, color: Colors.orange),
                  title: const Text('Notes', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushFade(
                      const NotesScreen(),
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: const Icon(Icons.analytics_outlined, size: 22, color: Colors.purple),
                  title:
                      const Text('Statistics', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushFade(
                      StatsPage(),
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading:
                      const Icon(Icons.notifications_outlined, size: 22, color: Colors.red),
                  title:
                      const Text('Notifications', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushFade(
                      const NotificationSettingsScreen(),
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: Icon(
                      _isDarkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 22,
                      color: _isDarkMode ? Colors.yellow[700] : Colors.black),
                  title: Text(_isDarkMode ? 'Light Mode' : 'Dark Mode',
                      style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                      AdaptiveThemeService.toggleTheme(context);
                    });
                  },
                ),
                ListTile(
  dense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  leading: const Icon(Icons.pets_outlined, size: 22, color: Colors.teal),
  title: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        'Pet Management',
        style: TextStyle(fontSize: 14),
      ),
      const SizedBox(width: 6), // spacing between text and badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Testing',
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  ),
  onTap: () {
    Navigator.pop(context);
    _showPetManagement();
  },
),

                const Divider(height: 1, thickness: 0.5),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    "Account",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey),
                  ),
                ),

                if (_isGuestMode)
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading:
                        const Icon(Icons.cloud_sync_outlined, size: 22, color: Colors.blueAccent),
                    title: const Text('Sign in with Google',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Sync your data',
                        style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(context);
                      _signInWithGoogle();
                    },
                  )
                else ...[
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: const Icon(Icons.backup_outlined, size: 22, color: Colors.indigo),
                    title: const Text('Backup to Cloud',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Sync your data',
                        style: TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(context);
                      _backupToCloud();
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: const Icon(Icons.logout, size: 22, color: Colors.redAccent),
                    title: const Text('Sign out', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      _signOut();
                    },
                  ),
                ],

                const Divider(height: 1, thickness: 0.5),

                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: const Icon(Icons.info_outline, size: 22, color: Colors.grey),
                  title:
                      const Text('About', style: TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog();
                  },
                ),
              ],
            ),
          ),

          // --- Footer ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "v1.0.0",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deck Packs'),
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
          // Search button
          IconButton(
            onPressed: () {
              context.pushSlide(
                const SearchScreen(),
              );
            },
            icon: Icon(Icons.search, color: Theme.of(context).appBarTheme.foregroundColor),
            tooltip: 'Search',
          ),
          
          // Notification settings button
          IconButton(
            onPressed: () {
              context.pushFade(
                const NotificationSettingsScreen(),
              );
            },
            icon: Icon(Icons.notifications, color: Theme.of(context).appBarTheme.foregroundColor),
            tooltip: 'Notification Settings',
          ),
          // Theme toggle button
          IconButton(
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
                AdaptiveThemeService.toggleTheme(context);
              });
            },
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            tooltip: _isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, -30), // move up by 20px
        child: FloatingActionButton.extended(
          onPressed: _createNewDeckPack,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('New Pack'),
          elevation: 5,
        ),
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
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
    color: Theme.of(context).colorScheme.onBackground, // automatically adapts
  ),
),

                            const Spacer(),
                            Text(
                              '${_allDecks.length} total decks',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            child:             Text(
              'Tap to expand deck packs and view decks',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.grey[600],
              ),
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
    // Get initials from deck pack name
List<String> words = deckPack.name.trim().split(RegExp(r'\s+'));

String initials;
if (words.length >= 2) {
  // Take first character of first two words
  initials = (words[0][0] + words[1][0]).toUpperCase();
} else {
  // Fall back to first one or two letters of single word
  initials = deckPack.name.substring(0, deckPack.name.length >= 2 ? 2 : 1).toUpperCase();
}


    final decks = _decksInPacks[deckPack.id] ?? [];
    final expanded = _expandedPacks[deckPack.id] ?? false;
    final packColor = Color(int.parse('0xFF${deckPack.coverColor}'));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3)
                : packColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: packColor.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
        ],
        border: Border.all(
          color: expanded 
              ? packColor.withOpacity(0.4)
              : Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[700]!
                  : packColor.withOpacity(0.15),
          width: expanded ? 2.5 : 1.5,
        ),
      ),
      child: Column(
        children: [
          // Deck Pack Header
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.light
                    ? [
                        packColor.withOpacity(0.12),
                        packColor.withOpacity(0.06),
                        packColor.withOpacity(0.02),
                      ]
                    : [
                        packColor.withOpacity(0.1),
                        packColor.withOpacity(0.05),
                      ],
                stops: Theme.of(context).brightness == Brightness.light
                    ? [0.0, 0.6, 1.0]
                    : null,
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
                      packColor,
                      packColor.darken(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: packColor.withOpacity(0.3),
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (deckPack.description.isNotEmpty) ...[
                    Text(
                      deckPack.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
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
                        color: packColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${decks.length} ${decks.length == 1 ? 'deck' : 'decks'}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: packColor,
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
                          ? (Theme.of(context).colorScheme.primary).withOpacity(0.1)
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: expanded
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).iconTheme.color,
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
          
          // Expanded content with animation and hierarchical indentation
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: expanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(40, 20, 20, 20), // Increased left padding for hierarchy
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? packColor.withOpacity(0.04)
                          : packColor.withOpacity(0.02),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: packColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildDeckPackDetails(deckPack),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

 Widget _buildDeckPackDetails(DeckPack deckPack) {
  final decks = _decksInPacks[deckPack.id] ?? [];
  final Color baseColor = Color(int.parse('0xFF${deckPack.coverColor}'));

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (decks.isNotEmpty) ...[
        // Section Header
        

        // Decks List with subtle dividers for better hierarchy
        Column(
          children: decks.asMap().entries.map((entry) {
            final index = entry.key;
            final deck = entry.value;
            return Column(
              children: [
                _buildDeckCard(deck, deckPack),
                if (index < decks.length - 1)
                  Divider(
                    color: baseColor.withOpacity(0.1),
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],

      // Add New Deck Button
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.light
                ? [
                    baseColor.withOpacity(0.15),
                    baseColor.withOpacity(0.08),
                    baseColor.withOpacity(0.03),
                  ]
                : [
                    baseColor.withOpacity(0.1),
                    baseColor.withOpacity(0.05),
                  ],
            stops: Theme.of(context).brightness == Brightness.light
                ? [0.0, 0.7, 1.0]
                : null,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: baseColor.withOpacity(0.25),
            style: BorderStyle.solid,
            width: 1.5,
          ),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : null,
          boxShadow: [
            if (Theme.of(context).brightness == Brightness.light)
              BoxShadow(
                color: baseColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
          ],
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
                    color: baseColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Deck',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: baseColor,
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
    final deckColor = Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}'));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.2)
                : deckColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          if (Theme.of(context).brightness == Brightness.light)
            BoxShadow(
              color: deckColor.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[700]!
              : deckColor.withOpacity(0.2),
          width: 1.5,
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
                // Deck Icon with Hero Animation
                HeroWrapper(
                  tag: 'deck_icon_${deck.id}',
                  child: Container(
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
                ),
                
                const SizedBox(width: 16),
                
                // Deck Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (deck.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          deck.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
  children: [
    Icon(Icons.style, size: 14, color: Colors.grey[500]),
    const SizedBox(width: 4),
    Flexible(
      child: Text(
        '${deck.cardCount} ${deck.cardCount == 1 ? 'card' : 'cards'}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey[600],
            ),
        overflow: TextOverflow.ellipsis, // important to prevent overflow
      ),
    ),
    const SizedBox(width: 12),
    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
    const SizedBox(width: 4),
    Flexible(
      child: Text(
        _formatDate(deck.updatedAt),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey[500],
            ),
        overflow: TextOverflow.ellipsis,
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
                      onTap: () => _confirmDeleteDeck(deck),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.withOpacity(0.2)
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
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

extension ColorExtension on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}