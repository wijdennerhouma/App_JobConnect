
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';

import '../../../core/api_config.dart';
import '../../../core/app_settings.dart';
import '../../../core/translations.dart';
import '../../../models/job.dart';
import '../../../models/user.dart';
import '../../../widgets/glass_container.dart';
import '../../../widgets/glass_button.dart';
import '../../../widgets/match_badge.dart';
import 'favorite_button.dart';
import 'bouncing_button.dart';
import '../job_detail_screen.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final AppUser? company;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final bool? hasApplied;
  final VoidCallback? onApply;
  final VoidCallback? onViewApplication;
  final bool showApplyButton;
  /// Optional match score 0-100 for "Recommended for you" badge.
  final int? matchScore;

  const JobCard({
    super.key,
    required this.job,
    this.company,
    required this.isSaved,
    required this.onToggleSaved,
    this.hasApplied,
    this.onApply,
    this.onViewApplication,
    this.showApplyButton = true,
    this.matchScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<AppSettings>().language;
    final isDark = theme.brightness == Brightness.dark;
    final isWeb = MediaQuery.of(context).size.width > 600;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isWeb ? 24 : 20,
        vertical: isWeb ? 12 : 10,
      ),
      child: GlassContainer(
        borderRadius: 24,
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => JobDetailScreen(jobId: job.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo and company name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'job-logo-${job.id}',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                         color: theme.colorScheme.surface,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (company?.avatar != null && company!.avatar!.isNotEmpty)
                            ? Image.network(
                                '${ApiConfig.baseUrl}/uploads/avatars/${company!.avatar}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.business_rounded, size: 28, color: theme.colorScheme.primary.withOpacity(0.5));
                                },
                              )
                            : Icon(Icons.business_rounded, size: 28, color: theme.colorScheme.primary.withOpacity(0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Hero(
                                      tag: 'job-title-${job.id}',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          job.title,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (matchScore != null && matchScore! >= 40) ...[
                                    const SizedBox(width: 8),
                                    MatchBadge(scorePercent: matchScore!, compact: true),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share_outlined, size: 20),
                                  onPressed: () {
                                    final text = 'Rejoignez-nous! ${job.title} chez ${company?.name ?? 'Entreprise'}\n'
                                        'Lieu: ${company?.city ?? job.address}\n'
                                        'Contrat: ${job.contract}\n'
                                        'Prix: ${job.price}';
                                    Share.share(text);
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                ),
                                FavoriteButton(
                                  isFavorite: isSaved,
                                  onToggle: onToggleSaved,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company?.name ?? lang.tr('company'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                         const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                              const SizedBox(width: 4),
                              Text(
                                '${company?.city ?? job.address} • ${lang.tr('recently_posted')}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Chips for details
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                   _buildChip(
                     theme, 
                     icon: Icons.access_time, 
                     label: job.contract,
                     color: Colors.purple,
                   ),
                   _buildChip(
                     theme, 
                     icon: Icons.work_outline, 
                     label: job.pricingType == 'per day' ? lang.tr('per_day') : lang.tr('per_hour'),
                      color: Colors.blue,
                   ),
                   _buildChip(
                     theme, 
                     icon: Icons.attach_money, 
                     label: '${job.price}',
                      color: Colors.green,
                   ),
                ],
              ),
              
              if (job.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  job.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              if (showApplyButton) ...[
                 const SizedBox(height: 20),
                 const Divider(),
                 const SizedBox(height: 8),

                 // Action Buttons
                 Row(
                   children: [
                      Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '${job.applicantsIds.length} ${lang.tr('applicants')}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                     const Spacer(),
                     BouncingButton(
                       onPressed: () {
                           Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(jobId: job.id),
                            ),
                          );
                       },
                       child: TextButton(
                          onPressed: null, // BouncingButton handles tap
                          child: Text(lang.tr('view_details')),
                       ),
                     ),
                     const SizedBox(width: 8),
                     BouncingButton(
                       onPressed: (hasApplied == true) ? onViewApplication : onApply,
                       child: FilledButton.icon(
                         onPressed: null, // BouncingButton handles tap
                         style: FilledButton.styleFrom(
                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                           backgroundColor: (hasApplied == true) ? Colors.blueGrey : null,
                         ),
                         icon: Icon((hasApplied == true) ? Icons.visibility : Icons.send, size: 18),
                         label: Text((hasApplied == true)
                             ? (lang.tr('view_application') ?? 'Voir candidature')
                             : lang.tr('apply')),
                       ),
                     ),
                   ],
                 ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
