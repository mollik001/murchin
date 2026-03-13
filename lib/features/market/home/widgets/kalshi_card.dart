// lib/features/market/home/widgets/kalshi_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:murchin/features/market/home/controllers/home_controller.dart';
import 'package:murchin/features/market/home/screens/card_details_screen.dart';
import 'package:murchin/features/market/home/widgets/custom_card.dart';

class KalshiCard extends StatelessWidget {
  final String? eventId;
  final String title;
  final String subtitle;
  final String date;
  final String marketPercentage;
  final String? aiPercentage;
  final String team;
  final Color bgColor;
  final Color borderColor;
  final String? seriesTicker;
  final List<String>? optionTitles;
  final List<double>? marketProbs;
  final List<double>? aiPercentages;
  final String? aiExplanation;
  final bool isSaved;
  final VoidCallback? onSaved;
  final Map<String, dynamic>? eventRef;

  const KalshiCard({
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
    this.seriesTicker,
    this.optionTitles,
    this.marketProbs,
    this.aiPercentages,
    this.aiExplanation,
    this.isSaved = false,
    this.onSaved,
    this.eventRef,
  });

  /// Get option titles for details screen
  List<String>? _getOptionTitles() {
    final ref = eventRef ?? {};
    final allOptionTitles = ref['optionTitles'] as List<dynamic>? ?? optionTitles ?? [];
    final allMarketProbs = ref['marketProbs'] as List<dynamic>? ?? marketProbs ?? [];
    
    // If we only have one option (single outcome event), show both YES and NO
    if (allOptionTitles.length == 1 && allMarketProbs.length == 1) {
      // Single outcome - return YES title and NO title
      final titleNo = ref['title_no'] as String? ?? 'No';
      return [allOptionTitles[0], titleNo];
    }
    
    // Multiple outcomes - return all valid options (non-0/non-100)
    List<String> validTitles = [];
    for (int i = 0; i < allOptionTitles.length && i < allMarketProbs.length; i++) {
      final prob = allMarketProbs[i] is double ? allMarketProbs[i] as double : double.tryParse(allMarketProbs[i].toString()) ?? 0;
      if (prob > 0 && prob < 100) {
        validTitles.add(allOptionTitles[i]);
      }
    }
    return validTitles.isNotEmpty ? validTitles : null;
  }

  /// Get market probabilities for details screen
  List<double>? _getMarketProbs() {
    final ref = eventRef ?? {};
    final allOptionTitles = ref['optionTitles'] as List<dynamic>? ?? optionTitles ?? [];
    final allMarketProbs = ref['marketProbs'] as List<dynamic>? ?? marketProbs ?? [];
    
    // If we only have one option (single outcome event), show both YES and NO probabilities
    if (allOptionTitles.length == 1 && allMarketProbs.length == 1) {
      final yesProb = allMarketProbs[0] is double ? allMarketProbs[0] as double : double.tryParse(allMarketProbs[0].toString()) ?? 0;
      final noProb = ref['probability_no'] as double? ?? (100 - yesProb);
      return [yesProb, noProb];
    }
    
    // Multiple outcomes - return all valid probabilities (non-0/non-100)
    List<double> validProbs = [];
    for (int i = 0; i < allOptionTitles.length && i < allMarketProbs.length; i++) {
      final prob = allMarketProbs[i] is double ? allMarketProbs[i] as double : double.tryParse(allMarketProbs[i].toString()) ?? 0;
      if (prob > 0 && prob < 100) {
        validProbs.add(prob);
      }
    }
    return validProbs.isNotEmpty ? validProbs : null;
  }

  /// Get AI percentages for details screen
  List<double>? _getAiPercentages() {
    final ref = eventRef ?? {};
    final allAiPercentages = ref['aiPercentages'] as List<dynamic>? ?? aiPercentages ?? [];
    final allOptionTitles = ref['optionTitles'] as List<dynamic>? ?? optionTitles ?? [];
    final allMarketProbs = ref['marketProbs'] as List<dynamic>? ?? marketProbs ?? [];
    
    // If we only have one option (single outcome event), show YES AI value (NO has no AI)
    if (allOptionTitles.length == 1 && allMarketProbs.length == 1) {
      final yesAi = allAiPercentages.isNotEmpty 
          ? (allAiPercentages[0] is double ? allAiPercentages[0] as double : (double.tryParse(allAiPercentages[0].toString()) ?? 0.0))
          : 0.0;
      // For NO, we don't have AI prediction, so use 0
      return [yesAi, 0.0];
    }
    
    // Multiple outcomes - return all valid AI percentages
    List<double> validAi = [];
    for (int i = 0; i < allOptionTitles.length && i < allAiPercentages.length; i++) {
      final prob = allMarketProbs[i] is double ? allMarketProbs[i] as double : double.tryParse(allMarketProbs[i].toString()) ?? 0;
      if (prob > 0 && prob < 100) {
        final ai = allAiPercentages[i] is double ? allAiPercentages[i] as double : double.tryParse(allAiPercentages[i].toString()) ?? 0;
        validAi.add(ai);
      }
    }
    return validAi.isNotEmpty ? validAi : null;
  }

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
                isPolymarket: false,
                bgColor: bgColor,
                eventIdString: eventId,
                seriesTicker: eventRef != null
                    ? (eventRef!['series_ticker'] as String?) ?? seriesTicker
                    : seriesTicker,
                optionTitles: _getOptionTitles(),
                marketProbs: _getMarketProbs(),
                aiPercentages: _getAiPercentages(),
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
        platform: 'Kalshi',
        iconAsset: 'assets/icons/kalshi.png',
        initiallySaved: isSaved,
        onSaved: onSaved ??
            () {
              if (eventId != null) {
                // For Kalshi, we use the event ticker directly as a string identifier
                // The saveEvent method will be updated to handle this
                print("Save Kalshi event: $eventId");
                // TODO: Implement Kalshi save with string ID
              }
            },
      ),
    );
  }
}