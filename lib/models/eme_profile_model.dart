import 'package:flutter/material.dart';

/// Categories available for EME World specialist profiles
enum ProfileCategory {
  ecoTourism('Eco Tourism'),
  finance('Finance'),
  artificialIntelligence('Artificial Intelligence'),
  socialServices('Social Services'),
  softwareTools('Software Tools'),
  research('Research'),
  education('Education'),
  healthcare('Healthcare'),
  startup('Startup'),
  rentalAndGear('Rental & Gear'),
  mobilityAndRides('Mobility & Rides'),
  marketplaceAndGoods('Marketplace & Goods');

  final String label;
  const ProfileCategory(this.label);

  static ProfileCategory fromString(String value) {
    return ProfileCategory.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => ProfileCategory.softwareTools,
    );
  }
}

typedef EmeProfileCategory = ProfileCategory;

class EmeProfileModel {
  final String id;
  final String name;
  final String? specialistTitle;
  final String? subtitle;
  final String description;
  final ProfileCategory category;
  final List<String> tags;
  final IconData iconData;
  final String? avatarUrl;
  final Color primaryColor;
  final Color secondaryColor;
  final int memberCount;
  final double? rating;
  final int? reviewsCount;
  final String? servicePricing;
  final String? location;
  final bool isVerified;
  final List<String> servicesOffered;

  const EmeProfileModel({
    required this.id,
    required this.name,
    this.specialistTitle,
    this.subtitle,
    required this.description,
    required this.category,
    required this.tags,
    required this.iconData,
    this.avatarUrl,
    this.primaryColor = const Color(0xFF2563EB),
    this.secondaryColor = const Color(0xFFEFF6FF),
    this.memberCount = 50,
    this.rating,
    this.reviewsCount,
    this.servicePricing,
    this.location,
    this.isVerified = true,
    this.servicesOffered = const [],
  });

  EmeProfileModel copyWith({
    String? id,
    String? name,
    String? specialistTitle,
    String? subtitle,
    String? description,
    ProfileCategory? category,
    List<String>? tags,
    IconData? iconData,
    String? avatarUrl,
    Color? primaryColor,
    Color? secondaryColor,
    int? memberCount,
    double? rating,
    int? reviewsCount,
    String? servicePricing,
    String? location,
    bool? isVerified,
    List<String>? servicesOffered,
  }) {
    return EmeProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialistTitle: specialistTitle ?? this.specialistTitle,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      iconData: iconData ?? this.iconData,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      memberCount: memberCount ?? this.memberCount,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      servicePricing: servicePricing ?? this.servicePricing,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      servicesOffered: servicesOffered ?? this.servicesOffered,
    );
  }
}
