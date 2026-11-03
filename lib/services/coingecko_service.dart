import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/coin_model.dart';

import 'package:flutter/foundation.dart';

class CoinGeckoService {
  static const String _baseUrl = "https://api.coingecko.com/api/v3";

  // Existing method: loads the top 20 coins for the dashboard.
  Future<List<Coin>> getMarketCoins() async {
    final url = Uri.parse(
      "$_baseUrl/coins/markets"
      "?vs_currency=usd"
      "&order=market_cap_desc"
      "&per_page=20"
      "&page=1"
      "&sparkline=false",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((coin) => Coin.fromJson(coin)).toList();
    } else {
      throw Exception("Failed to load cryptocurrency data.");
    }
  }

  // Fetches global cryptocurrency market statistics.
  Future<Map<String, dynamic>> getGlobalMarketData() async {
    final url = Uri.parse('$_baseUrl/global');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      return responseData['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load global market data.');
    }
  }

  // Fetches currently trending cryptocurrencies from CoinGecko.
  Future<List<Coin>> getTrendingCoins() async {
    final trendingUrl = Uri.parse('$_baseUrl/search/trending');

    final trendingResponse = await http.get(trendingUrl);

    if (trendingResponse.statusCode != 200) {
      throw Exception('Failed to load trending cryptocurrencies.');
    }

    final Map<String, dynamic> trendingData = jsonDecode(trendingResponse.body);

    final List<dynamic> trendingResults = trendingData['coins'] ?? [];

    if (trendingResults.isEmpty) {
      return [];
    }

    final List<String> coinIds = trendingResults
        .map((item) => item['item']['id'] as String)
        .toList();

    final marketUrl = Uri.https('api.coingecko.com', '/api/v3/coins/markets', {
      'vs_currency': 'usd',
      'ids': coinIds.join(','),
      'sparkline': 'false',
    });

    final marketResponse = await http.get(marketUrl);

    if (marketResponse.statusCode != 200) {
      throw Exception('Failed to load trending coin market data.');
    }

    final List<dynamic> marketData = jsonDecode(marketResponse.body);

    return marketData.map((coin) => Coin.fromJson(coin)).toList();
  }

  // New method: searches for coins by name or symbol.
  Future<List<Coin>> searchCoins(String query) async {
    final searchUrl = Uri.https('api.coingecko.com', '/api/v3/search', {
      'query': query,
    });

    final searchResponse = await http.get(searchUrl);

    if (searchResponse.statusCode != 200) {
      debugPrint('CoinGecko search API status: ${searchResponse.statusCode}');
      debugPrint('Response: ${searchResponse.body}');
      throw Exception("Failed to search cryptocurrencies.");
    }

    final Map<String, dynamic> searchData = jsonDecode(searchResponse.body);

    final List<dynamic> searchResults = searchData['coins'] ?? [];

    if (searchResults.isEmpty) {
      return [];
    }

    // Use the IDs returned by CoinGecko to fetch current market data.
    final List<String> coinIds = searchResults
        .take(20)
        .map((coin) => coin['id'] as String)
        .toList();

    final marketUrl = Uri.https('api.coingecko.com', '/api/v3/coins/markets', {
      'vs_currency': 'usd',
      'ids': coinIds.join(','),
      'per_page': '20',
      'page': '1',
      'sparkline': 'false',
    });

    final marketResponse = await http.get(marketUrl);

    if (marketResponse.statusCode != 200) {
      throw Exception("Failed to load search results.");
    }

    final List<dynamic> marketData = jsonDecode(marketResponse.body);

    return marketData.map((coin) => Coin.fromJson(coin)).toList();
  }

  // Fetches the latest market data for specific coin IDs.
  Future<List<Coin>> getCoinsByIds(List<String> coinIds) async {
    if (coinIds.isEmpty) {
      return [];
    }

    final url = Uri.https('api.coingecko.com', '/api/v3/coins/markets', {
      'vs_currency': 'usd',
      'ids': coinIds.join(','),
      'sparkline': 'false',
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((coin) => Coin.fromJson(coin)).toList();
    } else {
      throw Exception('Failed to refresh watchlist prices.');
    }
  }

  // Fetches historical price and trading-volume data for a coin.

  Future<Map<String, dynamic>> getCoinMarketChart(
    String coinId, {
    int days = 7,
  }) async {
    final url = Uri.https(
      'api.coingecko.com',
      '/api/v3/coins/$coinId/market_chart',
      {'vs_currency': 'usd', 'days': '$days'},
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to load historical data for $coinId. '
        'Status code: ${response.statusCode}',
      );
    }
  }

  // Fetches the description of an individual cryptocurrency.
  Future<String> getCoinDescription(String coinId) async {
    final url = Uri.https('api.coingecko.com', '/api/v3/coins/$coinId', {
      'localization': 'false',
      'tickers': 'false',
      'market_data': 'false',
      'community_data': 'false',
      'developer_data': 'false',
      'sparkline': 'false',
    });

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final description = data['description']?['en'] ?? '';

      return description.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    } else {
      throw Exception('Failed to load coin description.');
    }
  }
}
