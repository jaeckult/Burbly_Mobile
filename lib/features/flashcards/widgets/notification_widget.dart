// import 'package:flutter/material.dart';
// import '../../../core/services/notification_service.dart';
// import '../../../core/core.dart';
// import '../../../core/models/flashcard.dart';
// import '../screens/mixed_study_screen.dart';
// import '../screens/notification_settings_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async';

// class NotificationWidget extends StatefulWidget {
//   const NotificationWidget({super.key});

//   @override
//   State<NotificationWidget> createState() => _NotificationWidgetState();
// }

// class _NotificationWidgetState extends State<NotificationWidget> with WidgetsBindingObserver {
//   final NotificationService _notificationService = NotificationService();
//   final DataService _dataService = DataService();
//   List<Flashcard> _overdueCards = [];
//   List<Flashcard> _cardsDueToday = [];
//   bool _isLoading = true;
//   Timer? _refreshTimer;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _loadNotificationData();
//     _setupPeriodicRefresh();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _refreshTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     // Refresh when app becomes active (user returns to app)
//     if (state == AppLifecycleState.resumed) {
//       _loadNotificationData();
//     }
//   }

//   void _setupPeriodicRefresh() {
//     // Refresh every 5 minutes to check for new due cards
//     _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
//       if (mounted) {
//         _loadNotificationData();
//       }
//     });
//   }

//   Future<void> _startAutomaticStudy() async {
//     try {
//       // Dismiss widget for 4 hours
//       final prefs = await SharedPreferences.getInstance();
//       final now = DateTime.now();
//       final dismissUntil = now.add(const Duration(hours: 4));
//       await prefs.setString('notification_widget_dismissed_until', dismissUntil.toIso8601String());
      
//       if (mounted) {
//         setState(() {
//           _overdueCards = [];
//           _cardsDueToday = [];
//         });
//       }

//       // Navigate to Mixed Study Screen
//       if (!mounted) return;
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const MixedStudyScreen(),
//         ),
//       );
//     } catch (e) {
//       // Fallback navigation
//       if (!mounted) return;
//       Navigator.pushNamed(context, '/flashcards');
//     }
//   }

//   Future<void> _loadNotificationData() async {
//     if (!mounted) return;
    
//     setState(() => _isLoading = true);
    
//     try {
//       // Check if widget is dismissed until a specific time
//       final prefs = await SharedPreferences.getInstance();
//       final dismissedUntilString = prefs.getString('notification_widget_dismissed_until');
      
//       if (dismissedUntilString != null) {
//         try {
//           final dismissedUntil = DateTime.parse(dismissedUntilString);
//           final now = DateTime.now();
          
//           // If still within dismissal period, don't show widget
//           if (now.isBefore(dismissedUntil)) {
//             if (mounted) {
//               setState(() {
//                 _overdueCards = [];
//                 _cardsDueToday = [];
//                 _isLoading = false;
//               });
//             }
//             return;
//           } else {
//             // Clear expired dismissal
//             await prefs.remove('notification_widget_dismissed_until');
//           }
//         } catch (e) {
//           // If parsing fails, clear the invalid dismissal
//           await prefs.remove('notification_widget_dismissed_until');
//         }
//       }
      
//       final overdueCards = await _notificationService.getOverdueCards();
//       final cardsDueToday = await _notificationService.getCardsDueToday();
      
//       // Show notification if there are cards to review
//       if (overdueCards.isNotEmpty || cardsDueToday.isNotEmpty) {
//         await _showStudyReminderNotification(overdueCards.length, cardsDueToday.length);
//       }
      
//       if (mounted) {
//         setState(() {
//           _overdueCards = overdueCards;
//           _cardsDueToday = cardsDueToday;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//       print('Error loading notification data: $e');
//     }
//   }

//   Future<void> _showStudyReminderNotification(int overdueCount, int dueTodayCount) async {
//     try {
//       // Check if we should show notification (avoid spam)
//       final prefs = await SharedPreferences.getInstance();
//       final lastNotificationTime = prefs.getString('last_study_reminder_notification');
      
//       if (lastNotificationTime != null) {
//         final lastTime = DateTime.parse(lastNotificationTime);
//         final now = DateTime.now();
//         // Only show notification if it's been at least 2 hours since last one
//         if (now.difference(lastTime) < const Duration(hours: 2)) {
//           return;
//         }
//       }

//       String title;
//       String body;
      
//       if (overdueCount > 0) {
//         title = 'Cards Need Review! ⚠️';
//         body = '$overdueCount cards are overdue for review. Time to catch up!';
//       } else if (dueTodayCount > 0) {
//         title = 'Study Reminder 📚';
//         body = '$dueTodayCount cards are due for review today.';
//       } else {
//         return; // No cards to review
//       }

//       // Show the notification
//       await _notificationService.showStudyReminderNotification(title, body);
      
//       // Save the notification time
//       await prefs.setString('last_study_reminder_notification', DateTime.now().toIso8601String());
//     } catch (e) {
//       print('Error showing study reminder notification: $e');
//     }
//   }

//   // Method to manually refresh the widget (can be called from parent)
//   Future<void> refreshWidget() async {
//     await _loadNotificationData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         child: Card(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Center(
//               child: SizedBox(
//                 width: 20,
//                 height: 20,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     Theme.of(context).primaryColor,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final hasOverdueCards = _overdueCards.isNotEmpty;
//     final hasCardsDueToday = _cardsDueToday.isNotEmpty;

//     if (!hasOverdueCards && !hasCardsDueToday) {
//       return const SizedBox.shrink();
//     }

//     final totalCards = _overdueCards.length + _cardsDueToday.length;
//     final isUrgent = hasOverdueCards;

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//           side: BorderSide(
//             color: isUrgent 
//                 ? Colors.orange.withOpacity(0.3)
//                 : Colors.blue.withOpacity(0.2),
//             width: 1.5,
//           ),
//         ),
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: isUrgent
//                   ? [
//                       Colors.orange.withOpacity(0.05),
//                       Colors.red.withOpacity(0.02),
//                     ]
//                   : [
//                       Colors.blue.withOpacity(0.05),
//                       Colors.indigo.withOpacity(0.02),
//                     ],
//             ),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: isUrgent 
//                             ? Colors.orange.withOpacity(0.1)
//                             : Colors.blue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Icon(
//                         isUrgent ? Icons.warning_rounded : Icons.notifications_active_rounded,
//                         color: isUrgent ? Colors.orange[700] : Colors.blue[700],
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             isUrgent ? 'Cards Need Review!' : 'Study Reminder',
//                             style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                               fontWeight: FontWeight.w600,
//                               color: isUrgent ? Colors.orange[700] : Colors.blue[700],
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             '$totalCards ${totalCards == 1 ? 'card' : 'cards'} ready for review',
//                             style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const NotificationSettingsScreen(),
//                           ),
//                         );
//                       },
//                       icon: Icon(
//                         Icons.settings_outlined,
//                         color: Colors.grey[600],
//                         size: 20,
//                       ),
//                       tooltip: 'Notification Settings',
//                       style: IconButton.styleFrom(
//                         backgroundColor: Colors.grey.withOpacity(0.1),
//                         padding: const EdgeInsets.all(8),
//                       ),
//                     ),
//                   ],
//                 ),
                
//                 const SizedBox(height: 16),
                
//                 // Card counts
//                 if (hasOverdueCards) ...[
//                   _buildCountRow(
//                     icon: Icons.schedule_rounded,
//                     text: '${_overdueCards.length} overdue',
//                     color: Colors.orange,
//                   ),
//                   const SizedBox(height: 8),
//                 ],
//                 if (hasCardsDueToday) ...[
//                   _buildCountRow(
//                     icon: Icons.today_rounded,
//                     text: '${_cardsDueToday.length} due today',
//                     color: Colors.blue,
//                   ),
//                   const SizedBox(height: 8),
//                 ],
                
//                 const SizedBox(height: 16),
                
//                 // Action buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _startAutomaticStudy,
//                         icon: Icon(
//                           Icons.school_rounded,
//                           size: 18,
//                         ),
//                         label: Text(
//                           'Start Review',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                           ),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: isUrgent ? Colors.orange : Colors.blue,
//                           foregroundColor: Colors.white,
//                           elevation: 2,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: OutlinedButton(
//                         onPressed: () async {
//                           // Dismiss for 2 hours
//                           try {
//                             final prefs = await SharedPreferences.getInstance();
//                             final now = DateTime.now();
//                             final dismissUntil = now.add(const Duration(hours: 2));
//                             await prefs.setString('notification_widget_dismissed_until', dismissUntil.toIso8601String());
//                           } catch (_) {}
//                           if (!mounted) return;
//                           setState(() {
//                             _overdueCards = [];
//                             _cardsDueToday = [];
//                           });
//                         },
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           side: BorderSide(
//                             color: Colors.grey.withOpacity(0.3),
//                           ),
//                         ),
//                         child: Text(
//                           'Remind Later',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w500,
//                             fontSize: 14,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCountRow({
//     required IconData icon,
//     required String text,
//     required Color color,
//   }) {
//     return Row(
//       children: [
//         Icon(
//           icon,
//           color: color,
//           size: 16,
//         ),
//         const SizedBox(width: 8),
//         Text(
//           text,
//           style: TextStyle(
//             color: color,
//             fontWeight: FontWeight.w500,
//             fontSize: 13,
//           ),
//         ),
//       ],
//     );
//   }
// }
