import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/app_application.dart';

class ApplicationStatsChart extends StatefulWidget {
  final List<ApplicationItem> applications;

  const ApplicationStatsChart({super.key, required this.applications});

  @override
  State<ApplicationStatsChart> createState() => _ApplicationStatsChartState();
}

class _ApplicationStatsChartState extends State<ApplicationStatsChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    final inProgress = widget.applications.where((a) => ['pending', 'reviewed', 'started'].contains(a.status)).length;
    final accepted = widget.applications.where((a) => ['accepted', 'contract_signed', 'finished'].contains(a.status)).length;
    final rejected = widget.applications.where((a) => a.status == 'rejected').length;

    return Row(
      children: [
        Expanded(child: _buildStatCard(context, 'En cours', inProgress, Colors.blue, Icons.hourglass_empty)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, 'Accepté', accepted, Colors.green, Icons.check_circle_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(context, 'Rejeté', rejected, Colors.red, Icons.cancel_outlined)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, int count, Color color, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black87
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12, 
              color: isDark ? Colors.blueGrey[200] : Colors.grey[600], 
              fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


