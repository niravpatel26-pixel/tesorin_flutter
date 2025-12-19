import 'dart:math';

import '../models/txn.dart';

class MonthlyCashflow {
  final int incomeCents;
  final int expenseCentsAbs; // stored as positive for clarity
  final int surplusCents;

  const MonthlyCashflow({
    required this.incomeCents,
    required this.expenseCentsAbs,
    required this.surplusCents,
  });
}

class CashflowFacts {
  final MonthlyCashflow currentMonth;
  final int rolling3mAvgSurplusCents;
  final double expenseVolatility; // 0..+

  const CashflowFacts({
    required this.currentMonth,
    required this.rolling3mAvgSurplusCents,
    required this.expenseVolatility,
  });
}

class CashflowEngine {
  MonthlyCashflow forMonth(List<Txn> txns, int year, int month) {
    final monthTxns = txns.where((t) => t.date.year == year && t.date.month == month);

    var income = 0;
    var expenseAbs = 0;

    for (final t in monthTxns) {
      if (t.amountCents >= 0) {
        income += t.amountCents;
      } else {
        expenseAbs += (-t.amountCents);
      }
    }

    final surplus = income - expenseAbs;

    return MonthlyCashflow(
      incomeCents: income,
      expenseCentsAbs: expenseAbs,
      surplusCents: surplus,
    );
  }

  CashflowFacts factsNow(List<Txn> txns, DateTime now) {
    final current = forMonth(txns, now.year, now.month);

    // Rolling 3-month average surplus
    final months = <DateTime>[
      DateTime(now.year, now.month),
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month - 2),
    ];

    final surpluses = months
        .map((m) => forMonth(txns, m.year, m.month).surplusCents)
        .toList();

    final avgSurplus = (surpluses.isEmpty)
        ? 0
        : (surpluses.reduce((a, b) => a + b) / surpluses.length).round();

    // Expense volatility = std dev of expenses / mean expenses over last 3 months
    final expenses = months
        .map((m) => forMonth(txns, m.year, m.month).expenseCentsAbs)
        .toList();

    final vol = _volatility(expenses);

    return CashflowFacts(
      currentMonth: current,
      rolling3mAvgSurplusCents: avgSurplus,
      expenseVolatility: vol,
    );
  }

  double _volatility(List<int> values) {
    final xs = values.where((v) => v > 0).toList();
    if (xs.length < 2) return 0;

    final mean = xs.reduce((a, b) => a + b) / xs.length;
    if (mean == 0) return 0;

    var variance = 0.0;
    for (final v in xs) {
      variance += pow(v - mean, 2).toDouble();
    }
    variance /= xs.length;
    final std = sqrt(variance);

    return std / mean; // relative volatility
  }
}
