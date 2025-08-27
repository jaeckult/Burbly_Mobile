// import 'package:burblyflashcard/features/pets/screens/pet_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/auth_service.dart';
import '../../../core/core.dart';
import '../../../core/services/adaptive_theme_service.dart';
import 'create_deck_screen.dart';
import 'deck_detail_screen.dart';
// import 'search_screen.dart';
import '../../../core/services/background_service.dart';
import 'deck_pack_list_screen.dart';
import 'notes_screen.dart';
import 'notification_settings_screen.dart';
import '../../stats/stats_page.dart';
// import '../../../core/services/pet_notification_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'trash_screen.dart';

class FlashcardHomeScreen extends StatefulWidget {
  const FlashcardHomeScreen({super.key});

  @override
  State<FlashcardHomeScreen> createState() => _FlashcardHomeScreenState();
}

class _FlashcardHomeScreenState extends State<FlashcardHomeScreen> {
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  // final PetNotificationService _petNotificationService = PetNotificationService();
  List<Deck> _decks = [];
  bool _isLoading = true;
  bool _isGuestMode = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // _registerPetNotifications();
  }

  @override
  void dispose() {
    // _petNotificationService.unregisterCallback();
    super.dispose();
  }

  // void _registerPetNotifications() {
  //   _petNotificationService.registerCallback((message, type) {
  //     if (mounted) {
  //       switch (type) {
  //         case 'success':
  //           SnackbarUtils.showSuccessSnackbar(context, message);
  //           break;
  //         case 'warning':
  //           SnackbarUtils.showWarningSnackbar(context, message);
  //           break;
  //         case 'error':
  //           SnackbarUtils.showErrorSnackbar(context, message);
  //           break;
  //         case 'info':
  //           SnackbarUtils.showInfoSnackbar(context, message);
  //           break;
  //       }
  //     }
  //   });
  // }

  Future<void> _initializeData() async {
    try {
      if (!_dataService.isInitialized) {
        await _dataService.initialize();
      }
      _isGuestMode = await _dataService.isGuestMode();
      _isDarkMode = AdaptiveThemeService.isDarkMode(context);
      await _loadDecks();
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDecks() async {
    final decks = await _dataService.getDecks();
    setState(() => _decks = decks);
  }

  Future<void> _signInWithGoogle() async {
    try {
      final result = await _authService.signInWithGoogle(forceAccountSelection: true);
      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isGuestMode', false);
        setState(() => _isGuestMode = false);
        try {
          await _dataService.initialize();
          await _dataService.clearAllLocalData();
          await BackgroundService().resetStudyStreak();
          await _loadDecks();
        } catch (_) {}
        if (mounted) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Successfully signed in! Use the backup button to sync your data.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Sign-in failed: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _backupToCloud() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
          insetPadding: EdgeInsets.all(40),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Backing up your data...'),
              ],
            ),
          ),
        ),
      );
      await _dataService.backupToFirestore();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        SnackbarUtils.showSuccessSnackbar(
                    context,
                    'Backup completed successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        SnackbarUtils.showErrorSnackbar(
          context,
          'Backup failed: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOutGoogle();
      try {
        await _dataService.initialize();
        await _dataService.clearAllLocalData();
        await BackgroundService().resetStudyStreak();
        await _loadDecks();
      } catch (_) {}
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuestMode', true);
      setState(() => _isGuestMode = true);
      if (mounted) {
        SnackbarUtils.showInfoSnackbar(
          context,
          'Signed out successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Sign-out failed: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('My Decks', style: TextStyle(fontWeight: FontWeight.w600)),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => Navigator.pop(context),
  ),
  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
  foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
  elevation: 0,
),
drawer: _buildDrawer(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : _buildBody(),
      floatingActionButton: _decks.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showActionOptions,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: SafeArea(
        child: Column(
          children: [
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

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      "Study",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: const Icon(Icons.home_outlined, size: 22, color: Colors.blue),
                    title: const Text('Deck Packs', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      NavigationHelper.pushAndClearStack(
                        context,
                        const DeckPackListScreen(),
                        transitionType: MaterialMotionTransitionType.fadeThrough,
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: const Icon(Icons.school_outlined, size: 22, color: Colors.green),
                    title: const Text('My Decks', style: TextStyle(fontSize: 14)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: const Icon(Icons.analytics_outlined, size: 22, color: Colors.purple),
                    title: const Text('Statistics', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      context.pushFade(
                        StatsPage(),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: const Icon(Icons.notifications_outlined, size: 22, color: Colors.red),
                    title: const Text('Notifications', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      context.pushFade(
                        const NotificationSettingsScreen(),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: Icon(
                      _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      size: 22,
                      color: _isDarkMode ? Colors.yellow[700] : Colors.black,
                    ),
                    title: Text(_isDarkMode ? 'Light Mode' : 'Dark Mode', style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                        AdaptiveThemeService.toggleTheme(context);
                      });
                    },
                  ),
                  // ListTile(
                  //   dense: true,
                  //   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  //   leading: const Icon(Icons.pets_outlined, size: 22, color: Colors.teal),
                  //   title: Row(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       const Text('Pet Management', style: TextStyle(fontSize: 14)),
                  //       const SizedBox(width: 6),
                  //       Container(
                  //         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  //         decoration: BoxDecoration(
                  //           color: Colors.orange.shade600,
                  //           borderRadius: BorderRadius.circular(8),
                  //         ),
                  //         child: const Text(
                  //           'Testing',
                  //           style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     context.pushSlide(
                  //       const PetManagementScreen(),
                  //     );
                  //   },
                  // ),
                  // const Divider(height: 1, thickness: 0.5),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      "Account",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                  ),
                  if (_isGuestMode)
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      leading: const Icon(Icons.cloud_sync_outlined, size: 22, color: Colors.blueAccent),
                      title: const Text('Sign in with Google', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Sync your data', style: TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        _signInWithGoogle();
                      },
                    )
                  else ...[
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      leading: const Icon(Icons.backup_outlined, size: 22, color: Colors.indigo),
                      title: const Text('Backup to Cloud', style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Sync your data', style: TextStyle(fontSize: 12)),
                      onTap: () {
                        Navigator.pop(context);
                        _backupToCloud();
                      },
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: const Icon(Icons.info_outline, size: 22, color: Colors.grey),
                    title: const Text('About', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    leading: const Icon(Icons.delete_outline, size: 22, color: Colors.brown),
                    title: const Text('Trash', style: TextStyle(fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      context.pushFade(
                        const TrashScreen(),
                      );
                    },
                  ),
                ],
              ),
            ),
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

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          child: _decks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDecks,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _decks.length,
                    itemBuilder: (context, index) {
                      final deck = _decks[index];
                      return _buildDeckCard(deck);
                    },
                  ),
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
            Icons.school_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No decks yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first deck to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewDeck,
            icon: const Icon(Icons.add),
            label: const Text('Create Deck'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckCard(Deck deck) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openDeck(deck),
        onLongPress: () => _showDeckOptions(deck),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}')),
                Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}')).withOpacity(0.7),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        deck.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showDeckOptions(deck),
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    deck.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                if (deck.packId != null)
                  FutureBuilder<String?>(
                    future: _dataService.getDeckPackName(deck.packId!),
                    builder: (context, snapshot) {
                      String displayText;
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        displayText = 'Loading...';
                      } else if (snapshot.hasError) {
                        displayText = 'Error';
                        if (mounted) {
                          SnackbarUtils.showErrorSnackbar(context, 'Failed to load pack name: ${snapshot.error}');
                        }
                      } else {
                        displayText = snapshot.data ?? 'Unknown Pack';
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${deck.cardCount} cards',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDate(deck.updatedAt),
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _createNewDeck() {
    context.pushScale(
      CreateDeckScreen(
        onDeckCreated: (deck) {
          setState(() => _decks.add(deck));
        },
      ),
    );
  }

  void _openDeck(Deck deck) {
    context.pushSharedAxis(
      DeckDetailScreen(deck: deck),
    ).then((_) => _loadDecks());
  }

  void _showDeckOptions(Deck deck) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Deck'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit deck
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text('Delete Deck', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _deleteDeck(deck);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDeck(Deck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text('Are you sure you want to delete "${deck.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.deleteDeck(deck.id);
      setState(() => _decks.removeWhere((d) => d.id == deck.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck "${deck.name}" moved to Trash'),
            backgroundColor: Colors.orange,
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
        ' smart flashcard app that works offline and syncs your data when you sign in.',
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

  void _showActionOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.school, color: Colors.blue),
              title: const Text('Create New Deck'),
              onTap: () {
                Navigator.pop(context);
                _createNewDeck();
              },
            ),
          ],
        ),
      ),
    );
  }
}