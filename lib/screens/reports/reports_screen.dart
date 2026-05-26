import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../repositories/transaction_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/empty_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repo = TransactionRepository();
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  late Future<_ReportData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReportData> _load() async {
    final from = DateTime(_year, _month, 1);
    final to = DateTime(_year, _month + 1, 0, 23, 59, 59);
    final sums = await _repo.sums(from: from, to: to);
    final byCat = await _repo.expenseByCategory(from: from, to: to);
    final series = await _repo.dailySeries(from: from, to: to);
    return _ReportData(
      income: sums.income,
      expense: sums.expense,
      expenseByCategory: byCat,
      series: series,
    );
  }

  void _changeMonth(int delta) {
    var m = _month + delta;
    var y = _year;
    if (m < 1) {
      m = 12;
      y -= 1;
    } else if (m > 12) {
      m = 1;
      y += 1;
    }
    setState(() {
      _month = m;
      _year = y;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
      ),
      body: FutureBuilder<_ReportData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          final hasData = data.income > 0 || data.expense > 0;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              setState(() => _future = _load());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _MonthHeader(
                  month: _month,
                  year: _year,
                  onPrev: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  income: data.income,
                  expense: data.expense,
                ),
                if (!hasData)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      emoji: '📈',
                      title: 'Belum ada data',
                      subtitle:
                          'Mulai catat transaksi untuk melihat laporan bulan ini.',
                    ),
                  )
                else ...[
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: 'Tren Harian',
                    subtitle: 'Pemasukan vs pengeluaran',
                    child: SizedBox(
                      height: 200,
                      child: _DailyChart(series: data.series),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ChartCard(
                    title: 'Pengeluaran per Kategori',
                    subtitle:
                        'Persentase distribusi pengeluaran bulan ini',
                    child: _CategoryBreakdown(
                      byCategory: data.expenseByCategory,
                      totalExpense: data.expense,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportData {
  final double income;
  final double expense;
  final Map<String, double> expenseByCategory;
  final List<({DateTime day, double income, double expense})> series;
  _ReportData({
    required this.income,
    required this.expense,
    required this.expenseByCategory,
    required this.series,
  });
}

class _MonthHeader extends StatelessWidget {
  final int month;
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.year,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
          ),
          Expanded(
            child: Center(
              child: Text(
                Fmt.monthYear(DateTime(year, month)),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double income;
  final double expense;

  const _SummaryCard({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: net >= 0
                ? AppColors.incomeGradient
                : AppColors.expenseGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SALDO BERSIH',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${net >= 0 ? '+' : ''}${Fmt.idr(net)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  net >= 0 ? '🤑' : '😬',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniSummary(
                emoji: '⬇️',
                label: 'Pemasukan',
                value: Fmt.idrCompact(income),
                color: AppColors.income,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniSummary(
                emoji: '⬆️',
                label: 'Pengeluaran',
                value: Fmt.idrCompact(expense),
                color: AppColors.expense,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniSummary extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _MiniSummary({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DailyChart extends StatelessWidget {
  final List<({DateTime day, double income, double expense})> series;

  const _DailyChart({required this.series});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada transaksi.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    double maxY = 0;
    for (final s in series) {
      final x = s.day.day.toDouble();
      incomeSpots.add(FlSpot(x, s.income));
      expenseSpots.add(FlSpot(x, s.expense));
      maxY = [maxY, s.income, s.expense].reduce((a, b) => a > b ? a : b);
    }
    if (maxY == 0) maxY = 1;

    return LineChart(
      LineChartData(
        minX: 1,
        maxX: 31,
        minY: 0,
        maxY: maxY * 1.15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 5,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItems: (spots) => spots.map((s) {
              final color = s.barIndex == 0 ? AppColors.income : AppColors.expense;
              return LineTooltipItem(
                Fmt.idrCompact(s.y),
                TextStyle(color: color, fontWeight: FontWeight.w800),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            color: AppColors.income,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.income.withOpacity(0.15),
            ),
          ),
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: AppColors.expense,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.expense.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, double> byCategory;
  final double totalExpense;

  const _CategoryBreakdown({
    required this.byCategory,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProv = context.watch<CategoryProvider>();
    if (byCategory.isEmpty || totalExpense == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Belum ada pengeluaran berkategori bulan ini.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    final items = <Widget>[];
    for (final e in entries) {
      final cat = categoryProv.byId(e.key);
      final pct = (e.value / totalExpense) * 100;
      final color = cat?.color ?? AppColors.primary;
      sections.add(
        PieChartSectionData(
          color: color,
          value: e.value,
          radius: 50,
          title: '${pct.toStringAsFixed(0)}%',
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      );
      items.add(_CategoryRow(
        name: cat?.name ?? 'Tanpa kategori',
        icon: cat?.icon ?? '🏷️',
        color: color,
        value: e.value,
        pct: pct,
      ));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: items
              .map((w) =>
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: w))
              .toList(),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String name;
  final String icon;
  final Color color;
  final double value;
  final double pct;

  const _CategoryRow({
    required this.name,
    required this.icon,
    required this.color,
    required this.value,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Fmt.idr(value),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${pct.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
