import 'package:flutter/material.dart';

import '../models/coin_model.dart';
import '../services/coingecko_service.dart';
import '../services/watchlist_service.dart';
import 'search_screen.dart';
import "watchlist_screen.dart";
import 'coin_details_screen.dart';
import 'gainers_losers_screen.dart';
import 'profile_screen.dart';

import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CoinGeckoService _coinGeckoService = CoinGeckoService();
  final WatchlistService _watchlistService = WatchlistService();
  late Future<List<Coin>> _coinsFuture;
  late Future<List<Coin>> _trendingCoinsFuture;
  late Future<Map<String, dynamic>> _globalMarketFuture;
  int _selectedIndex = 0;
  Timer? _priceUpdateTimer;
  Timer? _globalMarketUpdateTimer;
  final ValueNotifier<List<Coin>> _marketCoinsNotifier =
      ValueNotifier<List<Coin>>([]);

  @override
  void initState() {
    super.initState();

    _loadCoins();
    _loadTrendingCoins();
    _loadGlobalMarketData();

    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted || _selectedIndex != 0) return;

      setState(() {
        _loadCoins();
      });
    });
    _globalMarketUpdateTimer = Timer.periodic(const Duration(minutes: 5), (
      timer,
    ) {
      if (!mounted || _selectedIndex != 0) return;

      setState(() {
        _loadGlobalMarketData();
      });
    });
  }

  void _loadCoins() {
    _coinsFuture = _coinGeckoService.getMarketCoins().then((coins) {
      if (mounted) {
        _marketCoinsNotifier.value = coins;
      }
      return coins;
    });
  }

  void _loadTrendingCoins() {
    _trendingCoinsFuture = _coinGeckoService.getTrendingCoins();
  }

  void _loadGlobalMarketData() {
    _globalMarketFuture = _coinGeckoService.getGlobalMarketData();
  }

  Future<void> _refreshCoins() async {
    setState(() {
      _loadCoins();
      _loadGlobalMarketData();
    });

    await Future.wait([
      _coinsFuture.then((_) {}),
      _globalMarketFuture.then((_) {}),
    ]);
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${price.toStringAsFixed(2)}';
    }
    if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    }
    return '\$${price.toStringAsFixed(4)}';
  }

  String _formatMarketCap(double value) {
    if (value >= 1e12) {
      return '\$${(value / 1e12).toStringAsFixed(2)}T';
    }
    if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(2)}B';
    }
    if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(2)}M';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    _globalMarketUpdateTimer?.cancel();
    _marketCoinsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0B1020);
    const cardColor = Color(0xFF171D32);
    const accent = Color(0xFF7C6CFF);
    const mutedText = Color(0xFF9CA5C3);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Row(
          children: [
            Icon(Icons.currency_bitcoin, color: Color(0xFFB4A7FF)),
            SizedBox(width: 8),
            Text(
              'Crypto Tracker',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: _selectedIndex == 1
          ? WatchlistScreen(
              onBackToMarket: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
            )
          : FutureBuilder<List<Coin>>(
              future: _coinsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: accent),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 56,
                            color: mutedText,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to load market data',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check your internet connection and try again. '
                            'The API may also be temporarily rate-limited.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: mutedText),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () {
                              setState(_loadCoins);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final coins = snapshot.data ?? [];

                return RefreshIndicator(
                  color: accent,
                  onRefresh: _refreshCoins,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Market Overview',
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Explore the cryptocurrency market',
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              tooltip: 'Search cryptocurrencies',
                              icon: const Icon(
                                Icons.search,
                                color: Color(0xFFB4A7FF),
                                size: 26,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SearchScreen(
                                      marketCoinsListenable:
                                          _marketCoinsNotifier,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _globalMarketSection(),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF37316B), Color(0xFF171D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.insights,
                              color: Color(0xFFB4A7FF),
                              size: 30,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Crypto Market',
                              style: TextStyle(color: mutedText, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${coins.length} cryptocurrencies',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Market prices in USD',
                              style: TextStyle(color: mutedText),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Trending Cryptocurrencies',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _trendingCoinsSection(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _rankingCard(
                              title: 'Top Gainers',
                              subtitle: 'Biggest 24h rises',
                              icon: Icons.trending_up,
                              color: const Color(0xFF46D7A1),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GainersLosersScreen(
                                      marketCoinsListenable:
                                          _marketCoinsNotifier,
                                      showGainers: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _rankingCard(
                              title: 'Top Losers',
                              subtitle: 'Biggest 24h drops',
                              icon: Icons.trending_down,
                              color: const Color(0xFFFF647C),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => GainersLosersScreen(
                                      marketCoinsListenable:
                                          _marketCoinsNotifier,
                                      showGainers: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Top Cryptocurrencies',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...coins.asMap().entries.map((entry) {
                        {
                          final index = entry.key;
                          final coin = entry.value;
                          final change = coin.priceChangePercentage24h;
                          final isPositive = change >= 0;

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CoinDetailsScreen(
                                    coin: coin,
                                    marketCoinsListenable: _marketCoinsNotifier,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: mutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ClipOval(
                                    child: Image.network(
                                      coin.image,
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const SizedBox(
                                        width: 42,
                                        height: 42,
                                        child: Icon(
                                          Icons.currency_bitcoin,
                                          color: Color(0xFFB4A7FF),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          coin.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          coin.symbol.toUpperCase(),
                                          style: const TextStyle(
                                            color: mutedText,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cap ${_formatMarketCap(coin.marketCap)}',
                                          style: const TextStyle(
                                            color: mutedText,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatPrice(coin.currentPrice),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPositive
                                                  ? const Color(0xFF163D35)
                                                  : const Color(0xFF452532),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${isPositive ? '+' : ''}'
                                              '${change.toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                color: isPositive
                                                    ? const Color(0xFF46D7A1)
                                                    : const Color(0xFFFF647C),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        tooltip: 'Save to watchlist',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);

                                          try {
                                            final wasAdded =
                                                await _watchlistService.addCoin(
                                                  coin,
                                                );

                                            if (!mounted) return;

                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  wasAdded
                                                      ? '${coin.name} added to your watchlist'
                                                      : '${coin.name} is already in your watchlist',
                                                ),
                                                duration: const Duration(
                                                  seconds: 2,
                                                ),
                                              ),
                                            );
                                          } catch (_) {
                                            if (!mounted) return;

                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Unable to save coin. Please try again.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.bookmark_add_outlined,
                                          color: Color(0xFFB4A7FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }),
                      const SizedBox(height: 12),
                      const Text(
                        'Market data provided by CoinGecko. '
                        'Prices can change frequently.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: mutedText, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF171D32),
        selectedItemColor: const Color(0xFFB4A7FF),
        unselectedItemColor: const Color(0xFF9CA5C3),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border_rounded),
            label: 'Watchlist',
          ),
        ],
      ),
    );
  }

  Widget _globalMarketSection() {
    const cardColor = Color(0xFF171D32);
    const mutedText = Color(0xFF9CA5C3);
    const positiveColor = Color(0xFF46D7A1);
    const negativeColor = Color(0xFFFF647C);
    const accent = Color(0xFFB4A7FF);

    return FutureBuilder<Map<String, dynamic>>(
      future: _globalMarketFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: accent),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Unable to load global market statistics.',
                    style: TextStyle(color: mutedText),
                  ),
                ),
                IconButton(
                  tooltip: 'Retry',
                  onPressed: () {
                    setState(_loadGlobalMarketData);
                  },
                  icon: const Icon(Icons.refresh, color: accent),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;

        final marketCap = (data['total_market_cap']?['usd'] ?? 0) as num;

        final tradingVolume = (data['total_volume']?['usd'] ?? 0) as num;

        final marketChange =
            (data['market_cap_change_percentage_24h'] ?? 0) as num;

        final activeCoins = (data['active_cryptocurrencies'] ?? 0) as num;

        final changeColor = marketChange >= 0 ? positiveColor : negativeColor;

        Widget statCard({
          required String title,
          required String value,
          String? subtitle,
          Color subtitleColor = mutedText,
        }) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: mutedText, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            statCard(
              title: 'Global Market Cap',
              value: _formatMarketCap(marketCap.toDouble()),
              subtitle: 'Entire market value',
            ),
            statCard(
              title: '24h Trading Volume',
              value: _formatMarketCap(tradingVolume.toDouble()),
              subtitle: 'Global volume',
            ),
            statCard(
              title: '24h Market Change',
              value:
                  '${marketChange >= 0 ? '+' : ''}'
                  '${marketChange.toStringAsFixed(2)}%',
              subtitle: 'Overall market movement',
              subtitleColor: changeColor,
            ),
            statCard(
              title: 'Active Cryptocurrencies',
              value: activeCoins.toStringAsFixed(0),
              subtitle: 'Tracked globally',
            ),
          ],
        );
      },
    );
  }

  Widget _trendingCoinsSection() {
    const cardColor = Color(0xFF171D32);
    const mutedText = Color(0xFF9CA5C3);
    const accent = Color(0xFFB4A7FF);

    return FutureBuilder<List<Coin>>(
      future: _trendingCoinsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: accent),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            'Unable to load trending cryptocurrencies.',
            style: TextStyle(color: mutedText),
          );
        }

        final trendingCoins = snapshot.data ?? [];

        if (trendingCoins.isEmpty) {
          return const Text(
            'No trending cryptocurrencies available.',
            style: TextStyle(color: mutedText),
          );
        }

        return SizedBox(
          height: 165,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trendingCoins.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final coin = trendingCoins[index];
              final change = coin.priceChangePercentage24h;
              final isPositive = change >= 0;

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CoinDetailsScreen(
                        coin: coin,
                        marketCoinsListenable: _marketCoinsNotifier,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 145,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipOval(
                            child: Image.network(
                              coin.image,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.currency_bitcoin,
                                color: accent,
                                size: 32,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.trending_up,
                            color: accent,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        coin.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        coin.symbol.toUpperCase(),
                        style: const TextStyle(color: mutedText, fontSize: 11),
                      ),
                      const Spacer(),
                      Text(
                        _formatPrice(coin.currentPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive
                              ? const Color(0xFF46D7A1)
                              : const Color(0xFFFF647C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _rankingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF171D32),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF9CA5C3), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
