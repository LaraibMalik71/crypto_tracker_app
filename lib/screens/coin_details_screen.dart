import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

import '../models/coin_model.dart';
import 'coin_market_chart.dart';
import '../services/coingecko_service.dart';

class CoinDetailsScreen extends StatelessWidget {
  final Coin coin;
  final ValueListenable<List<Coin>> marketCoinsListenable;

  const CoinDetailsScreen({
    super.key,
    required this.coin,
    required this.marketCoinsListenable,
  });

  String _formatPrice(double price) {
    if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    }
    return '\$${price.toStringAsFixed(6)}';
  }

  String _formatLargeNumber(double value) {
    if (value >= 1e12) {
      return '\$${(value / 1e12).toStringAsFixed(2)}T';
    }
    if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(2)}B';
    }
    if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(2)}M';
    }
    if (value >= 1e3) {
      return '\$${(value / 1e3).toStringAsFixed(2)}K';
    }
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatSupply(double value) {
    if (value >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(2)}T';
    }
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)}B';
    }
    if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)}M';
    }
    if (value >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B1020);
    const cardColor = Color(0xFF171D32);
    const accent = Color(0xFFB4A7FF);
    const mutedText = Color(0xFF9CA5C3);

    return ValueListenableBuilder<List<Coin>>(
      valueListenable: marketCoinsListenable,
      builder: (context, coins, child) {
        final updatedCoins = coins.where((item) => item.id == coin.id);

        final currentCoin = updatedCoins.isNotEmpty ? updatedCoins.first : coin;

        final change = currentCoin.priceChangePercentage24h;
        final isPositive = change >= 0;

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            title: Text(currentCoin.name),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      ClipOval(
                        child: Image.network(
                          currentCoin.image,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.currency_bitcoin,
                            size: 76,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${currentCoin.name} '
                        '(${currentCoin.symbol.toUpperCase()})',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatPrice(currentCoin.currentPrice),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isPositive
                              ? const Color(0xFF163D35)
                              : const Color(0xFF452532),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${isPositive ? '+' : ''}'
                          '${change.toStringAsFixed(2)}% (24h)',
                          style: TextStyle(
                            color: isPositive
                                ? const Color(0xFF46D7A1)
                                : const Color(0xFFFF647C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Market Statistics',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _statCard(
                  title: 'Market Capitalization',
                  value: _formatLargeNumber(currentCoin.marketCap),
                  cardColor: cardColor,
                  mutedText: mutedText,
                  accent: accent,
                ),
                const SizedBox(height: 12),
                _statCard(
                  title: 'Current Price',
                  value: _formatPrice(currentCoin.currentPrice),
                  cardColor: cardColor,
                  mutedText: mutedText,
                  accent: accent,
                ),
                const SizedBox(height: 12),
                _statCard(
                  title: '24-Hour Change',
                  value:
                      '${currentCoin.priceChangePercentage24h >= 0 ? '+' : ''}'
                      '${currentCoin.priceChangePercentage24h.toStringAsFixed(2)}%',
                  cardColor: cardColor,
                  mutedText: mutedText,
                  accent: accent,
                ),
                const SizedBox(height: 12),
                _statCard(
                  title: '24-Hour High',
                  value: _formatPrice(currentCoin.high24h),
                  cardColor: cardColor,
                  mutedText: mutedText,
                  accent: accent,
                ),
                const SizedBox(height: 12),
                _statCard(
                  title: '24-Hour Low',
                  value: _formatPrice(currentCoin.low24h),
                  cardColor: cardColor,
                  mutedText: mutedText,
                  accent: accent,
                ),
                const SizedBox(height: 12),
                _statCard(
                  title: 'Circulating Supply',
                  value:
                      '${_formatSupply(currentCoin.circulatingSupply)} '
                      '${currentCoin.symbol.toUpperCase()}',
                  cardColor: cardColor,
                  mutedText: mutedText,
                  accent: accent,
                ),
                const SizedBox(height: 32),
                CoinMarketChart(coinId: currentCoin.id),
                const SizedBox(height: 32),
                _AboutCoinSection(coinId: currentCoin.id),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: accent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Prices and market statistics are supplied by CoinGecko and may change frequently.',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required Color cardColor,
    required Color mutedText,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: mutedText, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutCoinSection extends StatefulWidget {
  final String coinId;

  const _AboutCoinSection({required this.coinId});

  @override
  State<_AboutCoinSection> createState() => _AboutCoinSectionState();
}

class _AboutCoinSectionState extends State<_AboutCoinSection> {
  final CoinGeckoService _service = CoinGeckoService();

  late Future<String> _descriptionFuture;

  @override
  void initState() {
    super.initState();
    _descriptionFuture = _service.getCoinDescription(widget.coinId);
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF171D32);
    const accent = Color(0xFFB4A7FF);
    const mutedText = Color(0xFF9CA5C3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: FutureBuilder<String>(
            future: _descriptionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: accent),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  'Unable to load coin description. Please try again later.',
                  style: TextStyle(color: mutedText, height: 1.5),
                );
              }

              final description = snapshot.data ?? '';

              if (description.isEmpty) {
                return const Text(
                  'No description is available for this cryptocurrency.',
                  style: TextStyle(color: mutedText, height: 1.5),
                );
              }

              return Text(
                description,
                style: const TextStyle(
                  color: mutedText,
                  fontSize: 14,
                  height: 1.6,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
