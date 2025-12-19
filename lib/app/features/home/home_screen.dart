import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tesorin/app/engines/cashflow_engine.dart';
import 'package:tesorin/app/providers.dart';
import 'package:tesorin/app/features/wallet/add_transaction_screen.dart';
import 'package:tesorin/app/features/networth/networth_screen.dart';
import 'package:tesorin/app/models/money.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(transactionsProvider);

    return txnsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (txns) {
        final now = DateTime.now();
        final summary = CashflowEngine().forMonth(txns, now.year, now.month);

        final s = summary.surplusCents;

        final interpretation = s >= 0
            ? "You have ~${Money.formatCents(s)} of monthly flexibility."
            : "You're short ~${Money.formatCents(s.abs())} this month. Fix cashflow first.";

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _card(
                title: 'Monthly Cashflow',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Income: ${Money.formatCents(summary.incomeCents)}'),
                    Text('Expenses: ${Money.formatCents(summary.expenseCentsAbs)}'),
                    const SizedBox(height: 8),
                    Text(
                      interpretation,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add transaction → Wallet'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(
                title: 'Net Worth Snapshot',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Next: assets, liabilities, net worth.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NetWorthScreen()),
                      ),
                      child: const Text('Open Net Worth'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _card(
                title: 'Goals Progress',
                child: const Text('Next: show 1–3 goals only (no overwhelm).'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
