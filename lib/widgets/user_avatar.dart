import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class UserAvatar extends StatelessWidget {
  final String? userId;
  final Map<String, dynamic>? customUserData;
  final double size;
  final IconData icon;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.userId,
    this.customUserData,
    required this.size,
    this.icon = Icons.person,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Если передали готовые данные (из списка)
    if (customUserData != null) {
      return _buildAvatar(context, customUserData!);
    }

    // Если передан ID — подписываемся на Firebase
    if (userId != null && userId!.isNotEmpty) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            return _buildAvatar(context, data);
          }
          return _buildPlaceholder(context);
        },
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildAvatar(BuildContext context, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    ImageProvider? imageProvider;

    final photoUrl = data['photoUrl'] as String?;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      imageProvider = NetworkImage(photoUrl);
    } else {
      final base64String = data['photoBase64'] as String?;
      if (base64String != null && base64String.isNotEmpty) {
        try {
          imageProvider = MemoryImage(base64Decode(base64String));
        } catch (_) {}
      }
    }

    final bgColor = backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.1);
    final iconColor = backgroundColor != null ? Colors.white : theme.colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
      ),
      child: imageProvider == null
          ? Icon(icon, size: size * 0.6, color: iconColor)
          : null,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.1);
    final iconColor = backgroundColor != null ? Colors.white : theme.colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
      child: Icon(icon, size: size * 0.6, color: iconColor),
    );
  }
}