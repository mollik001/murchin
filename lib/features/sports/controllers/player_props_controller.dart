import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:murchin/const/service/endpoint.dart';
import 'package:murchin/features/sports/model/player_props_model.dart';

class PlayerPropsController extends GetxController {
  final isLoading = false.obs;
  final Rx<PlayerPropsResponse?> _playerProps = Rx<PlayerPropsResponse?>(null);

  PlayerPropsResponse? get playerProps => _playerProps.value;

  @override
  void onInit() {
    super.onInit();
  }

  /// Fetch player props data
  Future<void> fetchPlayerProps({
    required String eventId,
    required String platform,
  }) async {
    try {
      isLoading.value = true;
      print('=== Fetching Player Props ===');
      print('Event ID: $eventId, Platform: $platform');

      final url = '${Urls.baseUrl}/api/trade/sportsbook-players-data/$eventId/$platform/';
      print('URL: $url');

      final response = await http.get(Uri.parse(url));

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _playerProps.value = PlayerPropsResponse.fromJson(data);
        print('Player props loaded successfully!');
      } else {
        print('Failed to fetch player props: ${response.statusCode}');
        _playerProps.value = null;
      }
    } catch (e) {
      print('Error fetching player props: $e');
      _playerProps.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get display title for category
  String getCategoryTitle(String category) {
    switch (category) {
      case 'First_Basket':
        return 'First Basket';
      case 'First_team_basket_scorer':
        return 'First Team Basket Scorer';
      case 'To_Score_10_Plus_Points':
        return 'To Score 10+ Points';
      case 'To_Score_25_Plus_Points':
        return 'To Score 25+ Points';
      case 'Five_Plus_Made_Threes':
        return '5+ Made Threes';
      case 'To_record_10_Plus_Rebounds':
        return 'To Record 10+ Rebounds';
      case 'To_record_10_Plus_Assist':
        return 'To Record 10+ Assists';
      case 'Player_Points':
        return 'Player Points';
      case 'Player_Made_Threes':
        return 'Player Made Threes';
      case 'Player_Rebounds':
        return 'Player Rebounds';
      case 'Player_Assists':
        return 'Player Assists';
      case 'Player_pts_plus_rebound':
        return 'Player Pts + Rebound';
      case 'Player_pts_plus_ast':
        return 'Player Pts + Ast';
      case 'Player_reb_plus_ast':
        return 'Player Reb + Ast';
      case 'To_record_a_triple_double':
        return 'To Record a Triple Double';
      default:
        return category;
    }
  }

  /// Get list of categories that have data
  List<String> getAvailableCategories() {
    final props = _playerProps.value;
    if (props == null) return [];

    final categories = <String>[];
    
    if (props.firstBasket.isNotEmpty) categories.add('First_Basket');
    if (props.firstTeamBasketScorer.isNotEmpty) categories.add('First_team_basket_scorer');
    if (props.toScore10PlusPoints.isNotEmpty) categories.add('To_Score_10_Plus_Points');
    if (props.toScore25PlusPoints.isNotEmpty) categories.add('To_Score_25_Plus_Points');
    if (props.fivePlusMadeThrees.isNotEmpty) categories.add('Five_Plus_Made_Threes');
    if (props.toRecord10PlusRebounds.isNotEmpty) categories.add('To_record_10_Plus_Rebounds');
    if (props.toRecord10PlusAssist.isNotEmpty) categories.add('To_record_10_Plus_Assist');
    if (props.playerPoints.isNotEmpty) categories.add('Player_Points');
    if (props.playerMadeThrees.isNotEmpty) categories.add('Player_Made_Threes');
    if (props.playerRebounds.isNotEmpty) categories.add('Player_Rebounds');
    if (props.playerAssists.isNotEmpty) categories.add('Player_Assists');
    if (props.playerPtsPlusRebound.isNotEmpty) categories.add('Player_pts_plus_rebound');
    if (props.playerPtsPlusAst.isNotEmpty) categories.add('Player_pts_plus_ast');
    if (props.playerRebPlusAst.isNotEmpty) categories.add('Player_reb_plus_ast');
    if (props.toRecordATripleDouble.isNotEmpty) categories.add('To_record_a_triple_double');

    return categories;
  }

  /// Clear player props data
  void clearPlayerProps() {
    _playerProps.value = null;
  }
}
