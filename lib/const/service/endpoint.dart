class Urls {

  static const String baseUrl = 'https://api.pickfair.ai';

  // AI Sportsbook API base URL
  static const String aiBaseUrl = 'https://ai.pickfair.ai/api/v1/sportbook';

  // AI Sportsbook API endpoint
  static const String aiSportsbookGameLinesUrl = 'https://ai.pickfair.ai/api/v1/sportbook/game-lines';

  // MLB AI Game Lines endpoint
  static const String mlbAiGameLinesUrl = 'https://ai.pickfair.ai/api/v1/mlb/game-lines';

  // Kalshi API endpoint
  static const String kalshiEventListUrl = 'https://api.pickfair.ai/api/trade/kalshi-event-list/';

  // Sportsbook API endpoint
  static const String sportsbookModelUrl = 'https://api.pickfair.ai/api/trade/sportsbook-models/';

  // MLB Sportsbook API endpoint
  static const String mlbSportsbookModelUrl = 'https://api.pickfair.ai/api/trade/mlb-sportsbook-models-lists/';

  // Sportsbook Search API endpoint
  static const String sportsbookSearchUrl = 'https://api.pickfair.ai/api/trade/sportsbook-event-search/';

  // NBA Finals Championship Odds API endpoint
  static String nbaFinalsOddsUrl(String platform) =>
      'https://api.pickfair.ai/api/trade/nba-final-championship-odds/?bookmark=$platform';
}