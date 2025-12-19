import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tesorin/app/engines/goals_engine.dart';
import 'package:tesorin/app/models/money.dart';
import 'package:tesorin/app/features/goals/goals_provider.dart';
import 'package:tesorin/app/features/goals/goal_setup_screen.dart';
import 'package:tesorin/app/features/goals/goal_templates.dart';
import 'package:tesorin/app/ui/ui.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  GoalTemplate? _selected;

  void _openSetup(GoalTemplate t) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalSetupScreen(template: t)),
    );
  }

  Future<void> _openTemplatePicker() async {
    final picked = await showModalBottomSheet<GoalTemplate>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Text('Add a goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            for (final t in goalTemplates)
              ListTile(
                leading: CircleAvatar(child: Icon(t.icon)),
                title: Text(t.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pop(t),
              ),
          ],
        ),
      ),
    );

    if (picked != null) _openSetup(picked);
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    final engine = GoalsEngine();

    // If goals exist → show progress tracker
    if (goals.isNotEmpty) {
      return Scaffold(
        body: ListView(
          padding: Insets.screen,
          children: [
            TCard(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Goals Progress Tracker',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openTemplatePicker,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Goal'),
                  ),
                ],
              ),
            ),
            Gaps.h12,
            for (final g in goals)
              TCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Gaps.h8,
                    Text('${Money.formatCents(g.currentCents)} / ${Money.formatCents(g.targetCents)}'),
                    Gaps.h8,
                    LinearProgressIndicator(value: engine.progress(g).ratio),
                    Gaps.h8,
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('${engine.percent(g)}%'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    // No goals yet → show template selection + Next (like your prototype)
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Let's set a new goal!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('What goal would you like to set?', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),

            Expanded(
              child: ListView.separated(
                itemCount: goalTemplates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = goalTemplates[i];
                  final selected = _selected?.key == t.key;

                  return InkWell(
                    borderRadius: Radii.r16,
                    onTap: () => setState(() => _selected = t),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: Radii.r16,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor.withOpacity(0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(child: Icon(t.icon)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected == null ? null : () => _openSetup(_selected!),
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
