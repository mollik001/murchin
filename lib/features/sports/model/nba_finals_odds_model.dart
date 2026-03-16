// NBA Finals Championship Odds API Models

class NbaFinalsOddsResponse {
  final int count;
  final String? next;
  final String? previous;
  final NbaFinalsOddsResults results;

  NbaFinalsOddsResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory NbaFinalsOddsResponse.fromJson(Map<String, dynamic> json) {
    return NbaFinalsOddsResponse(
      count: json['count'] ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: NbaFinalsOddsResults.fromJson(json['results'] ?? {}),
    );
  }
}

class NbaFinalsOddsResults {
  final List<NbaFinalsOdd> odds;

  NbaFinalsOddsResults({required this.odds});

  factory NbaFinalsOddsResults.fromJson(Map<String, dynamic> json) {
    final oddsList = json['odds'] as List<dynamic>? ?? [];
    return NbaFinalsOddsResults(
      odds: oddsList.map((o) => NbaFinalsOdd.fromJson(o)).toList(),
    );
  }
}

class NbaFinalsOdd {
  final int id;
  final String bookmarkTitle;
  final String teamName;
  final String price;
  final String date;
  final String? aiPrediction;
  final bool isLoadingAi;

  NbaFinalsOdd({
    required this.id,
    required this.bookmarkTitle,
    required this.teamName,
    required this.price,
    required this.date,
    this.aiPrediction,
    this.isLoadingAi = false,
  });

  factory NbaFinalsOdd.fromJson(Map<String, dynamic> json) {
    return NbaFinalsOdd(
      id: json['id'] ?? 0,
      bookmarkTitle: json['bookmark_title'] ?? '',
      teamName: json['team_name'] ?? '',
      price: json['price'] ?? '',
      date: json['date'] ?? '',
    );
  }

  /// Create a copy with updated AI prediction
  NbaFinalsOdd copyWith({
    int? id,
    String? bookmarkTitle,
    String? teamName,
    String? price,
    String? date,
    String? aiPrediction,
    bool? isLoadingAi,
  }) {
    return NbaFinalsOdd(
      id: id ?? this.id,
      bookmarkTitle: bookmarkTitle ?? this.bookmarkTitle,
      teamName: teamName ?? this.teamName,
      price: price ?? this.price,
      date: date ?? this.date,
      aiPrediction: aiPrediction ?? this.aiPrediction,
      isLoadingAi: isLoadingAi ?? this.isLoadingAi,
    );
  }

  /// Parse price as double for comparison
  double get priceValue {
    try {
      return double.parse(price);
    } catch (e) {
      return double.infinity;
    }
  }
}
