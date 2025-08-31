import 'package:flutter/material.dart';
import '../../../core/models/notification.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../screens/deck_detail_screen.dart';

class NotificationDisplayWidget extends StatefulWidget {
  const NotificationDisplayWidget({super.key});

  @override
  State<NotificationDisplayWidget> createState() => _NotificationDisplayWidgetState();
}

class _NotificationDisplayWidgetState extends State<NotificationDisplayWidget> {
  final NotificationService _notificationService = NotificationService();
  final DataService _dataService = DataService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupPeriodicRefresh() {
    // Refresh every 30 seconds to check for new notifications
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotifications();
      }
    });
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final notifications = await _notificationService.getNotifications();
      
      // Add a test notification if no notifications exist (for testing)
      if (notifications.isEmpty) {
        print('No notifications found, adding test notification');
        await _notificationService.saveNotification(
          title: 'Test Notification',
          message: 'This is a test notification to verify the system is working',
          type: NotificationType.general,
        );
        // Reload notifications after adding test
        final updatedNotifications = await _notificationService.getNotifications();
        if (mounted) {
          setState(() {
            _notifications = updatedNotifications;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _notifications = notifications;
            _isLoading = false;
          });
        }
      }
      
      print('Loaded ${_notifications.length} notifications, unread: $_unreadCount');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading notifications: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllNotificationsAsRead();
      await _loadNotifications();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      await _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      await _loadNotifications();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    print('Building NotificationDisplayWidget - notifications: ${_notifications.length}, unread: $_unreadCount, loading: $_isLoading');
    
    return IconButton(
      onPressed: () {
        print('Notification icon pressed!');
        _showNotificationDialog(context);
      },
      icon: Stack(
        children: [
          Icon(
            Icons.notifications,
            color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
            size: 24,
          ),
          if (_unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Notifications',
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? const Text('No notifications')
                : SizedBox(
                    width: 300,
                    height: 400,
                    child: ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return ListTile(
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead 
                                  ? FontWeight.normal 
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(notification.message),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _deleteNotification(notification.id);
                                  Navigator.pop(context);
                                  _showNotificationDialog(context);
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            _markAsRead(notification.id);
                            Navigator.pop(context);
                            _handleNotificationTap(notification);
                          },
                        );
                      },
                    ),
                  ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () {
                _markAllAsRead();
                Navigator.pop(context);
              },
              child: Text('Mark all as read ($_unreadCount)'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }



  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(AppNotification notification) async {
    // Handle different notification types
    switch (notification.type) {
      case NotificationType.studyReminder:
        // Check if it's a deck-specific notification
        if (notification.data?['deckId'] != null) {
          final deckId = notification.data!['deckId'];
          try {
            final deck = await _dataService.getDeck(deckId);
            if (deck != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeckDetailScreen(deck: deck),
                ),
              );
              return;
            }
          } catch (e) {
            print('Error navigating to deck: $e');
          }
        }
        // Fallback to mixed study screen
        Navigator.pushNamed(context, '/flashcards');
        break;
      case NotificationType.overdueCards:
        // Check if it's a deck-specific notification
        if (notification.data?['deckId'] != null) {
          final deckId = notification.data!['deckId'];
          try {
            final deck = await _dataService.getDeck(deckId);
            if (deck != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeckDetailScreen(deck: deck),
                ),
              );
              return;
            }
          } catch (e) {
            print('Error navigating to deck: $e');
          }
        }
        // Fallback to mixed study screen
        Navigator.pushNamed(context, '/flashcards');
        break;
      case NotificationType.dailyReminder:
        // Navigate to deck packs
        Navigator.pushNamed(context, '/deck-packs');
        break;
      case NotificationType.streakAchievement:
        // Navigate to stats
        Navigator.pushNamed(context, '/stats');
        break;
      case NotificationType.general:
        // For general notifications, check if it's a pet notification
        if (notification.data?['source'] == 'pet') {
          // Could navigate to pet management screen if available
          // For now, just stay on current screen
        }
        break;
      default:
        // No specific action
        break;
    }
  }
}
