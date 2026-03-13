import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:murchin/features/market/home/controllers/home_controller.dart';
import 'package:murchin/features/market/home/screens/card_details_screen.dart';
import 'package:murchin/features/market/home/widgets/custom_card.dart';

class PolymarketCard extends StatelessWidget {
  final int? eventId;
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String? aiPercentage;
  final String team;
  final Color bgColor;
  final Color borderColor;
  final String? slug;
  final List<String>? optionTitles;
  final List<double>? marketProbs;
  final List<double>? aiPercentages;
  final String? aiExplanation;
  final bool isSaved;
  final VoidCallback? onSaved;
  final Map<String, dynamic>? eventRef;

  const PolymarketCard({
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
    this.slug,
    this.optionTitles,
    this.marketProbs,
    this.aiPercentages,
    this.aiExplanation,
    this.isSaved = false,
    this.onSaved,
    this.eventRef,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return GestureDetector(
      onTap: () {
        final effectiveAiPercentage = eventRef != null
            ? (eventRef!['aiPercentage'] as String?) ?? aiPercentage
            : aiPercentage;

        if (effectiveAiPercentage != null) {
          Get.to(() => CardDetailScreen(
                title: title,
                subtitle: subtitle,
                date: date,
                marketPercentage: marketPercentage,
                aiPercentage: effectiveAiPercentage,
                team: team,
                isPolymarket: true,
                bgColor: bgColor,
                eventId: eventId,
                slug: eventRef != null
                    ? (eventRef!['slug'] as String?) ?? slug
                    : slug,
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
      child: BaseCard(
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
        platform: 'Polymarket',
        iconAsset: 'assets/icons/polymarket.png',
        initiallySaved: isSaved,
        onSaved: onSaved ??
            () {
              if (eventId != null) {
                controller.saveEvent(eventId: eventId!, marketPlace: 'Polymarket');
              }
            },
      ),
    );
  }
}
