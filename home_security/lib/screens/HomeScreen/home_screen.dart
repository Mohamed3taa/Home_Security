import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:home_security/app_routes.dart';
import 'package:home_security/custom/custom_image_picker/custom_image_picker.dart';
import 'package:home_security/notification/firebase_notification_api.dart';
import 'package:home_security/screens/HomeScreen/LiveStream/live_stream_viewer.dart';
import 'package:home_security/screens/HomeScreen/NotificationScreen/notification_screen.dart';
import 'package:home_security/screens/HomeScreen/hardware/hardware_control_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _photoUrl;

  @override
  void initState() {
    super.initState();

    firebaseNotificationApi.initNotifications();

    _photoUrl = _auth.currentUser?.photoURL;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadCurrentImageUrl();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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

        if (userDoc.exists && mounted) {
          setState(() {
            _photoUrl = userDoc.get('photoUrl') as String?;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar(
              message: 'Error loading profile image: $e',
              isError: true,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleUpdateProfileImage(String newUrl) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('Users').doc(user.uid).update({
          'photoUrl': newUrl,
        });

        await user.updatePhotoURL(newUrl);

        if (mounted) {
          setState(() {
            _photoUrl = newUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar(message: 'Profile picture updated!', isError: false),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar(message: 'Error updating image: $e', isError: true),
          );
        }
      }
    }
  }

  SnackBar _buildSnackBar({required String message, bool isError = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final snackBarTheme = theme.snackBarTheme;

    return SnackBar(
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isError ? colorScheme.onError : colorScheme.onPrimary,
        ),
      ),
      backgroundColor: isError ? colorScheme.error : colorScheme.primary,
      behavior: snackBarTheme.behavior ?? SnackBarBehavior.floating,
      shape:
          snackBarTheme.shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: snackBarTheme.behavior == SnackBarBehavior.floating
          ? const EdgeInsets.all(12)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = _auth.currentUser;

    String fullName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
    String firstName = fullName.split(' ')[0];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: CustomImagePicker(
                    currentImageUrl: _photoUrl,
                    imageSize: 32,
                    onImageUploaded: _handleUpdateProfileImage,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Home Security',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hello, $firstName!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Notification Icon Button with Real-time Count
                StreamBuilder<QuerySnapshot>(
                  stream: user != null
                      ? _firestore
                            .collection('Users')
                            .doc(user.uid)
                            .collection('notifications')
                            .where('read', isEqualTo: false)
                            .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    final int count = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;

                    return IconButton(
                      icon: Stack(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          if (count > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  count > 99 ? '99+' : '$count',
                                  style: TextStyle(
                                    color: colorScheme.onError,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.settings),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LiveStreamViewer(),
                  const HardwareControlSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
