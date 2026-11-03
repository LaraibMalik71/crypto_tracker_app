import 'package:flutter/material.dart';

import '../models/coin_model.dart';
import '../services/watchlist_service.dart';
import '../services/coingecko_service.dart';

import 'dart:async';

class WatchlistScreen extends StatefulWidget {
  final VoidCallback onBackToMarket;

  const WatchlistScreen({super.key, required this.onBackToMarket});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final WatchlistService _watchlistService = WatchlistService();
  final CoinGeckoService _coinGeckoService = CoinGeckoService();

  Timer? _priceUpdateTimer;

  List<Coin> _latestCoins = [];
  bool _isRefreshing = false;
  @override
  @override
  void initState() {
    super.initState();

    // Fetch the latest prices as soon as Watchlist opens.
    _refreshPrices();

    // Refresh prices every 30 seconds.
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isRefreshing) {
        _refreshPrices();
      }
    });
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPrices() async {
    if (_isRefreshing) return;

    _isRefreshing = true;

    try {
      final savedCoins = await _watchlistService.getWatchlist().first;

      if (savedCoins.isEmpty) {
        if (mounted) {
          setState(() {
            _latestCoins = [];
          });
        }
        return;
      }

      final coinIds = savedCoins.map((coin) => coin.id).toList();

      final updatedCoins = await _coinGeckoService.getCoinsByIds(coinIds);

      if (!mounted) return;

      setState(() {
        _latestCoins = updatedCoins;
      });
    } catch (e) {
      debugPrint('Watchlist price refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  static const background = Color(0xFF0B1020);
  static const cardColor = Color(0xFF171D32);
  static const accent = Color(0xFF7C6CFF);
  static const mutedText = Color(0xFF9CA5C3);
  static const positiveColor = Color(0xFF46D7A1);
  static const negativeColor = Color(0xFFFF647C);

  String _formatPrice(double price) {
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final watchlistService = WatchlistService();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onBackToMarket,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'My Watchlist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<Coin>>(
        stream: watchlistService.getWatchlist(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load your watchlist.',
                style: TextStyle(color: mutedText),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: accent),
            );
          }

          final savedCoins = snapshot.data ?? [];

          final latestCoinsById = {
            for (final coin in _latestCoins) coin.id: coin,
          };

          final coins = savedCoins.map((savedCoin) {
            return latestCoinsById[savedCoin.id] ?? savedCoin;
          }).toList();

          if (coins.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bookmark_border_rounded,
                      size: 58,
                      color: accent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your watchlist is empty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save your favorite coins to see them here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedText),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: widget.onBackToMarket,
                      child: const Text('Explore coins'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: coins.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final coin = coins[index];
              final change = coin.priceChangePercentage24h;
              final positive = change >= 0;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.network(
                        coin.image,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.currency_bitcoin, color: accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coin.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            coin.symbol.toUpperCase(),
                            style: const TextStyle(color: mutedText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatPrice(coin.currentPrice),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${positive ? '+' : ''}${change.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: positive ? positiveColor : negativeColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Remove from watchlist',
                      onPressed: () async {
                        try {
                          await watchlistService.removeCoin(coin.id);
                        } catch (_) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to remove coin.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.bookmark_remove_rounded,
                        color: negativeColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
