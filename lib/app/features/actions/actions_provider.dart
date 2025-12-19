import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tesorin/app/engines/actions_engine.dart';
import 'package:tesorin/app/engines/cashflow_engine.dart';
import 'package:tesorin/app/models/action_item.dart';
import 'package:tesorin/app/providers.dart';

final actionsAsyncProvider = Provider<AsyncValue<List<ActionItem>>>((ref) {
  final txnsAsync = ref.watch(transactionsProvider);

  return txnsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (txns) {
      final now = DateTime.now();
      final cashflow = CashflowEngine().forMonth(txns, now.year, now.month);
      final actions = ActionsEngine().generate(txns: txns, cashflow: cashflow);
      return AsyncValue.data(actions);
    },
  );
});

final hasActionsProvider = Provider<bool>((ref) {
  final a = ref.watch(actionsAsyncProvider);
  return a.maybeWhen(data: (list) => list.isNotEmpty, orElse: () => false);
});
