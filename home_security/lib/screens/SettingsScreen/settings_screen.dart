// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:home_security/app_routes.dart';
import 'package:home_security/custom/custom_image_picker/custom_image_picker.dart';
import 'package:home_security/models/auth_service.dart';
import 'package:home_security/screens/SettingsScreen/basic_info_screen.dart';
import 'package:home_security/screens/SettingsScreen/change_password_screen.dart';
import 'package:home_security/screens/SettingsScreen/change_email_screen.dart';
import 'package:home_security/screens/SettingsScreen/family_management_screen.dart';
import 'package:home_security/screens/VerificationScreens/verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentImageUrl;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _tileTapController;
  late Animation<double> _tileScaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadCurrentImageUrl();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _tileTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _tileScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tileTapController, curve: Curves.easeInOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _tileTapController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentImageUrl() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('Users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _currentImageUrl = userDoc.get('photoUrl') as String?;
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            message: 'Error loading profile image: $e',
            isError: true,
          ),
        );
      }
    }
  }

  void _handleLogout() async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        titlePadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Text(
            'Sign Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  Future<String?> _promptForPassword() async {
    final controller = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showDialog<String>(
      context: context,
      builder: (context) => FadeTransition(
        opacity: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeInOut,
        ),
        child: AlertDialog(
          backgroundColor: colorScheme.surface,
          titlePadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Enter Password',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: TextField(
              controller: controller,
              obscureText: true,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(
                'Confirm',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleChangeEmail() async {
    final user = _auth.currentUser;
    if (user == null ||
        user.providerData.any((p) => p.providerId == 'google.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          message: 'Email change not available for Google accounts',
          isError: true,
        ),
      );
      return;
    }

    final password = await _promptForPassword();
    if (password == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(message: 'Verification failed: $e', isError: true),
      );
    }
  }

  void _handleChangePassword() async {
    final user = _auth.currentUser;
    if (user == null ||
        user.providerData.any((p) => p.providerId == 'google.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(
          message: 'Password change not available for Google accounts',
          isError: true,
        ),
      );
      return;
    }

    final password = await _promptForPassword();
    if (password == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(message: 'Verification failed: $e', isError: true),
      );
    }
  }

  void _handleDeleteAccount() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => FadeTransition(
        opacity: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeInOut,
        ),
        child: AlertDialog(
          backgroundColor: colorScheme.surface,
          titlePadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Confirm Deletion',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              'Are you sure you want to delete your account?\nThis action cannot be undone.',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Delete',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userProviders = user.providerData.map((e) => e.providerId).toList();

      if (userProviders.contains('google.com')) {
        final googleUser = await _authService.googleSignIn.signIn();
        if (googleUser == null) throw Exception('Google Sign-In failed');

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (userProviders.contains('password')) {
        final password = await _promptForPassword();
        if (password == null) return;

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      final uid = user.uid;
      await _firestore.collection('Users').doc(uid).delete();
      await user.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(message: 'Account deleted successfully', isError: false),
      );

      await _authService.signOut();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildSnackBar(message: 'Error deleting account: $e', isError: true),
      );
    }
  }

  void _handleUpdateProfileImage(String photoUrl) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('Users').doc(user.uid).update({
          'photoUrl': photoUrl,
        });
        await user.updatePhotoURL(photoUrl);
        setState(() {
          _currentImageUrl = photoUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            message: 'Profile image updated successfully',
            isError: false,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar(
            message: 'Error updating profile image: $e',
            isError: true,
          ),
        );
      }
    }
  }

  SnackBar _buildSnackBar({required String message, required bool isError}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError
                ? colorScheme.onErrorContainer
                : colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: isError
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      duration: const Duration(seconds: 3),
      elevation: 6,
      showCloseIcon: true,
      closeIconColor: isError
          ? colorScheme.onErrorContainer
          : colorScheme.onPrimaryContainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.onPrimaryContainer,
        backgroundColor: colorScheme.primaryContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimaryContainer),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Center(
                      child: CustomImagePicker(
                        currentImageUrl: _currentImageUrl,
                        imageSize: 60,
                        onImageUploaded: _handleUpdateProfileImage,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSettingTile(
                      title: 'Basic Info',
                      icon: Icons.person_outline_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BasicInfoScreen(),
                        ),
                      ),
                      tooltip: 'Update your name and phone number',
                    ),
                    // NEW: Family Management Tile
                    _buildSettingTile(
                      title: 'Family Members',
                      icon: Icons.people_outline_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FamilyManagementScreen(),
                        ),
                      ),
                      tooltip: 'Manage your family members',
                    ),
                    _buildSettingTile(
                      title: 'Change Email',
                      icon: Icons.email_outlined,
                      onTap: _handleChangeEmail,
                      tooltip: 'Change your account email address',
                    ),
                    _buildSettingTile(
                      title: 'Change Password',
                      icon: Icons.lock_reset_rounded,
                      onTap: _handleChangePassword,
                      tooltip: 'Change your account password',
                    ),
                    _buildSettingTile(
                      title: 'Verify Email',
                      icon: Icons.verified_user_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmailVerificationScreen(),
                        ),
                      ),
                      tooltip: 'Verify your email address',
                    ),
                    _buildSettingTile(
                      title: 'Share App',
                      icon: Icons.share_rounded,
                      onTap: () {},
                      tooltip: 'Share this app with others',
                    ),
                    _buildSettingTile(
                      title: 'Sign Out',
                      icon: Icons.logout_rounded,
                      onTap: _handleLogout,
                      tooltip: 'Sign out of your account',
                    ),
                    _buildSettingTile(
                      title: 'Delete Account',
                      icon: Icons.delete_outline_rounded,
                      onTap: _handleDeleteAccount,
                      tooltip: 'Permanently delete your account',
                      isDanger: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Tooltip(
        message: tooltip,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.surface,
          fontWeight: FontWeight.w500,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTapDown: (_) => _tileTapController.forward(),
            onTapUp: (_) => _tileTapController.reverse(),
            onTapCancel: () => _tileTapController.reverse(),
            onTap: onTap,
            child: ScaleTransition(
              scale: _tileScaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDanger
                      ? colorScheme.errorContainer.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerLow,
                  border: Border.all(
                    color: isDanger
                        ? colorScheme.error.withValues(alpha: 0.3)
                        : colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDanger
                            ? colorScheme.error.withValues(alpha: 0.1)
                            : colorScheme.primaryContainer.withValues(
                                alpha: 0.4,
                              ),
                      ),
                      child: Icon(
                        icon,
                        color: isDanger
                            ? colorScheme.error
                            : colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDanger
                              ? colorScheme.error
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: isDanger
                          ? colorScheme.error.withValues(alpha: 0.5)
                          : colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
