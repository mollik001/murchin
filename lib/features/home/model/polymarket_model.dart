class PolymarketEventResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<Event> events;

  PolymarketEventResponse({
    required this.count,
    required this.next,
    required this.previous,
    required this.events,
  });

  factory PolymarketEventResponse.fromJson(Map<String, dynamic> json) {
    return PolymarketEventResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      events: (json['results']['events'] as List)
          .map((e) => Event.fromJson(e))
          .toList(),
    );
  }
}

class Event {
  final int eventId;
  final String title;
  final String endDate;
  final List<QuestionOutcome> outcomes;

  Event({
    required this.eventId,
    required this.title,
    required this.endDate,
    required this.outcomes,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'],
      title: json['title'],
      endDate: json['end_date'],
      outcomes: (json['question_outcome'] as List)
          .map((e) => QuestionOutcome.fromJson(e))
          .toList(),
    );
  }

  /// 🔥 Highest probability outcome
  QuestionOutcome? get highestOutcome {
    if (outcomes.isEmpty) return null;
    outcomes.sort((a, b) =>
        double.parse(b.probability).compareTo(double.parse(a.probability)));
    return outcomes.first;
  }
}

class QuestionOutcome {
  final String title;
  final String probability;

  QuestionOutcome({
    required this.title,
    required this.probability,
  });

  factory QuestionOutcome.fromJson(Map<String, dynamic> json) {
    return QuestionOutcome(
      title: json['group_item_title'],
      probability: json['probability'],
    );
  }
}
