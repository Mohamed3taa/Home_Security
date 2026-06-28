// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_security/app_routes.dart';
import 'package:home_security/cloudinary.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class SignUpScreen extends StatefulWidget {
  // Optional prefill values (if coming from Google, for example)
  final String? prefillName;
  final String? prefillEmail;

  const SignUpScreen({super.key, this.prefillName, this.prefillEmail});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Text controllers
  late TextEditingController _nameController;
  final TextEditingController _phoneController = TextEditingController();
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Password visibility states
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _photoUrl;

  // A helper getter: if prefillEmail is provided, we consider that the user is already created via an external provider (like Google).
  bool get _isPrefilled => widget.prefillEmail != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefillName ?? '');
    _emailController = TextEditingController(text: widget.prefillEmail ?? '');
  }

  /// Either creates a new client account (if no prefill) or updates the Firestore
  /// document for the already-authenticated user.
  Future<void> _createAccount() async {
    // Check common required fields.
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    // If not prefilled (i.e., standard email/password sign-up), validate credentials.
    if (!_isPrefilled) {
      if (_emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields.')),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }
    }

    try {
      User? user;
      if (!_isPrefilled) {
        // Create new user using email and password.
        UserCredential credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        user = credential.user;
      } else {
        // User is already authenticated (e.g., via Google)
        user = FirebaseAuth.instance.currentUser;
      }
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred during account creation.'),
          ),
        );
        return;
      }

      // Update displayName using the entered name (non-deprecated method)
      await user.updateDisplayName(_nameController.text.trim());

      if (!_isPrefilled && _photoUrl != null) {
        await user.updatePhotoURL(_photoUrl);
      }

      await user.reload();
      user = FirebaseAuth.instance.currentUser!;

      // Save/Update user data in the Users collection
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _isPrefilled
            ? widget.prefillEmail
            : _emailController.text.trim(),
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Navigate to the home screen after successful sign-up/profile completion (UPDATED ROUTE)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully! Welcome!')),
      );
      // We use pushReplacement to navigate straight to the home screen
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      String errorMsg = '';
      if (e.code == 'weak-password') {
        errorMsg = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMsg = 'The email address is already in use by another account.';
      } else {
        errorMsg = 'Error: ${e.message}';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating account: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Directionality is set to LTR (English standard)
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colorScheme.surface, // Replaced colorScheme.background
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Subtitle
                Center(
                  child: Text(
                    'Client Registration',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onSurface, // Changed to onSurface
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Welcome! Please create a new account.',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface.withAlpha(
                        179,
                      ), // Changed to onSurface
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Form container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withAlpha(
                          26,
                        ), // Fixed deprecated withOpacity
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CustomImagePicker(
                          currentImageUrl: _isPrefilled
                              ? FirebaseAuth.instance.currentUser?.photoURL
                              : null,
                          onImageUploaded: (url) {
                            _photoUrl = url;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Name
                      Text(
                        'Name',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.left,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colorScheme
                              .surfaceContainerLow, // Replaced colorScheme.background
                          hintText: 'Enter your name',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Phone
                      Text(
                        'Phone Number',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _phoneController,
                        textAlign: TextAlign.left,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: colorScheme
                              .surfaceContainerLow, // Replaced colorScheme.background
                          hintText: 'Enter phone number',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_isPrefilled) ...[
                        // Email
                        Text(
                          'Email Address',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _emailController,
                          textAlign: TextAlign.left,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme
                                .surfaceContainerLow, // Replaced colorScheme.background
                            hintText: 'Enter email address',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        Text(
                          'Password',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textAlign: TextAlign.left,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme
                                .surfaceContainerLow, // Replaced colorScheme.background
                            hintText: 'Enter password',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        Text(
                          'Confirm Password',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textAlign: TextAlign.left,
                          style: TextStyle(color: colorScheme.onSurface),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme
                                .surfaceContainerLow, // Replaced colorScheme.background
                            hintText: 'Re-enter password',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Create Account / Complete Profile Button
                      SizedBox(
                        width: screenWidth,
                        height:
                            52, // Slightly increased height for better touch target
                        child: ElevatedButton(
                          onPressed: _createAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5, // Added elevation
                            shadowColor: colorScheme.primary.withAlpha(150),
                          ),
                          child: Text(
                            _isPrefilled
                                ? 'Complete Profile'
                                : 'Create Account',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface, // Changed to onSurface
                        ),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final double? imageSize;
  // Callback to return the uploaded photo URL
  final void Function(String photoUrl) onImageUploaded;

  const CustomImagePicker({
    super.key,
    this.currentImageUrl,
    this.imageSize,
    required this.onImageUploaded,
  });

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  XFile? _pickedImage;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        setState(() {
          _pickedImage = pickedImage;
        });
        await _uploadImageToCloudinary();
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error picking image: $error';
      });
    }
  }

  Future<File> _resizeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception('Failed to decode image.');
    }

    // Resize the image (e.g., max width of 600px)
    final resizedImage = img.copyResize(
      originalImage,
      width: 600, // Change this to your desired width
    );

    // Save the resized image to a temporary file
    final tempDir = Directory.systemTemp;
    final resizedFile = File('${tempDir.path}/resized_image.jpg');
    resizedFile.writeAsBytesSync(img.encodeJpg(resizedImage, quality: 85));

    return resizedFile;
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_pickedImage == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Resize the image before uploading
      final resizedImage = await _resizeImage(File(_pickedImage!.path));

      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: resizedImage.path,
          resourceType: CloudinaryResourceType.image,
        ),
      );

      if (response.isSuccessful) {
        setState(() {
          _uploadedImageUrl = response.secureUrl!;
          if (kDebugMode) {
            print(response.secureUrl!);
          }
        });

        // Optionally update the user's profile picture URL if using FirebaseAuth
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePhotoURL(_uploadedImageUrl);
        }
        // Return the URL via callback
        widget.onImageUploaded(_uploadedImageUrl!);
      } else {
        setState(() {
          _errorMessage = 'Error uploading image: ${response.error}';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error uploading image: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ImageProvider _getImageProvider() {
    try {
      if (_pickedImage != null) {
        return FileImage(File(_pickedImage!.path));
      } else if (_uploadedImageUrl != null) {
        return NetworkImage(_uploadedImageUrl!);
      } else if (widget.currentImageUrl != null &&
          widget.currentImageUrl!.isNotEmpty) {
        return NetworkImage(widget.currentImageUrl!);
      } else {
        return const AssetImage('assets/images/default_avatar.png');
      }
    } catch (error) {
      return const AssetImage('assets/images/default_avatar.png');
    }
  }

  bool _isUsingDefaultImage() {
    return widget.currentImageUrl == null && _pickedImage == null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
          ),
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: widget.imageSize ?? 100,
            backgroundImage: _getImageProvider(),
            child: _isUsingDefaultImage() ? null : null,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
      ],
    );
  }
}
