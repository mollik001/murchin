// lib/features/home/widgets/kalshi_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:murchin/features/home/screens/card_details_screen.dart';
import 'package:murchin/features/home/widgets/custom_card.dart';

class KalshiCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String aiPercentage;
  final String team;
  final Color bgColor;
  final Color borderColor;

  const KalshiCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.marketPercentage,
    required this.aiPercentage,
    required this.team,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to card detail screen
        Get.to(() => CardDetailScreen(
          title: title,
          subtitle: subtitle,
          date: date,
          marketPercentage: marketPercentage,
          aiPercentage: aiPercentage,
          team: team,
          isPolymarket: false,
          bgColor: bgColor,
        ));
      },
child: BaseCard(
  title: title,
  subtitle: subtitle,
  date: date,
  marketPercentage: marketPercentage,
  aiPercentage: aiPercentage,
  team: team,
  bgColor: bgColor,
  platform: 'Kalshi',
  iconAsset: 'assets/icons/kalshi.png',
  borderColor: borderColor,
  initiallySaved: false, // Add this - you can make it dynamic if needed
),
    );
  }
}