// Sportsbook API Models

class SportsbookResponse {
  final int count;
  final String? next;
  final String? previous;
  final SportsbookResults results;

  SportsbookResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory SportsbookResponse.fromJson(Map<String, dynamic> json) {
    return SportsbookResponse(
      count: json['count'] ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: SportsbookResults.fromJson(json['results'] ?? {}),
    );
  }
}

class SportsbookResults {
  final List<SportsbookEvent> events;

  SportsbookResults({required this.events});

  factory SportsbookResults.fromJson(Map<String, dynamic> json) {
    final eventsList = json['events'] as List<dynamic>? ?? [];
    return SportsbookResults(
      events: eventsList.map((e) => SportsbookEvent.fromJson(e)).toList(),
    );
  }
}

class SportsbookEvent {
  final String eventId;
  final List<Bookmark> bookmark;
  final String date;
  final String homeTeam;
  final String awayTeam;
  final String? aiPercentage;
  final String? aiExplanation;
  final List<String>? optionTitles;
  final List<double>? marketProbs;
  final List<double>? aiPercentages;

  SportsbookEvent({
    required this.eventId,
    required this.bookmark,
    required this.date,
    required this.homeTeam,
    required this.awayTeam,
    this.aiPercentage,
    this.aiExplanation,
    this.optionTitles,
    this.marketProbs,
    this.aiPercentages,
  });

  factory SportsbookEvent.fromJson(Map<String, dynamic> json) {
    final bookmarkList = json['bookmark'] as List<dynamic>? ?? [];
    return SportsbookEvent(
      eventId: json['event_id'] ?? '',
      bookmark: bookmarkList.map((b) => Bookmark.fromJson(b)).toList(),
      date: json['date'] ?? '',
      homeTeam: json['home_team'] ?? '',
      awayTeam: json['away_team'] ?? '',
      aiPercentage: json['ai_percentage'] as String?,
      aiExplanation: json['ai_explanation'] as String?,
      optionTitles: json['option_titles'] != null ? List<String>.from(json['option_titles']) : null,
      marketProbs: json['market_probs'] != null ? List<double>.from(json['market_probs']) : null,
      aiPercentages: json['ai_percentages'] != null ? List<double>.from(json['ai_percentages']) : null,
    );
  }

  SportsbookEvent copyWith({
    String? eventId,
    List<Bookmark>? bookmark,
    String? date,
    String? homeTeam,
    String? awayTeam,
    String? aiPercentage,
    String? aiExplanation,
    List<String>? optionTitles,
    List<double>? marketProbs,
    List<double>? aiPercentages,
  }) {
    return SportsbookEvent(
      eventId: eventId ?? this.eventId,
      bookmark: bookmark ?? this.bookmark,
      date: date ?? this.date,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      aiPercentage: aiPercentage ?? this.aiPercentage,
      aiExplanation: aiExplanation ?? this.aiExplanation,
      optionTitles: optionTitles ?? this.optionTitles,
      marketProbs: marketProbs ?? this.marketProbs,
      aiPercentages: aiPercentages ?? this.aiPercentages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'bookmark': bookmark.map((b) => b.toJson()).toList(),
      'date': date,
      'home_team': homeTeam,
      'away_team': awayTeam,
      'ai_percentage': aiPercentage,
      'ai_explanation': aiExplanation,
      'option_titles': optionTitles,
      'market_probs': marketProbs,
      'ai_percentages': aiPercentages,
    };
  }
}

class Bookmark {
  final int id;
  final List<Market> market;
  final String marketTitle;
  final String link;
  final String event;
  final String? aiSpreadAway;
  final String? aiSpreadHome;
  final String? aiMoneylineAway;
  final String? aiMoneylineHome;
  final String? aiTotalOver;
  final String? aiTotalUnder;

  Bookmark({
    required this.id,
    required this.market,
    required this.marketTitle,
    required this.link,
    required this.event,
    this.aiSpreadAway,
    this.aiSpreadHome,
    this.aiMoneylineAway,
    this.aiMoneylineHome,
    this.aiTotalOver,
    this.aiTotalUnder,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final marketList = json['market'] as List<dynamic>? ?? [];
    return Bookmark(
      id: json['id'] ?? 0,
      market: marketList.map((m) => Market.fromJson(m)).toList(),
      marketTitle: json['market_title'] ?? '',
      link: json['link'] ?? '',
      event: json['event'] ?? '',
      aiSpreadAway: json['ai_spread_away'] as String?,
      aiSpreadHome: json['ai_spread_home'] as String?,
      aiMoneylineAway: json['ai_moneyline_away'] as String?,
      aiMoneylineHome: json['ai_moneyline_home'] as String?,
      aiTotalOver: json['ai_total_over'] as String?,
      aiTotalUnder: json['ai_total_under'] as String?,
    );
  }

  Bookmark copyWith({
    int? id,
    List<Market>? market,
    String? marketTitle,
    String? link,
    String? event,
    String? aiSpreadAway,
    String? aiSpreadHome,
    String? aiMoneylineAway,
    String? aiMoneylineHome,
    String? aiTotalOver,
    String? aiTotalUnder,
  }) {
    return Bookmark(
      id: id ?? this.id,
      market: market ?? this.market,
      marketTitle: marketTitle ?? this.marketTitle,
      link: link ?? this.link,
      event: event ?? this.event,
      aiSpreadAway: aiSpreadAway ?? this.aiSpreadAway,
      aiSpreadHome: aiSpreadHome ?? this.aiSpreadHome,
      aiMoneylineAway: aiMoneylineAway ?? this.aiMoneylineAway,
      aiMoneylineHome: aiMoneylineHome ?? this.aiMoneylineHome,
      aiTotalOver: aiTotalOver ?? this.aiTotalOver,
      aiTotalUnder: aiTotalUnder ?? this.aiTotalUnder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'market': market.map((m) => m.toJson()).toList(),
      'market_title': marketTitle,
      'link': link,
      'event': event,
      'ai_spread_away': aiSpreadAway,
      'ai_spread_home': aiSpreadHome,
      'ai_moneyline_away': aiMoneylineAway,
      'ai_moneyline_home': aiMoneylineHome,
      'ai_total_over': aiTotalOver,
      'ai_total_under': aiTotalUnder,
    };
  }
}

class Market {
  final int id;
  final String key;
  final MarketOutcome outcome;
  final int bookmark;

  Market({
    required this.id,
    required this.key,
    required this.outcome,
    required this.bookmark,
  });

  factory Market.fromJson(Map<String, dynamic> json) {
    return Market(
      id: json['id'] ?? 0,
      key: json['key'] ?? '',
      outcome: MarketOutcome.fromJson(json['outcome'] ?? {}),
      bookmark: json['bookmark'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'outcome': outcome.toJson(),
      'bookmark': bookmark,
    };
  }
}

class MarketOutcome {
  final TeamOdds? awayTeam;
  final TeamOdds? homeTeam;
  final TotalOdds? over;
  final TotalOdds? under;

  MarketOutcome({
    this.awayTeam,
    this.homeTeam,
    this.over,
    this.under,
  });

  factory MarketOutcome.fromJson(Map<String, dynamic> json) {
    return MarketOutcome(
      awayTeam: json['away_team'] != null ? TeamOdds.fromJson(json['away_team']) : null,
      homeTeam: json['home_team'] != null ? TeamOdds.fromJson(json['home_team']) : null,
      over: json['over'] != null ? TotalOdds.fromJson(json['over']) : null,
      under: json['under'] != null ? TotalOdds.fromJson(json['under']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'away_team': awayTeam?.toJson(),
      'home_team': homeTeam?.toJson(),
      'over': over?.toJson(),
      'under': under?.toJson(),
    };
  }
}

class TeamOdds {
  final String american;

  TeamOdds({required this.american});

  factory TeamOdds.fromJson(Map<String, dynamic> json) {
    return TeamOdds(
      american: json['american'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'american': american,
    };
  }
}

class TotalOdds {
  final double point;
  final String american;

  TotalOdds({required this.point, required this.american});

  factory TotalOdds.fromJson(Map<String, dynamic> json) {
    return TotalOdds(
      point: (json['point'] ?? 0).toDouble(),
      american: json['american'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'point': point,
      'american': american,
    };
  }
}
