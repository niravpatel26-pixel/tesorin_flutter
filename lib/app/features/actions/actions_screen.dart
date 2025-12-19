import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'actions_provider.dart';

class ActionsScreen extends ConsumerWidget {
  const ActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(actionsAsyncProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Actions')),
      body: actionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (actions) {
          final top = actions.length > 3 ? actions.take(3).toList() : actions;

          if (top.isEmpty) {
            return const Center(child: Text('No actions right now. You’re on track.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: top.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = top[i];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text('Why: ${a.why}'),
                      const SizedBox(height: 6),
                      Text(
                        'Impact: ${a.impact}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
