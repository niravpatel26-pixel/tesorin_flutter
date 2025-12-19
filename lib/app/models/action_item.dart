enum ActionPriority { high, medium, low }

class ActionItem {
  final String id;
  final String title;
  final String why;
  final String impact; // keep as text for now (simple + clear)
  final ActionPriority priority;

  const ActionItem({
    required this.id,
    required this.title,
    required this.why,
    required this.impact,
    required this.priority,
  });
}
