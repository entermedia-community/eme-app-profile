import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'eme_profile_card.dart';

/// Legacy alias for EmeProfileCard
class IndividualCard extends ConsumerWidget {
  final dynamic specialist;

  const IndividualCard({super.key, required this.specialist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (specialist is EmeProfileModel) {
      return EmeProfileCard(profile: specialist as EmeProfileModel);
    }
    // Fallback if passing legacy specialist object
    final p = EmeProfileModel(
      id: specialist.id as String,
      name: (specialist.title ?? specialist.name) as String,
      specialistTitle: specialist.specialistTitle as String?,
      subtitle: specialist.subtitle as String?,
      description: specialist.description as String,
      category: specialist.category is ProfileCategory
          ? specialist.category as ProfileCategory
          : ProfileCategory.fromString(specialist.category.toString()),
      tags: (specialist.tags as List<dynamic>).cast<String>(),
      iconData: specialist.iconData as IconData,
      avatarUrl: specialist.avatarUrl as String?,
      primaryColor: specialist.primaryColor as Color,
      secondaryColor: specialist.secondaryColor as Color,
      memberCount: specialist.memberCount as int,
      rating: specialist.rating as double?,
      reviewsCount: specialist.reviewsCount as int?,
      servicePricing: specialist.servicePricing as String?,
      location: specialist.location as String?,
      isVerified: specialist.isVerified as bool,
      servicesOffered:
          (specialist.servicesOffered as List<dynamic>).cast<String>(),
    );
    return EmeProfileCard(profile: p);
  }
}
