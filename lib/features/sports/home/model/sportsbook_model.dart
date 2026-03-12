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
      aiPercentage: null,
      aiExplanation: null,
      optionTitles: null,
      marketProbs: null,
      aiPercentages: null,
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
      aiSpreadAway: null,
      aiSpreadHome: null,
      aiMoneylineAway: null,
      aiMoneylineHome: null,
      aiTotalOver: null,
      aiTotalUnder: null,
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
}

class TeamOdds {
  final String american;

  TeamOdds({required this.american});

  factory TeamOdds.fromJson(Map<String, dynamic> json) {
    return TeamOdds(
      american: json['american'] ?? '',
    );
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
}
