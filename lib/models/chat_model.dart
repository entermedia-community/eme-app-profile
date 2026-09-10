import 'package:flutter/material.dart';

class ChatModel {
  final String id;
  final String userName;
  final String userRole;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final Color avatarColor;
  final bool isOnline;
  final String? avatarInitials;

  const ChatModel({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    required this.avatarColor,
    this.isOnline = false,
    this.avatarInitials,
  });
}
