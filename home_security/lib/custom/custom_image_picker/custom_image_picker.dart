// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:home_security/cloudinary.dart';

class CustomImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final double? imageSize;
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
        setState(() => _pickedImage = pickedImage);
        await _uploadImageToCloudinary();
      }
    } catch (error) {
      setState(() => _errorMessage = 'Error picking image: $error');
    }
  }

  Future<File> _resizeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) throw Exception('Failed to decode image.');
    final resizedImage = img.copyResize(originalImage, width: 600);
    final tempDir = Directory.systemTemp;
    final resizedFile = File(
      '${tempDir.path}/resized_img_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    resizedFile.writeAsBytesSync(img.encodeJpg(resizedImage, quality: 85));
    return resizedFile;
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_pickedImage == null) return;
    try {
      setState(() => _isLoading = true);
      final resizedImage = await _resizeImage(File(_pickedImage!.path));
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: resizedImage.path,
          resourceType: CloudinaryResourceType.image,
        ),
      );
      if (response.isSuccessful) {
        setState(() => _uploadedImageUrl = response.secureUrl);
        widget.onImageUploaded(_uploadedImageUrl!);
      } else {
        setState(() => _errorMessage = 'Upload failed: ${response.error}');
      }
    } catch (error) {
      setState(() => _errorMessage = 'Upload error: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  ImageProvider _getImageProvider() {
    if (_pickedImage != null) return FileImage(File(_pickedImage!.path));
    if (_uploadedImageUrl != null) return NetworkImage(_uploadedImageUrl!);
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return NetworkImage(widget.currentImageUrl!);
    }
    return const AssetImage('assets/images/default_avatar.png');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ),
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  radius: widget.imageSize ?? 60,
                  backgroundImage:
                      _pickedImage != null ||
                          _uploadedImageUrl != null ||
                          (widget.currentImageUrl?.isNotEmpty ?? false)
                      ? _getImageProvider()
                      : null,
                  child:
                      (_pickedImage == null &&
                          _uploadedImageUrl == null &&
                          (widget.currentImageUrl?.isEmpty ?? true))
                      ? Icon(
                          Icons.person_outline_rounded,
                          size: 50,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        )
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 3),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 18,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
