import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_settings.dart';
import '../core/translations.dart';

/// Badge indicating job match score (e.g. "High match").
class MatchBadge extends StatelessWidget {
  final int scorePercent;
  final bool compact;

  const MatchBadge({
    super.key,
    required this.scorePercent,
    this.compact = false,
  });

  String _label(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    if (scorePercent >= 80) return lang.tr('high_match');
    if (scorePercent >= 60) return lang.tr('good_match');
    if (scorePercent >= 40) return lang.tr('fair_match');
    return '';
  }

  Color _color(BuildContext context) {
    if (scorePercent >= 80) return const Color(0xFF10B981);
    if (scorePercent >= 60) return const Color(0xFF3B82F6);
    if (scorePercent >= 40) return const Color(0xFFF59E0B);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (scorePercent < 40) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = _color(context);
    final label = _label(context);
    if (label.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thumb_up, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              '$scorePercent%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
