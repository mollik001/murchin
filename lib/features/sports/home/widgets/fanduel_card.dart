import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:murchin/features/sports/home/controllers/sports_home_controller.dart';
import 'package:murchin/features/sports/home/widgets/sports_card_details_screen.dart';
import 'package:murchin/features/sports/home/widgets/sports_base_card.dart';

class FanduelCard extends StatelessWidget {
  final String? eventId;
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
        
        final bookmark = eventRef?['bookmark'] as Map<String, dynamic>?;
        
        // Extract spread, moneyline, and total from bookmark
        String? spreadAway, spreadHome, moneylineAway, moneylineHome, totalOver, totalUnder;
        String? aiSpreadAway, aiSpreadHome, aiMoneylineAway, aiMoneylineHome, aiTotalOver, aiTotalUnder;
        
        if (bookmark != null) {
          aiMoneylineAway = bookmark['ai_moneyline_away'] as String?;
          aiMoneylineHome = bookmark['ai_moneyline_home'] as String?;
          aiSpreadAway = bookmark['ai_spread_away'] as String?;
          aiSpreadHome = bookmark['ai_spread_home'] as String?;
          aiTotalOver = bookmark['ai_total_over'] as String?;
          aiTotalUnder = bookmark['ai_total_under'] as String?;
          
          // Get market data
          final markets = bookmark['market'] as List<dynamic>?;
          if (markets != null) {
            for (var market in markets) {
              final key = market['key'] as String?;
              final outcome = market['outcome'] as Map<String, dynamic>?;
              if (outcome == null) continue;
              
              if (key == 'h2h') {
                final away = outcome['away_team'] as Map<String, dynamic>?;
                final home = outcome['home_team'] as Map<String, dynamic>?;
                moneylineAway = away?['american'] as String?;
                moneylineHome = home?['american'] as String?;
              } else if (key == 'spreads' || key == 'spread') {
                final away = outcome['away_team'] as Map<String, dynamic>?;
                final home = outcome['home_team'] as Map<String, dynamic>?;
                spreadAway = away?['american'] as String?;
                spreadHome = home?['american'] as String?;
              } else if (key == 'totals' || key == 'total') {
                final over = outcome['over'] as Map<String, dynamic>?;
                final under = outcome['under'] as Map<String, dynamic>?;
                totalOver = over?['american'] as String?;
                totalUnder = under?['american'] as String?;
              }
            }
          }
        }

        Get.to(() => SportsCardDetailsScreen(
              title: title,
              subtitle: subtitle,
              date: date,
              marketPercentage: marketPercentage,
              aiPercentage: effectiveAiPercentage ?? 'N/A',
              team: team,
              isFanduel: true,
              bgColor: bgColor,
              eventId: eventId,
              platform: platform,
              awayTeam: subtitle.split(' vs ').firstOrNull?.trim(),
              homeTeam: subtitle.split(' vs ').lastOrNull?.trim(),
              spreadAway: spreadAway ?? '-',
              spreadHome: spreadHome ?? '-',
              moneylineAway: moneylineAway ?? '-',
              moneylineHome: moneylineHome ?? '-',
              totalOver: totalOver ?? '-',
              totalUnder: totalUnder ?? '-',
              aiSpreadAway: aiSpreadAway,
              aiSpreadHome: aiSpreadHome,
              aiMoneylineAway: aiMoneylineAway,
              aiMoneylineHome: aiMoneylineHome,
              aiTotalOver: aiTotalOver,
              aiTotalUnder: aiTotalUnder,
            ));
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
                controller.saveEvent(eventId: eventId!, marketPlace: platform);
              }
            },
      ),
    );
  }
}
