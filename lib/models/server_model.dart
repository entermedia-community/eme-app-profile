import 'package:flutter/material.dart';

class ServerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String description;
  final String category;
  final List<String> tags;
  final IconData iconData;
  final Color primaryColor;
  final Color secondaryColor;
  final int memberCount;
  final bool isJoined;
  final String? bannerSvgOrType;
  final double? rating;
  final int? reviewsCount;
  final String? servicePricing;
  final String? location;
  final bool isVerified;
  final List<String> servicesOffered;
  final String? avatarUrl;
  final String? lastNotification;
  final String? lastNotificationTime;
  final Color? statusColor;

  const ServerModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.description,
    required this.category,
    required this.tags,
    required this.iconData,
    this.primaryColor = const Color(0xFF2563EB),
    this.secondaryColor = const Color(0xFFEFF6FF),
    this.memberCount = 120,
    this.isJoined = false,
    this.bannerSvgOrType,
    this.rating,
    this.reviewsCount,
    this.servicePricing,
    this.location,
    this.isVerified = true,
    this.servicesOffered = const [],
    this.avatarUrl,
    this.lastNotification,
    this.lastNotificationTime,
    this.statusColor,
  });

  ServerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? category,
    List<String>? tags,
    IconData? iconData,
    Color? primaryColor,
    Color? secondaryColor,
    int? memberCount,
    bool? isJoined,
    String? bannerSvgOrType,
    double? rating,
    int? reviewsCount,
    String? servicePricing,
    String? location,
    bool? isVerified,
    List<String>? servicesOffered,
    String? avatarUrl,
    String? lastNotification,
    String? lastNotificationTime,
    String? status,
    Color? statusColor,
  }) {
    return ServerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      iconData: iconData ?? this.iconData,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      memberCount: memberCount ?? this.memberCount,
      isJoined: isJoined ?? this.isJoined,
      bannerSvgOrType: bannerSvgOrType ?? this.bannerSvgOrType,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      servicePricing: servicePricing ?? this.servicePricing,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastNotification: lastNotification ?? this.lastNotification,
      lastNotificationTime: lastNotificationTime ?? this.lastNotificationTime,
      statusColor: statusColor ?? this.statusColor,
    );
  }
}
