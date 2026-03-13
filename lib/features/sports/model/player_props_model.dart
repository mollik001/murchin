// Player Props Data Models

class PlayerPropsResponse {
  final int id;
  final Map<String, dynamic> firstBasket;
  final Map<String, dynamic> firstTeamBasketScorer;
  final Map<String, dynamic> toScore10PlusPoints;
  final Map<String, dynamic> toScore25PlusPoints;
  final Map<String, dynamic> fivePlusMadeThrees;
  final Map<String, dynamic> toRecord10PlusRebounds;
  final Map<String, dynamic> toRecord10PlusAssist;
  final Map<String, dynamic> playerPoints;
  final Map<String, dynamic> playerMadeThrees;
  final Map<String, dynamic> playerRebounds;
  final Map<String, dynamic> playerAssists;
  final Map<String, dynamic> playerPtsPlusRebound;
  final Map<String, dynamic> playerPtsPlusAst;
  final Map<String, dynamic> playerRebPlusAst;
  final Map<String, dynamic> toRecordATripleDouble;
  final int bookmark;

  PlayerPropsResponse({
    required this.id,
    required this.firstBasket,
    required this.firstTeamBasketScorer,
    required this.toScore10PlusPoints,
    required this.toScore25PlusPoints,
    required this.fivePlusMadeThrees,
    required this.toRecord10PlusRebounds,
    required this.toRecord10PlusAssist,
    required this.playerPoints,
    required this.playerMadeThrees,
    required this.playerRebounds,
    required this.playerAssists,
    required this.playerPtsPlusRebound,
    required this.playerPtsPlusAst,
    required this.playerRebPlusAst,
    required this.toRecordATripleDouble,
    required this.bookmark,
  });

  factory PlayerPropsResponse.fromJson(Map<String, dynamic> json) {
    return PlayerPropsResponse(
      id: json['id'] ?? 0,
      firstBasket: json['First_Basket'] ?? {},
      firstTeamBasketScorer: json['First_team_basket_scorer'] ?? {},
      toScore10PlusPoints: json['To_Score_10_Plus_Points'] ?? {},
      toScore25PlusPoints: json['To_Score_25_Plus_Points'] ?? {},
      fivePlusMadeThrees: json['Five_Plus_Made_Threes'] ?? {},
      toRecord10PlusRebounds: json['To_record_10_Plus_Rebounds'] ?? {},
      toRecord10PlusAssist: json['To_record_10_Plus_Assist'] ?? {},
      playerPoints: json['Player_Points'] ?? {},
      playerMadeThrees: json['Player_Made_Threes'] ?? {},
      playerRebounds: json['Player_Rebounds'] ?? {},
      playerAssists: json['Player_Assists'] ?? {},
      playerPtsPlusRebound: json['Player_pts_plus_rebound'] ?? {},
      playerPtsPlusAst: json['Player_pts_plus_ast'] ?? {},
      playerRebPlusAst: json['Player_reb_plus_ast'] ?? {},
      toRecordATripleDouble: json['To_record_a_triple_double'] ?? {},
      bookmark: json['bookmark'] ?? 0,
    );
  }

  /// Get player props by category
  Map<String, dynamic> getPropsByCategory(String category) {
    switch (category) {
      case 'First_Basket':
        return firstBasket;
      case 'First_team_basket_scorer':
        return firstTeamBasketScorer;
      case 'To_Score_10_Plus_Points':
        return toScore10PlusPoints;
      case 'To_Score_25_Plus_Points':
        return toScore25PlusPoints;
      case 'Five_Plus_Made_Threes':
        return fivePlusMadeThrees;
      case 'To_record_10_Plus_Rebounds':
        return toRecord10PlusRebounds;
      case 'To_record_10_Plus_Assist':
        return toRecord10PlusAssist;
      case 'Player_Points':
        return playerPoints;
      case 'Player_Made_Threes':
        return playerMadeThrees;
      case 'Player_Rebounds':
        return playerRebounds;
      case 'Player_Assists':
        return playerAssists;
      case 'Player_pts_plus_rebound':
        return playerPtsPlusRebound;
      case 'Player_pts_plus_ast':
        return playerPtsPlusAst;
      case 'Player_reb_plus_ast':
        return playerRebPlusAst;
      case 'To_record_a_triple_double':
        return toRecordATripleDouble;
      default:
        return {};
    }
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
        return playerData['result'];
      } else if (playerData.containsKey('over') && !playerData.containsKey('under')) {
        return playerData['over'];
      }
    }
    return null;
  }

  /// Get API endpoint for category
  static String getEndpointForCategory(String category) {
    switch (category) {
      case 'First_Basket':
        return '/first-basket';
      case 'First_team_basket_scorer':
        return '/first-team-basket-scorer';
      case 'To_Score_10_Plus_Points':
        return '/to-score-10-plus';
      case 'To_Score_25_Plus_Points':
        return '/to-score-25-plus';
      case 'Five_Plus_Made_Threes':
        return '/five-plus-made-threes';
      case 'To_record_10_Plus_Rebounds':
        return '/ten-plus-rebounds';
      case 'To_record_10_Plus_Assist':
        return '/ten-plus-assists';
      case 'To_record_a_triple_double':
        return '/triple-double';
      // Type 2 - Over/Under categories
      case 'Player_Points':
        return '/player-points';
      case 'Player_Made_Threes':
        return '/player-made-threes';
      case 'Player_Rebounds':
        return '/player-rebounds';
      case 'Player_Assists':
        return '/player-assists';
      case 'Player_pts_plus_rebound':
        return '/player-pts-rebounds';
      case 'Player_pts_plus_ast':
        return '/player-pts-assists';
      case 'Player_reb_plus_ast':
        return '/player-reb-assists';
      default:
        return '/first-basket';
    }
  }

  /// Get title for API request
  static String getTitleForCategory(String category) {
    switch (category) {
      case 'First_Basket':
        return 'First Basket';
      case 'First_team_basket_scorer':
        return 'First Team Basket Scorer';
      case 'To_Score_10_Plus_Points':
        return 'To Score 10 Plus';
      case 'To_Score_25_Plus_Points':
        return 'To Score 25 Plus';
      case 'Five_Plus_Made_Threes':
        return 'Five Plus Made Threes';
      case 'To_record_10_Plus_Rebounds':
        return 'Ten Plus Rebounds';
      case 'To_record_10_Plus_Assist':
        return 'Ten Plus Assists';
      case 'To_record_a_triple_double':
        return 'Triple Double';
      // Type 2 - Over/Under categories
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
      default:
        return 'Player Props';
    }
  }

  /// Check if category is Type 2 (Over/Under)
  static bool isType2Category(String category) {
    const type2Categories = [
      'Player_Points',
      'Player_Made_Threes',
      'Player_Rebounds',
      'Player_Assists',
      'Player_pts_plus_rebound',
      'Player_pts_plus_ast',
      'Player_reb_plus_ast',
    ];
    return type2Categories.contains(category);
  }
}
