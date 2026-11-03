import 'package:flutter/material.dart';

import '../models/coin_model.dart';
import '../services/coingecko_service.dart';
import '../services/watchlist_service.dart';

import 'package:flutter/foundation.dart' show ValueListenable;

import 'coin_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final ValueListenable<List<Coin>> marketCoinsListenable;

  const SearchScreen({super.key, required this.marketCoinsListenable});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final CoinGeckoService _service = CoinGeckoService();
  final WatchlistService _watchlistService = WatchlistService();
  final TextEditingController _controller = TextEditingController();

  List<Coin> _coins = [];
  bool _isLoading = true;
  String? _error;
  int _searchRequestId = 0;
  String _sortOption = 'Most Popular';

  static const background = Color(0xFF0B1020);
  static const cardColor = Color(0xFF171D32);
  static const accent = Color(0xFF7C6CFF);
  static const mutedText = Color(0xFF9CA5C3);
  static const positiveColor = Color(0xFF46D7A1);
  static const negativeColor = Color(0xFFFF647C);

  @override
  void initState() {
    super.initState();
  }

  Future<void> _searchCoins(String query) async {
    final searchQuery = query.trim();
    final requestId = ++_searchRequestId;

    if (searchQuery.isEmpty) {
      setState(() {
        _coins = [];
        _isLoading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _coins = [];
      _isLoading = true;
      _error = null;
    });

    try {
      final coins = await _service.searchCoins(searchQuery);

      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _coins = coins;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _coins = [];
        _isLoading = false;
        _error = 'Unable to search coins. Check your connection.';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(6)}';
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
  Widget build(BuildContext context) {
    final results = List<Coin>.from(_coins);

    switch (_sortOption) {
      case 'Market Cap: Low to High':
        results.sort((a, b) => a.marketCap.compareTo(b.marketCap));
        break;

      case '24h Change: High to Low':
        results.sort(
          (a, b) =>
              b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h),
        );
        break;

      case 'Most Popular':
      default:
        results.sort((a, b) => b.marketCap.compareTo(a.marketCap));
        break;
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back to dashboard',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: (value) {
                        setState(() {});
                        _searchCoins(value);
                      },
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search coins by name or symbol',
                        hintStyle: const TextStyle(color: mutedText),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: accent,
                        ),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: mutedText,
                                ),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 17,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Discover',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: ['Bitcoin', 'Ethereum', 'Solana'].map((name) {
                      return ActionChip(
                        label: Text(name),
                        avatar: const Icon(
                          Icons.trending_up_rounded,
                          size: 17,
                          color: Color(0xFFB4A7FF),
                        ),
                        backgroundColor: const Color(0xFF292650),
                        side: BorderSide.none,
                        labelStyle: const TextStyle(color: Color(0xFFDCD5FF)),
                        onPressed: () {
                          _controller.text = name;
                          _controller.selection = TextSelection.collapsed(
                            offset: name.length,
                          );
                          setState(() {});
                          _searchCoins(name);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (_controller.text.trim().isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Top results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    PopupMenuButton<String>(
                      initialValue: _sortOption,
                      color: cardColor,
                      onSelected: (value) {
                        setState(() {
                          _sortOption = value;
                        });
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'Most Popular',
                          child: Text('Most Popular'),
                        ),
                        PopupMenuItem(
                          value: 'Market Cap: Low to High',
                          child: Text('Market Cap: Low to High'),
                        ),
                        PopupMenuItem(
                          value: '24h Change: High to Low',
                          child: Text('24h Change: High to Low'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _sortOption,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: accent,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: accent),
                      )
                    : _error != null
                    ? SingleChildScrollView(
                        child: _MessageState(
                          icon: Icons.cloud_off_outlined,
                          message: _error!,
                          actionLabel: 'Try again',
                          onAction: () {
                            _searchCoins(_controller.text);
                          },
                        ),
                      )
                    : results.isEmpty
                    ? const SingleChildScrollView(
                        child: _MessageState(
                          icon: Icons.search_off_rounded,
                          message: 'No coins found',
                          subtitle: 'Try another coin name or symbol.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final coin = results[index];
                          final change = coin.priceChangePercentage24h;
                          final positive = change >= 0;

                          return InkWell(
                            borderRadius: BorderRadius.circular(17),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CoinDetailsScreen(
                                    coin: coin,
                                    marketCoinsListenable:
                                        widget.marketCoinsListenable,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.04),
                                ),
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
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatPrice(coin.currentPrice),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: positive
                                              ? const Color(0xFF163D35)
                                              : const Color(0xFF452532),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${positive ? '+' : ''}'
                                          '${change.toStringAsFixed(2)}%',
                                          style: TextStyle(
                                            color: positive
                                                ? positiveColor
                                                : negativeColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    tooltip: 'Save to watchlist',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );

                                      try {
                                        final wasAdded = await _watchlistService
                                            .addCoin(coin);

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
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF9CA5C3)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9CA5C3)),
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
