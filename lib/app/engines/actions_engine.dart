import '../models/action_item.dart';
import '../models/money.dart';
import '../models/txn.dart';
import 'cashflow_engine.dart';

class ActionsEngine {
  List<ActionItem> generate({
    required List<Txn> txns,
    required MonthlyCashflow cashflow,
  }) {
    final actions = <ActionItem>[];

    String id(String key) => 'action:$key';

    // Priority ranking for sorting
    int rank(ActionPriority p) {
      switch (p) {
        case ActionPriority.high:
          return 1;
        case ActionPriority.medium:
          return 2;
        case ActionPriority.low:
          return 3;
      }
    }

    // 1) Cashflow stress
    if (cashflow.surplusCents < 0) {
      actions.add(
        ActionItem(
          id: id('cashflow_deficit'),
          priority: ActionPriority.high,
          title: 'Fix cashflow first',
          why: 'You are running a monthly deficit.',
          impact: 'Close the gap by ${Money.formatCents(cashflow.surplusCents.abs())}/mo.',
        ),
      );
    }

    // 2) Emergency buffer (placeholder heuristic)
    if (cashflow.expenseCentsAbs > 0) {
      final ratio = cashflow.surplusCents / cashflow.expenseCentsAbs;
      if (ratio > 0 && ratio < 0.05) {
        actions.add(
          ActionItem(
            id: id('emergency_buffer'),
            priority: ActionPriority.medium,
            title: 'Start an emergency buffer',
            why: 'Small shocks can force debt when cash is tight.',
            impact: 'Target 1 month of expenses first.',
          ),
        );
      }
    }

    // 3) Recurring spending review (placeholder until recurring engine lands)
    final spendCount = txns.where((t) => t.amountCents < 0).length;
    if (spendCount >= 8) {
      actions.add(
        ActionItem(
          id: id('recurring_review'),
          priority: ActionPriority.low,
          title: 'Review recurring spending',
          why: 'Repeated expenses can hide silent drains.',
          impact: 'Cut 1–2 subscriptions to free up cash monthly.',
        ),
      );
    }

    actions.sort((a, b) => rank(a.priority).compareTo(rank(b.priority)));
    return actions.take(3).toList();
  }
}
