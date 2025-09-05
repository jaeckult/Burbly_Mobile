import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';
import 'profile_avatar.dart';

class ProfileDemoScreen extends StatefulWidget {
  const ProfileDemoScreen({super.key});

  @override
  State<ProfileDemoScreen> createState() => _ProfileDemoScreenState();
}

class _ProfileDemoScreenState extends State<ProfileDemoScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  String? _storedProfilePicture;
  String? _storedProfileName;
  String? _storedProfileEmail;
  String? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadStoredProfileData();
  }

  Future<void> _loadStoredProfileData() async {
    final profilePicture = await _userProfileService.getStoredProfilePicture();
    final profileName = await _userProfileService.getStoredProfileName();
    final profileEmail = await _userProfileService.getStoredProfileEmail();
    final lastUpdated = await _userProfileService.getLastUpdated();
    final isStale = await _userProfileService.isProfileDataStale();

    if (mounted) {
      setState(() {
        _storedProfilePicture = profilePicture;
        _storedProfileName = profileName;
        _storedProfileEmail = profileEmail;
        _lastUpdated = lastUpdated;
      });
    }
  }

  Future<void> _refreshProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _userProfileService.storeProfileFromFirebaseUser(user);
      await _loadStoredProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile data refreshed!')),
        );
      }
    }
  }

  Future<void> _clearProfileData() async {
    await _userProfileService.clearStoredProfile();
    await _loadStoredProfileData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data cleared!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfileData,
            tooltip: 'Refresh Profile Data',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearProfileData,
            tooltip: 'Clear Profile Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Firebase User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Firebase User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (user != null) ...[
                      _buildInfoRow('Email', user.email ?? 'N/A'),
                      _buildInfoRow('Display Name', user.displayName ?? 'N/A'),
                      _buildInfoRow('Photo URL', user.photoURL ?? 'N/A'),
                      _buildInfoRow('UID', user.uid),
                    ] else ...[
                      const Text('No user signed in'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stored Profile Data
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stored Profile Data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Stored Photo URL', _storedProfilePicture ?? 'None'),
                    _buildInfoRow('Stored Name', _storedProfileName ?? 'None'),
                    _buildInfoRow('Stored Email', _storedProfileEmail ?? 'None'),
                    _buildInfoRow('Last Updated', _lastUpdated ?? 'Never'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Profile Avatar Examples
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Avatar Examples',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text('Small'),
                            const SizedBox(height: 8),
                            UserProfileAvatar(radius: 20),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Medium'),
                            const SizedBox(height: 8),
                            UserProfileAvatar(radius: 30),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Large'),
                            const SizedBox(height: 8),
                            UserProfileAvatar(radius: 40),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text('With Border'),
                            const SizedBox(height: 8),
                            UserProfileAvatar(
                              radius: 30,
                              showBorder: true,
                              borderColor: Colors.blue,
                              borderWidth: 3,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Custom Color'),
                            const SizedBox(height: 8),
                            UserProfileAvatar(
                              radius: 30,
                              backgroundColor: Colors.purple[100],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _refreshProfileData,
                            child: const Text('Refresh Profile Data'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearProfileData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Clear Profile Data'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
