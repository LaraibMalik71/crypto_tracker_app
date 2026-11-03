import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../models/coin_model.dart';

class GainersLosersScreen extends StatelessWidget {
  final ValueListenable<List<Coin>> marketCoinsListenable;
  final bool showGainers;

  const GainersLosersScreen({
    super.key,
    required this.marketCoinsListenable,
    required this.showGainers,
  });

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF0B1020);
    const cardColor = Color(0xFF171D32);
    const positiveColor = Color(0xFF46D7A1);
    const negativeColor = Color(0xFFFF647C);
    const mutedColor = Color(0xFF9CA5C3);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(showGainers ? 'Top Gainers' : 'Top Losers'),
      ),
      body: ValueListenableBuilder<List<Coin>>(
        valueListenable: marketCoinsListenable,
        builder: (context, coins, child) {
          final rankedCoins =
              coins
                  .where(
                    (coin) => showGainers
                        ? coin.priceChangePercentage24h > 0
                        : coin.priceChangePercentage24h < 0,
                  )
                  .toList()
                ..sort(
                  (a, b) => showGainers
                      ? b.priceChangePercentage24h.compareTo(
                          a.priceChangePercentage24h,
                        )
                      : a.priceChangePercentage24h.compareTo(
                          b.priceChangePercentage24h,
                        ),
                );

          if (rankedCoins.isEmpty) {
            return const Center(
              child: Text(
                'No ranking data available yet.',
                style: TextStyle(color: mutedColor),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rankedCoins.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final coin = rankedCoins[index];
              final change = coin.priceChangePercentage24h;
              final changeColor = change >= 0 ? positiveColor : negativeColor;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: mutedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coin.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            coin.symbol.toUpperCase(),
                            style: const TextStyle(color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: changeColor,
                        fontWeight: FontWeight.bold,
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
