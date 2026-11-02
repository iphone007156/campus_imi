import 'dart:convert';
import 'package:flutter/material.dart';

class FullScreenImageScreen extends StatelessWidget {
  final String imageUrl;
  final bool isBase64;

  const FullScreenImageScreen({
    super.key,
    required this.imageUrl,
    required this.isBase64,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Черный фон для просмотра
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        // ✅ InteractiveViewer позволяет приближать (зум) и двигать картинку
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 5.0, // Максимальное приближение (5x)
          child: isBase64
              ? Image.memory(
            base64Decode(imageUrl),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            width: double.infinity,
          )
              : Image.network(
            imageUrl,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            width: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
          ),
        ),
      ),
    );
  }
}