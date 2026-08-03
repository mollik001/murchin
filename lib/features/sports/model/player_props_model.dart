// Player Props Data Models
import 'package:get/get.dart';

class PlayerPropsResponse {
  final int id;
  final Map<String, Map<String, dynamic>> props;
  final int bookmark;

  PlayerPropsResponse({
    required this.id,
    required this.props,
    required this.bookmark,
  });

  factory PlayerPropsResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, Map<String, dynamic>> propsMap = {};
    
    // NBA Categories
    const nbaCategories = [
      'First_Basket', 'First_team_basket_scorer', 'To_Score_10_Plus_Points',
      'To_Score_25_Plus_Points', 'Five_Plus_Made_Threes', 'To_record_10_Plus_Rebounds',
      'To_record_10_Plus_Assist', 'Player_Points', 'Player_Made_Threes',
      'Player_Rebounds', 'Player_Assists', 'Player_pts_plus_rebound',
      'Player_pts_plus_ast', 'Player_reb_plus_ast', 'To_record_a_triple_double'
    ];

    // MLB Categories
    const mlbCategories = [
      'batter_home_runs', 'batter_hits', 'batter_strikeouts', 'batter_singles',
      'batter_doubles', 'batter_triples', 'totals_1st_1_innings', 'totals_1st_5_innings',
      'batter_runs_scored', 'batter_hits_runs_rbis', 'batter_rbis', 'batter_stolen_bases',
      'pitcher_strikeouts', 'pitcher_outs', 'pitcher_earned_runs', 'pitcher_hits_allowed'
    ];

    for (var cat in [...nbaCategories, ...mlbCategories]) {
      if (json.containsKey(cat) && json[cat] is Map) {
        propsMap[cat] = Map<String, dynamic>.from(json[cat]);
      }
    }

    return PlayerPropsResponse(
      id: json['id'] ?? 0,
      props: propsMap,
      bookmark: json['bookmark'] ?? 0,
    );
  }

  /// Get player props by category
  Map<String, dynamic> getPropsByCategory(String category) {
    return props[category] ?? {};
  }

  /// Check if player data has both over and under
  static bool hasOverUnder(dynamic playerData) {
    if (playerData is Map) {
      return playerData.containsKey('over') && playerData.containsKey('under');
    }
    return false;
  }

  /// Get sportsbook value (result or over only)
  static String? getSportsbookValue(dynamic playerData) {
    if (playerData is Map) {
      if (playerData.containsKey('result')) {
        return playerData['result']?.toString();
      } else if (playerData.containsKey('over') && !playerData.containsKey('under')) {
        return playerData['over']?.toString();
      }
    }
    return null;
  }

  /// Get API endpoint for category
  static String getEndpointForCategory(String category, {bool isMlb = false}) {
    if (isMlb) {
      // MLB endpoints use hyphens
      String slug = category.replaceAll('_', '-');
      // Special cases for MLB inning totals as per doc
      if (slug == 'totals-1st-1-innings') return '/totals-1st-inning';
      return '/$slug';
    }
    
    switch (category) {
      case 'First_Basket': return '/first-basket';
      case 'First_team_basket_scorer': return '/first-team-basket-scorer';
      case 'To_Score_10_Plus_Points': return '/to-score-10-plus';
      case 'To_Score_25_Plus_Points': return '/to-score-25-plus';
      case 'Five_Plus_Made_Threes': return '/five-plus-made-threes';
      case 'To_record_10_Plus_Rebounds': return '/ten-plus-rebounds';
      case 'To_record_10_Plus_Assist': return '/ten-plus-assists';
      case 'To_record_a_triple_double': return '/triple-double';
      case 'Player_Points': return '/player-points';
      case 'Player_Made_Threes': return '/player-made-threes';
      case 'Player_Rebounds': return '/player-rebounds';
      case 'Player_Assists': return '/player-assists';
      case 'Player_pts_plus_rebound': return '/player-pts-rebounds';
      case 'Player_pts_plus_ast': return '/player-pts-assists';
      case 'Player_reb_plus_ast': return '/player-reb-assists';
      default: return '/first-basket';
    }
  }

  /// Get title for API request
  static String getTitleForCategory(String category, {bool isMlb = false}) {
    if (isMlb) {
      return category.replaceAll('_', ' ').split(' ').map((s) => s.capitalizeFirst).join(' ');
    }
    switch (category) {
      case 'First_Basket': return 'First Basket';
      case 'First_team_basket_scorer': return 'First Team Basket Scorer';
      case 'To_Score_10_Plus_Points': return 'To Score 10 Plus';
      case 'To_Score_25_Plus_Points': return 'To Score 25 Plus';
      case 'Five_Plus_Made_Threes': return 'Five Plus Made Threes';
      case 'To_record_10_Plus_Rebounds': return 'Ten Plus Rebounds';
      case 'To_record_10_Plus_Assist': return 'Ten Plus Assists';
      case 'To_record_a_triple_double': return 'Triple Double';
      case 'Player_Points': return 'Player Points';
      case 'Player_Made_Threes': return 'Player Made Threes';
      case 'Player_Rebounds': return 'Player Rebounds';
      case 'Player_Assists': return 'Player Assists';
      case 'Player_pts_plus_rebound': return 'Player Pts + Rebound';
      case 'Player_pts_plus_ast': return 'Player Pts + Ast';
      case 'Player_reb_plus_ast': return 'Player Reb + Ast';
      default: return category.replaceAll('_', ' ').toUpperCase();
    }
  }
}
