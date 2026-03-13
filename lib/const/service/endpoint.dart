class Urls {

  static const String baseUrl = 'https://pickfair.dsrt321.online';

  // AI Sportsbook API base URL
  static const String aiBaseUrl = 'https://abc.dsrt321.online/api/v1/sportbook';

  // AI Sportsbook API endpoint
  static const String aiSportsbookGameLinesUrl = 'https://abc.dsrt321.online/api/v1/sportbook/game-lines';

  // Kalshi API endpoint
  static const String kalshiEventListUrl = 'https://pickfair.dsrt321.online/api/trade/kalshi-event-list/';

  // Sportsbook API endpoint
  static const String sportsbookModelUrl = 'https://pickfair.dsrt321.online/api/trade/sportsbook-models/';

  // Sportsbook Search API endpoint
  static const String sportsbookSearchUrl = 'https://pickfair.dsrt321.online/api/trade/sportsbook-event-search/';

  // NBA Finals Championship Odds API endpoint
  static String nbaFinalsOddsUrl(String platform) =>
      'https://pickfair.dsrt321.online/api/trade/nba-final-championship-odds/?bookmark=$platform';
}