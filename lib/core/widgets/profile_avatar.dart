import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';

class ProfileAvatar extends StatefulWidget {
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final Widget? fallbackIcon;
  final String? fallbackText;
  final bool useStoredProfile;

  const ProfileAvatar({
    super.key,
    this.radius = 30,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.backgroundColor,
    this.fallbackIcon,
    this.fallbackText,
    this.useStoredProfile = true,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final UserProfileService _userProfileService = UserProfileService();
  String? _profilePictureUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    if (!widget.useStoredProfile) {
      // Use Firebase Auth directly
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          _profilePictureUrl = user?.photoURL;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final profilePicture = await _userProfileService.getProfilePictureWithFallback();
      if (mounted) {
        setState(() {
          _profilePictureUrl = profilePicture;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile picture: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor ?? Colors.grey[300],
        child: const CircularProgressIndicator(),
      );
    }

    if (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor ?? Colors.white,
        backgroundImage: NetworkImage(_profilePictureUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // If network image fails, show fallback
          if (mounted) {
            setState(() {
              _profilePictureUrl = null;
            });
          }
        },
      );
    }

    // Fallback to default profile picture or icon
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor ?? Colors.grey[300],
      child: widget.fallbackIcon ??
          (widget.fallbackText != null
              ? Text(
                  widget.fallbackText!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: widget.radius * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(
                  Icons.person,
                  color: Colors.grey,
                )),
    );
  }
}

// A specialized profile avatar that shows user initials as fallback
class UserProfileAvatar extends StatelessWidget {
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final bool useStoredProfile;

  const UserProfileAvatar({
    super.key,
    this.radius = 30,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.backgroundColor,
    this.useStoredProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(
      radius: radius,
      showBorder: showBorder,
      borderColor: borderColor,
      borderWidth: borderWidth,
      backgroundColor: backgroundColor,
      useStoredProfile: useStoredProfile,
      fallbackText: _getUserInitials(),
    );
  }

  String _getUserInitials() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null) {
      final name = user!.displayName!;
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.length == 1) {
        return parts[0][0].toUpperCase();
      }
    }
    if (user?.email != null) {
      return user!.email![0].toUpperCase();
    }
    return 'U';
  }
}
