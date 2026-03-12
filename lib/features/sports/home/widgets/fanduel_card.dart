import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:murchin/features/sports/home/controllers/sports_home_controller.dart';
import 'package:murchin/features/sports/home/widgets/sports_card_details_screen.dart';
import 'package:murchin/features/sports/home/widgets/sports_base_card.dart';

class FanduelCard extends StatelessWidget {
  final int? eventId;
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String? aiPercentage;
  final String team;
  final Color bgColor;
  final Color borderColor;
  final String platform;
  final List<String>? optionTitles;
  final List<double>? marketProbs;
  final List<double>? aiPercentages;
  final String? aiExplanation;
  final bool isSaved;
  final VoidCallback? onSaved;
  final Map<String, dynamic>? eventRef;
  final VoidCallback? customOnTap;

  const FanduelCard({
    super.key,
    this.eventId,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    this.aiPercentage,
    required this.team,
    required this.bgColor,
    required this.borderColor,
    required this.platform,
    this.optionTitles,
    this.marketProbs,
    this.aiPercentages,
    this.aiExplanation,
    this.isSaved = false,
    this.onSaved,
    this.eventRef,
    this.customOnTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SportsHomeController>();

    return GestureDetector(
      onTap: customOnTap ?? () {
        final effectiveAiPercentage = eventRef != null
            ? (eventRef!['aiPercentage'] as String?) ?? aiPercentage
            : aiPercentage;

        if (effectiveAiPercentage != null) {
          Get.to(() => SportsCardDetailsScreen(
                title: title,
                subtitle: subtitle,
                date: date,
                marketPercentage: marketPercentage,
                aiPercentage: effectiveAiPercentage,
                team: team,
                isFanduel: true,
                bgColor: bgColor,
                optionTitles: eventRef != null
                    ? (eventRef!['optionTitles'] as List<String>?) ?? optionTitles
                    : optionTitles,
                marketProbs: eventRef != null
                    ? (eventRef!['marketProbs'] as List<double>?) ?? marketProbs
                    : marketProbs,
                aiPercentages: eventRef != null
                    ? (eventRef!['aiPercentages'] as List<double>?) ?? aiPercentages
                    : aiPercentages,
                aiExplanation: eventRef != null
                    ? (eventRef!['aiExplanation'] as String?) ?? aiExplanation
                    : aiExplanation,
              ));
        }
      },
      child: SportsBaseCard(
        title: title,
        subtitle: subtitle,
        date: date,
        marketPercentage: marketPercentage,
        aiPercentage: eventRef != null
            ? (eventRef!['aiPercentage'] as String?) ?? aiPercentage
            : aiPercentage,
        team: team,
        bgColor: bgColor,
        borderColor: borderColor,
        platform: platform,
        iconAsset: 'assets/images/NBA.png',
        initiallySaved: isSaved,
        onSaved: onSaved ??
            () {
              if (eventId != null) {
                controller.saveEvent(eventId: eventId.toString(), marketPlace: platform);
              }
            },
      ),
    );
  }
}
