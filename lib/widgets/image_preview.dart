import 'dart:io';
import 'package:flutter/material.dart';

/// A rectangular preview area that displays either a placeholder with an icon
/// and guide text or the selected image file.
class ImagePreview extends StatelessWidget {
  final File? imageFile;
  final VoidCallback? onTap;

  const ImagePreview({
    super.key,
    required this.imageFile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: imageFile != null ? Colors.green.shade600 : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageFile != null
            ? Image.file(
                imageFile!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a paddy leaf image',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
