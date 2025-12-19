import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tesorin/app/features/wallet/add_transaction_sheet.dart';
import 'package:tesorin/app/models/txn.dart';
import 'package:tesorin/app/providers.dart';
import 'package:tesorin/app/ui/ui.dart';

enum WalletPeriod { week, month }
enum _InsightTab { trend, breakdown }

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  WalletPeriod _period = WalletPeriod.month;
  _InsightTab _tab = _InsightTab.trend;

  String _currencyCode = 'CAD';

  static const _currencyOptions = <_Currency>[
    _Currency(code: 'CAD', symbol: r'CA$'),
    _Currency(code: 'USD', symbol: r'$'),
    _Currency(code: 'INR', symbol: '₹'),
    _Currency(code: 'EUR', symbol: '€'),
    _Currency(code: 'GBP', symbol: '£'),
  ];

  _Currency get _currency =>
      _currencyOptions.firstWhere((c) => c.code == _currencyCode, orElse: () => _currencyOptions.first);

  String _fmtCents(int cents, {bool showPlus = false}) {
    final sign = cents < 0 ? '-' : (showPlus && cents > 0 ? '+' : '');
    final abs = cents.abs();
    final major = abs ~/ 100;
    final minor = abs % 100;
    return '$sign${_currency.symbol}$major.${minor.toString().padLeft(2, '0')}';
  }

  Future<void> _pickCurrency() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Currency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            ..._currencyOptions.map(
              (c) => ListTile(
                title: Text('${c.code}  (${c.symbol})'),
                trailing: c.code == _currencyCode ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(c.code),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (selected != null && selected.isNotEmpty) setState(() => _currencyCode = selected);
  }

  Future<void> _pickPeriod() async {
    final selected = await showModalBottomSheet<WalletPeriod>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Period size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            ListTile(
              title: const Text('Week'),
              trailing: _period == WalletPeriod.week ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(WalletPeriod.week),
            ),
            ListTile(
              title: const Text('Month'),
              trailing: _period == WalletPeriod.month ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(WalletPeriod.month),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (selected != null) setState(() => _period = selected);
  }

  @override
  Widget build(BuildContext context) {
    final txnsAsync = ref.watch(transactionsProvider);

    return txnsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (txns) {
        final now = DateTime.now();

        final range = _currentRange(now, _period);
        final inRange = txns.where((t) => !t.date.isBefore(range.start) && t.date.isBefore(range.end)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        final income = inRange.where((t) => t.amountCents > 0).fold<int>(0, (s, t) => s + t.amountCents);
        final expensesAbs = inRange.where((t) => t.amountCents < 0).fold<int>(0, (s, t) => s + t.amountCents.abs());
        final net = income - expensesAbs;

        final trend = _buildTrend(txns, now, _period);
        final pie = _buildPie(inRange);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Wallet'),
            actions: [
              // Period chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _pickPeriod,
                  child: _Chip(
                    label: _period == WalletPeriod.month ? 'Month' : 'Week',
                    icon: Icons.keyboard_arrow_down,
                  ),
                ),
              ),
              // Currency chip
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _pickCurrency,
                  child: _Chip(label: _currency.code, icon: Icons.keyboard_arrow_down),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showAddTransactionSheet(context),
            child: const Icon(Icons.add),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: Insets.screen,
                  child: Column(
                    children: [
                      // 1) Summary card (compact)
                      TCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cash Flow', style: TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text(
                                _fmtCents(net, showPlus: true),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _MiniStat(label: 'Income', value: _fmtCents(income, showPlus: true))),
                                  const SizedBox(width: 12),
                                  Expanded(child: _MiniStat(label: 'Expenses', value: _fmtCents(expensesAbs))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      Gaps.h12,

                      // 2) Insights card (toggle between Trend + Breakdown)
                      TCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Insights', style: TextStyle(fontWeight: FontWeight.w900)),
                                  const Spacer(),
                                  SegmentedButton<_InsightTab>(
                                    segments: const [
                                      ButtonSegment(value: _InsightTab.trend, label: Text('Trend')),
                                      ButtonSegment(value: _InsightTab.breakdown, label: Text('Breakdown')),
                                    ],
                                    selected: {_tab},
                                    onSelectionChanged: (s) => setState(() => _tab = s.first),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Keep charts compact so user can reach the list
                              if (_tab == _InsightTab.trend)
                                SizedBox(
                                  height: 125, // ✅ smaller than before
                                  child: _TrendBarChart(
                                    trend: trend,
                                    primary: Theme.of(context).colorScheme.primary,
                                    secondary: Theme.of(context).colorScheme.tertiary,
                                    labelColor: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 170, // ✅ smaller than before
                                  child: pie.totalExpenseCents == 0
                                      ? const Center(child: Text('No expenses in this period yet.'))
                                      : _SpendingPieChart(
                                          data: pie,
                                          paletteBase: Theme.of(context).colorScheme.primary,
                                          textColor: Theme.of(context).textTheme.bodySmall?.color,
                                          format: (centsAbs) => _fmtCents(centsAbs),
                                        ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      Gaps.h12,

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _period == WalletPeriod.month ? 'Transactions (this month)' : 'Transactions (this week)',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Gaps.h8,
                    ],
                  ),
                ),
              ),

              // Transaction list
              if (inRange.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                    child: Center(child: Text('No transactions yet. Tap + to add one.')),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: inRange.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 24, endIndent: 12),
                  itemBuilder: (context, i) {
                    final t = inRange[i];
                    final date =
                        '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
                    final amount = _fmtCents(t.amountCents, showPlus: true);

                    return Dismissible(
                      key: ValueKey(t.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.12),
                        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete transaction?'),
                                content: const Text('This cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) async {
                        await ref.read(transactionsRepoProvider).deleteTxn(t.id);
                      },
                      child: ListTile(
                        onTap: () => showAddTransactionSheet(context, initial: t),
                        leading: CircleAvatar(
                          child: Icon(t.amountCents >= 0 ? Icons.arrow_downward : Icons.arrow_upward),
                        ),
                        title: Text(t.category, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(t.note.isEmpty ? date : '$date • ${t.note}'),
                        trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    );
                  },
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),
        );
      },
    );
  }

  // ---------- data helpers ----------
  static _DateRange _currentRange(DateTime now, WalletPeriod period) {
    if (period == WalletPeriod.month) {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      return _DateRange(start, end);
    }
    final start = _startOfWeek(now);
    final end = start.add(const Duration(days: 7));
    return _DateRange(start, end);
  }

  static DateTime _startOfWeek(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    final delta = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: delta));
  }

  static List<_TrendBucket> _buildTrend(List<Txn> txns, DateTime now, WalletPeriod period) {
    if (period == WalletPeriod.month) {
      // last 6 months including current
      final buckets = <_TrendBucket>[];
      for (int back = 5; back >= 0; back--) {
        final m = DateTime(now.year, now.month - back, 1);
        final start = DateTime(m.year, m.month, 1);
        final end = DateTime(m.year, m.month + 1, 1);

        final slice = txns.where((t) => !t.date.isBefore(start) && t.date.isBefore(end));
        final inc = slice.where((t) => t.amountCents > 0).fold<int>(0, (s, t) => s + t.amountCents);
        final expAbs = slice.where((t) => t.amountCents < 0).fold<int>(0, (s, t) => s + t.amountCents.abs());

        buckets.add(_TrendBucket(
          label: _monthLabel(start.month),
          incomeCents: inc,
          expenseCentsAbs: expAbs,
        ));
      }
      return buckets;
    } else {
      // last 8 weeks including current
      final buckets = <_TrendBucket>[];
      final thisWeekStart = _startOfWeek(now);
      for (int back = 7; back >= 0; back--) {
        final start = thisWeekStart.subtract(Duration(days: 7 * back));
        final end = start.add(const Duration(days: 7));

        final slice = txns.where((t) => !t.date.isBefore(start) && t.date.isBefore(end));
        final inc = slice.where((t) => t.amountCents > 0).fold<int>(0, (s, t) => s + t.amountCents);
        final expAbs = slice.where((t) => t.amountCents < 0).fold<int>(0, (s, t) => s + t.amountCents.abs());

        buckets.add(_TrendBucket(
          label: '${start.month}/${start.day}',
          incomeCents: inc,
          expenseCentsAbs: expAbs,
        ));
      }
      return buckets;
    }
  }

  static _PieData _buildPie(List<Txn> inRange) {
    final totals = <String, int>{};
    for (final t in inRange.where((x) => x.amountCents < 0)) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amountCents.abs();
    }

    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    const maxSlices = 6; // top 6 + Other
    final top = entries.take(maxSlices).toList();
    final rest = entries.skip(maxSlices);

    int other = 0;
    for (final e in rest) {
      other += e.value;
    }

    final slices = <_PieSlice>[
      for (final e in top) _PieSlice(label: e.key, centsAbs: e.value),
      if (other > 0) _PieSlice(label: 'Other', centsAbs: other),
    ];

    final total = slices.fold<int>(0, (s, x) => s + x.centsAbs);
    return _PieData(slices: slices, totalExpenseCents: total);
  }

  static String _monthLabel(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[math.max(1, math.min(12, m)) - 1];
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Icon(icon, size: 18),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: Radii.r16,
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: tt.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _TrendBucket {
  final String label;
  final int incomeCents;
  final int expenseCentsAbs;
  const _TrendBucket({required this.label, required this.incomeCents, required this.expenseCentsAbs});
}

class _TrendBarChart extends StatelessWidget {
  final List<_TrendBucket> trend;
  final Color primary;
  final Color secondary;
  final Color? labelColor;

  const _TrendBarChart({
    required this.trend,
    required this.primary,
    required this.secondary,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    double maxY = 0;
    for (final b in trend) {
      maxY = math.max(maxY, (b.incomeCents / 100).toDouble());
      maxY = math.max(maxY, (b.expenseCentsAbs / 100).toDouble());
    }
    maxY = math.max(10, maxY * 1.2);

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(trend[i].label, style: TextStyle(fontSize: 10, color: labelColor)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: true),
        barGroups: [
          for (int i = 0; i < trend.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: (trend[i].incomeCents / 100).toDouble(),
                  width: 8,
                  color: primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                BarChartRodData(
                  toY: (trend[i].expenseCentsAbs / 100).toDouble(),
                  width: 8,
                  color: secondary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PieSlice {
  final String label;
  final int centsAbs;
  const _PieSlice({required this.label, required this.centsAbs});
}

class _PieData {
  final List<_PieSlice> slices;
  final int totalExpenseCents;
  const _PieData({required this.slices, required this.totalExpenseCents});
}

class _SpendingPieChart extends StatefulWidget {
  final _PieData data;
  final Color paletteBase;
  final Color? textColor;
  final String Function(int centsAbs) format;

  const _SpendingPieChart({
    required this.data,
    required this.paletteBase,
    required this.textColor,
    required this.format,
  });

  @override
  State<_SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<_SpendingPieChart> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.totalExpenseCents;
    final slices = widget.data.slices;

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < slices.length; i++) {
      final s = slices[i];
      final pct = total == 0 ? 0 : (s.centsAbs / total) * 100.0;

      final alpha = 0.20 + (0.65 * (i / math.max(1, slices.length - 1)));
      final color = widget.paletteBase.withValues(alpha: alpha.clamp(0.2, 0.9));

      final isTouched = _touched == i;

      sections.add(
        PieChartSectionData(
          value: s.centsAbs.toDouble(),
          radius: isTouched ? 66 : 58,
          color: color,
          title: pct >= 12 ? '${pct.toStringAsFixed(0)}%' : '',
          titleStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: widget.textColor),
        ),
      );
    }

    final legend = Column(
      children: [
        for (int i = 0; i < slices.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.paletteBase.withValues(
                      alpha: (0.20 + (0.65 * (i / math.max(1, slices.length - 1)))).clamp(0.2, 0.9),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slices[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: widget.textColor),
                  ),
                ),
                Text(widget.format(slices[i].centsAbs), style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
      ],
    );

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 34,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final idx = response?.touchedSection?.touchedSectionIndex;
                  setState(() => _touched = (event.isInterestedForInteractions && idx != null) ? idx : null);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(flex: 6, child: legend),
      ],
    );
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;
  const _DateRange(this.start, this.end);
}

class _Currency {
  final String code;
  final String symbol;
  const _Currency({required this.code, required this.symbol});
}
