import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:murchin/features/home/screens/card_details_screen.dart';
import 'package:murchin/features/home/widgets/custom_card.dart';

class PolymarketCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String? aiPercentage;
  final String team;
  final Color bgColor;
  final Color borderColor;
  final List<String>? optionTitles;
  final List<double>? marketProbs;
  final List<double>? aiPercentages;
  final String? aiExplanation;

  const PolymarketCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    this.aiPercentage,
    required this.team,
    required this.bgColor,
    required this.borderColor,
    this.optionTitles,
    this.marketProbs,
    this.aiPercentages,
    this.aiExplanation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (aiPercentage != null) {
          Get.to(() => CardDetailScreen(
                title: title,
                subtitle: subtitle,
                date: date,
                marketPercentage: marketPercentage,
                aiPercentage: aiPercentage!,
                team: team,
                isPolymarket: true,
                bgColor: bgColor,
                optionTitles: optionTitles,
                marketProbs: marketProbs,
                aiPercentages: aiPercentages,
                aiExplanation: aiExplanation,
              ));
        }
      },
      child: BaseCard(
        title: title,
        subtitle: subtitle,
        date: date,
        marketPercentage: marketPercentage,
        aiPercentage: aiPercentage,
        team: team,
        bgColor: bgColor,
        borderColor: borderColor,
        platform: 'Polymarket',
        iconAsset: 'assets/icons/polymarket.png',
      ),
    );
  }
}
