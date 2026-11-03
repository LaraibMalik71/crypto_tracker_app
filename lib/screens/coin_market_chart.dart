import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/coingecko_service.dart';

class CoinMarketChart extends StatefulWidget {
  final String coinId;

  const CoinMarketChart({super.key, required this.coinId});

  @override
  State<CoinMarketChart> createState() => _CoinMarketChartState();
}

class _CoinMarketChartState extends State<CoinMarketChart> {
  static const Color _cardColor = Color(0xFF171D32);
  static const Color _accent = Color(0xFFB4A7FF);
  static const Color _mutedText = Color(0xFF9CA5C3);
  static const Color _volumeColor = Color(0xFF46D7A1);

  final CoinGeckoService _service = CoinGeckoService();

  int _days = 7;
  bool _isLoading = true;
  String? _error;
  List<FlSpot> _priceSpots = [];
  List<double> _volumes = [];
  double _priceChangePercent = 0;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  @override
  void didUpdateWidget(covariant CoinMarketChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.coinId != widget.coinId) {
      _loadChartData();
    }
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getCoinMarketChart(
        widget.coinId,
        days: _days,
      );

      final prices = _samplePairs(data['prices'], 50);
      final volumes = _samplePairs(data['total_volumes'], 20);

      if (prices.length < 2) {
        throw Exception('Not enough historical price data.');
      }

      if (!mounted) return;
      final firstPrice = prices.first[1];
      final lastPrice = prices.last[1];

      final changePercent = firstPrice > 0
          ? ((lastPrice - firstPrice) / firstPrice) * 100
          : 0.0;
      setState(() {
        _priceChangePercent = changePercent;
        _priceSpots = List.generate(
          prices.length,
          (index) => FlSpot(index.toDouble(), prices[index][1]),
        );

        _volumes = volumes.map((pair) => pair[1]).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load chart data. Please try again.';
        _isLoading = false;
      });
    }
  }

  // Reduces the number of points so charts remain readable.
  List<List<double>> _samplePairs(dynamic rawData, int maxPoints) {
    if (rawData is! List) return [];

    final pairs = <List<double>>[];

    for (final item in rawData) {
      if (item is List && item.length >= 2) {
        final timestamp = item[0];
        final value = item[1];

        if (timestamp is num && value is num && value.isFinite && value >= 0) {
          pairs.add([timestamp.toDouble(), value.toDouble()]);
        }
      }
    }

    if (pairs.length <= maxPoints) return pairs;

    final sampled = <List<double>>[];
    final step = (pairs.length - 1) / (maxPoints - 1);

    for (var i = 0; i < maxPoints; i++) {
      sampled.add(pairs[(i * step).round()]);
    }

    return sampled;
  }

  String _formatPrice(double value) {
    if (value >= 1) {
      return '\$${value.toStringAsFixed(2)}';
    }
    return '\$${value.toStringAsFixed(6)}';
  }

  String _formatVolume(double value) {
    if (value >= 1e9) {
      return '\$${(value / 1e9).toStringAsFixed(1)}B';
    }
    if (value >= 1e6) {
      return '\$${(value / 1e6).toStringAsFixed(1)}M';
    }
    if (value >= 1e3) {
      return '\$${(value / 1e3).toStringAsFixed(1)}K';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price History',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _rangeButton('1D', 1),
                  const SizedBox(width: 8),
                  _rangeButton('7D', 7),
                  const SizedBox(width: 8),
                  _rangeButton('30D', 30),
                  const SizedBox(width: 8),
                  _rangeButton('1Y', 365),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SizedBox(
                  height: 220,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.show_chart,
                          size: 36,
                          color: _mutedText,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _mutedText),
                        ),
                        TextButton(
                          onPressed: _loadChartData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Text(
                  _formatPrice(_priceSpots.last.y),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      _priceChangePercent >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 18,
                      color: _priceChangePercent >= 0
                          ? const Color(0xFF46D7A1)
                          : const Color(0xFFFF647C),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_priceChangePercent >= 0 ? '+' : ''}'
                      '${_priceChangePercent.toStringAsFixed(2)}% for selected period',
                      style: TextStyle(
                        color: _priceChangePercent >= 0
                            ? const Color(0xFF46D7A1)
                            : const Color(0xFFFF647C),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 190,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (_priceSpots.length - 1).toDouble(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _priceInterval(),
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Color(0xFF343B54),
                          strokeWidth: 0.7,
                        ),
                      ),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF252C43),
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              return LineTooltipItem(
                                'Price\n${_formatPrice(spot.y)}',
                                const TextStyle(
                                  color: Color(0xFFB4A7FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes.map((index) {
                            return TouchedSpotIndicatorData(
                              const FlLine(
                                color: Color(0xFFB4A7FF),
                                strokeWidth: 1.5,
                                dashArray: [4, 4],
                              ),
                              FlDotData(
                                getDotPainter: (spot, percent, bar, index) {
                                  return FlDotCirclePainter(
                                    radius: 5,
                                    color: const Color(0xFFB4A7FF),
                                    strokeWidth: 2,
                                    strokeColor: const Color(0xFF171D32),
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _priceSpots,
                          isCurved: true,
                          color: _priceChangePercent >= 0
                              ? const Color(0xFF46D7A1)
                              : const Color(0xFFFF647C),
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color:
                                (_priceChangePercent >= 0
                                        ? const Color(0xFF46D7A1)
                                        : const Color(0xFFFF647C))
                                    .withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Trading Volume',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 135,
                  child: _volumes.isEmpty
                      ? const Center(
                          child: Text(
                            'Volume data unavailable.',
                            style: TextStyle(color: _mutedText),
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY:
                                _volumes.reduce((a, b) => a > b ? a : b) * 1.15,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        _formatVolume(rod.toY),
                                        const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                              ),
                            ),
                            barGroups: List.generate(
                              _volumes.length,
                              (index) => BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: _volumes[index],
                                    color: _volumeColor,
                                    width: 7,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  double _priceInterval() {
    if (_priceSpots.isEmpty) return 1;

    final values = _priceSpots.map((spot) => spot.y);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final interval = (maxValue - minValue) / 4;

    return interval > 0
        ? interval
        : (maxValue.abs() * 0.01).clamp(0.01, double.infinity);
  }

  Widget _rangeButton(String label, int days) {
    final selected = _days == days;

    return Expanded(
      child: GestureDetector(
        onTap: selected
            ? null
            : () {
                setState(() => _days = days);
                _loadChartData();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _accent : const Color(0xFF252C43),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _accent : const Color(0xFF343B54),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF171D32) : Colors.white,
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
