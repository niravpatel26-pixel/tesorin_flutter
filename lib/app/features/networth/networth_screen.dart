import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tesorin/app/engines/networth_engine.dart';
import 'package:tesorin/app/features/networth/networth_provider.dart';
import 'package:tesorin/app/models/money.dart';
import 'package:tesorin/app/models/networth_item.dart';
import 'package:tesorin/app/ui/ui.dart';

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(netWorthProvider);

    final assets = items.where((i) => i.type == NetWorthType.asset).toList();
    final liabilities = items.where((i) => i.type == NetWorthType.liability).toList();

    final engine = NetWorthEngine();
    final snap = engine.snapshot(items);
    final sig = engine.signals(snap);

    final assetsTotal = snap.assetsCents;
    final liabilitiesTotal = snap.liabilitiesCents;
    final netWorth = snap.netWorthCents;

    final insight = engine.oneLineInsight(snap, sig);

    return Scaffold(
      appBar: AppBar(title: const Text('Net Worth')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: Insets.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top summary (premium, minimal)
                  TCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Net Worth',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Gaps.h8,
                        Text(
                          Money.formatCents(netWorth),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                        Gaps.h12,
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'Assets',
                                value: Money.formatCents(assetsTotal),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MiniStat(
                                label: 'Liabilities',
                                value: Money.formatCents(liabilitiesTotal),
                              ),
                            ),
                          ],
                        ),
                        if (sig.leverageRatio.isFinite && assetsTotal > 0) ...[
                          Gaps.h12,
                          Text(
                            'Leverage: ${(sig.leverageRatio * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),

                  Gaps.h12,

                  // Thinking layer line
                  Text(
                    insight,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          // Assets
          SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(child: TSectionHeader('Assets')),
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 10),
                  child: TextButton.icon(
                    onPressed: () => _openAddSheet(context, NetWorthType.asset),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
          if (assets.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('No assets yet. Add cash, bank, investments, property.'),
              ),
            )
          else
            SliverList.separated(
              itemCount: assets.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 24, endIndent: 12),
              itemBuilder: (context, i) => _NetWorthRow(item: assets[i]),
            ),

          // Liabilities
          SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(child: TSectionHeader('Liabilities')),
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 10),
                  child: TextButton.icon(
                    onPressed: () => _openAddSheet(context, NetWorthType.liability),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
          if (liabilities.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('No liabilities yet. Add credit cards, loans, mortgage.'),
              ),
            )
          else
            SliverList.separated(
              itemCount: liabilities.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 24, endIndent: 12),
              itemBuilder: (context, i) => _NetWorthRow(item: liabilities[i], isLiability: true),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static Future<void> _openAddSheet(BuildContext context, NetWorthType type) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AddNetWorthSheet(type: type),
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
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: tt.labelMedium),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _NetWorthRow extends ConsumerWidget {
  final NetWorthItem item;
  final bool isLiability;

  const _NetWorthRow({required this.item, this.isLiability = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = isLiability
        ? '-${Money.formatCents(item.amountCents)}'
        : Money.formatCents(item.amountCents);

    return ListTile(
      title: Text(item.name),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      onLongPress: () {
        ref.read(netWorthProvider.notifier).remove(item.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed')));
      },
    );
  }
}

class _AddNetWorthSheet extends ConsumerStatefulWidget {
  final NetWorthType type;
  const _AddNetWorthSheet({required this.type});

  @override
  ConsumerState<_AddNetWorthSheet> createState() => _AddNetWorthSheetState();
}

class _AddNetWorthSheetState extends ConsumerState<_AddNetWorthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final cents = Money.parseCents(_amount.text);
      ref.read(netWorthProvider.notifier).add(
            type: widget.type,
            name: _name.text.trim(),
            amountCents: cents.abs(), // store positive; type determines asset/liability
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.type == NetWorthType.asset ? 'Add Asset' : 'Add Liability';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Gaps.h12,
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Name (e.g., Cash, Mortgage)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                Gaps.h12,
                TextFormField(
                  controller: _amount,
                  enabled: !_saving,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (e.g., 1250.00)'),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Enter an amount';
                    try {
                      Money.parseCents(s);
                      return null;
                    } catch (_) {
                      return 'Enter a valid amount';
                    }
                  },
                ),
                Gaps.h16,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
