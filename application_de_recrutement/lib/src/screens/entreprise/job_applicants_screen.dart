import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../core/api_config.dart';
import '../../models/app_application.dart';
import '../../models/job.dart';
import '../../services/application_service.dart';
import '../../services/resume_service.dart';
import '../../models/user.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import '../chat/chat_screen.dart';
import '../employee/widgets/application_stats_chart.dart';

class JobApplicantsScreen extends StatefulWidget {
  const JobApplicantsScreen({super.key, required this.job});

  final Job job;

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  late Future<List<ApplicationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ApplicationItem>> _load() async {
    final auth = context.read<AuthState>();
    return ApplicationService(auth).byJob(widget.job.id);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.grey[50];
    final appBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor, 
      appBar: AppBar(
        title: Text(
          '${lang.tr('applicants')} - ${widget.job.title}',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        backgroundColor: appBarColor,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        elevation: 0,
      ),
      body: FutureBuilder<List<ApplicationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${lang.tr('error_prefix')}: ${snapshot.error}'));
          }
          final apps = snapshot.data ?? [];
          if (apps.isEmpty) {
            return Center(child: Text(lang.tr('no_applicants_yet')));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: apps.length + 1, // +1 for summary stats
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSummaryCards(apps, lang, theme);
              }
              final app = apps[index - 1];
              return _buildApplicantCard(context, app, theme, lang);
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(List<ApplicationItem> apps, AppLanguage lang, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            lang.tr('statistics') ?? 'Statistiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ApplicationStatsChart(applications: apps),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildApplicantCard(BuildContext context, ApplicationItem app, ThemeData theme, AppLanguage lang) {
    final applicant = app.applicant;
    String name = lang.tr('candidate') ?? 'Candidat';
    if (applicant != null) {
       final hasFirst = applicant.firstName != null && applicant.firstName!.isNotEmpty;
       final hasName = applicant.name.isNotEmpty;
       if (hasFirst && hasName) {
         name = '${applicant.firstName} ${applicant.name}';
       } else if (hasFirst) {
         name = applicant.firstName!;
       } else if (hasName) {
         name = applicant.name;
       }
    }
    final avatar = applicant?.avatar;
    final headline = applicant?.bio ?? '${lang.tr('candidate') ?? 'Candidat'} • ${applicant?.city ?? 'Tunis'}';
    final hasCoverLetter = app.coverLetter != null && app.coverLetter!.isNotEmpty;

    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.blueGrey[200] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor, // Premium dark card or white
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showApplicationDetails(context, app),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipOval(
                          child: avatar != null && avatar.isNotEmpty
                            ? Image.network(
                                '${ApiConfig.baseUrl}/uploads/avatars/$avatar',
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(name),
                              )
                            : _buildPlaceholderAvatar(name),
                        ),
                        if (app.status == 'started' || app.status == 'contract_signed')
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(app.status),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1E293B), width: 2),
                              ),
                              child: const Icon(Icons.star, size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(app.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatStatus(app.status, lang),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(app.status),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent, size: 20),
                                onPressed: () {
                                  if (applicant != null) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUser: applicant)));
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: lang.tr('send_message'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                onPressed: () => _deleteApplication(app, lang),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: lang.tr('delete'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const SizedBox(height: 4),
                          // Headline + Date
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  headline,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subTextColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (app.createdAt != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _getTimeAgo(app.createdAt!, lang),
                                  style: TextStyle(fontSize: 11, color: Colors.blueGrey[400]),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (applicant?.showEmail == true && applicant?.email != null)
                            Row(
                              children: [
                                Icon(Icons.email_outlined, size: 14, color: Colors.blueGrey[400]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    applicant!.email,
                                    style: TextStyle(fontSize: 12, color: Colors.blueGrey[400]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasCoverLetter) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      app.coverLetter!,
                      style: TextStyle(fontSize: 13, color: subTextColor, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatStatus(String status, AppLanguage lang) {
    switch (status) {
      case 'pending': return lang.tr('status_pending') ?? 'New';
      case 'reviewed': return lang.tr('status_reviewed') ?? 'Viewed';
      case 'accepted': return lang.tr('status_accepted') ?? 'Accepted';
      case 'rejected': return lang.tr('status_rejected') ?? 'Rejected';
      case 'started': return lang.tr('status_started') ?? 'Active';
      case 'contract_signed': return lang.tr('status_signed') ?? 'Hired';
      case 'finished': return lang.tr('status_finished') ?? 'Finished';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.grey;
      case 'reviewed': return Colors.blueAccent;
      case 'accepted': return Colors.greenAccent;
      case 'rejected': return Colors.redAccent;
      case 'started': return Colors.orangeAccent;
      case 'contract_signed': return Colors.purpleAccent;
      case 'finished': return Colors.tealAccent;
      default: return Colors.blueGrey;
    }
  }

  void _showApplicationDetails(BuildContext context, ApplicationItem app) {
    // Automatically mark as viewed if pending
    if (app.status == 'pending') {
      _updateStatus(context, app, 'reviewed', closeModal: false); // Silent update, no pop/refresh yet
    }
    
    final lang = context.read<AppSettings>().language;
    final applicant = app.applicant;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
           final theme = Theme.of(context);
           final isDark = theme.brightness == Brightness.dark;
           final modalBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
           final contentBgColor = isDark ? const Color(0xFF0F172A) : Colors.grey[100];
           final textColor = isDark ? Colors.white : Colors.black87;
           final subTextColor = isDark ? Colors.white70 : (Colors.grey[700] ?? Colors.grey);

           return FutureBuilder<Map<String, dynamic>?>(
             future: applicant != null 
                 ? ResumeService(context.read<AuthState>()).getByUser(applicant.id)
                 : Future.value(null),
             builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
               }
               
               final resumeData = snapshot.data;
               final List<dynamic> workExperience = resumeData?['workExperience'] ?? [];
               final List<dynamic> education = resumeData?['education'] ?? [];
               final List<dynamic> languages = resumeData?['languages'] ?? [];
               final List<dynamic> certifications = resumeData?['certifications'] ?? [];
               final List<dynamic> interests = resumeData?['interests'] ?? []; // Placeholder

               final textTheme = Theme.of(context).textTheme.apply(
                 bodyColor: textColor,
                 displayColor: textColor,
               );

               return Container(
                 decoration: BoxDecoration(
                    color: modalBgColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                 ),
                 child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions de statut
                      // Actions de statut
                      _buildActionButtons(context, app),

                      const SizedBox(height: 32),
                      const SizedBox(height: 32),

                      // Header
                      Row(
                        children: [
                           ClipOval(
                            child: applicant?.avatar != null && applicant!.avatar!.isNotEmpty
                              ? Image.network(
                                  '${ApiConfig.baseUrl}/uploads/avatars/${applicant.avatar}',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderAvatar(applicant?.name),
                                )
                              : _buildPlaceholderAvatar(applicant?.name),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCandidateName(applicant, lang, textColor),
                                if (applicant?.showEmail == true && applicant?.email != null)
                                  Text(
                                    applicant!.email,
                                    style: TextStyle(color: subTextColor, fontSize: 16),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // À propos (Bio)
                      if (applicant?.bio != null && applicant!.bio!.isNotEmpty) ...[
                        Text(
                          lang.tr('about_me') ?? 'À propos',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: contentBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            applicant!.bio!,
                            style: TextStyle(height: 1.5, color: subTextColor),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Lettre de motivation
                      if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
                        Text(
                          lang.tr('cover_letter') ?? 'Lettre de motivation',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: contentBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showFullCoverLetter(context, app.coverLetter!, lang),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.coverLetter!,
                                  style: TextStyle(height: 1.5, color: subTextColor),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lang.tr('click_to_read_more') ?? 'Lire la suite...',
                                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Compétences de la candidature
                      if (app.skills != null && app.skills!.isNotEmpty) ...[
                        Text(
                          lang.tr('skills') ?? 'Compétences déclarées',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: app.skills!.map((skill) => Chip(
                            label: Text(skill),
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            labelStyle: const TextStyle(color: Colors.blueAccent),
                            side: BorderSide.none,
                          )).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Expérience
                      if (workExperience.isNotEmpty) ...[
                        Text(
                          lang.tr('work_experience') ?? 'Expérience Professionnelle',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...workExperience.map((exp) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: contentBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.work, color: Colors.blueAccent),
                            title: Text(exp['jobTitle'] ?? '', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            subtitle: Text('${exp['company'] ?? ''} • ${_formatDate(exp['startDate'])} - ${_formatDate(exp['endDate'])}', style: TextStyle(color: subTextColor)),
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // Formation
                      if (education.isNotEmpty) ...[
                        Text(
                          lang.tr('education') ?? 'Formation',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...education.map((edu) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: contentBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.school, color: Colors.greenAccent),
                            title: Text(edu['degree'] ?? '', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            subtitle: Text('${edu['school'] ?? edu['institution'] ?? ''} • ${_formatDate(edu['startDate'])} - ${_formatDate(edu['endDate'])}', style: TextStyle(color: subTextColor)),
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // Certifications
                      if (certifications.isNotEmpty) ...[
                        Text(
                          lang.tr('certifications') ?? 'Certifications',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...certifications.map((cert) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: contentBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.verified, color: Colors.amber),
                            title: Text(cert['name'] ?? '', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            subtitle: Text('${cert['issuer'] ?? ''} • ${_formatDate(cert['date'])}', style: TextStyle(color: subTextColor)),
                          ),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // Intérêts
                      if (interests.isNotEmpty) ...[
                        Text(
                          lang.tr('interests') ?? 'Centres d\'intérêt',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                         const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: interests.map((interest) => Chip(
                            label: Text(interest.toString()),
                            backgroundColor: Colors.pink.withOpacity(0.2),
                            labelStyle: const TextStyle(color: Colors.pinkAccent),
                            side: BorderSide.none,
                          )).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // CV Download Button
                      if (resumeData != null && resumeData['file'] != null && resumeData['file'].isNotEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _downloadCV(resumeData['file']),
                            icon: const Icon(Icons.download, color: Colors.blueAccent),
                            label: Text(lang.tr('download_resume') ?? 'Télécharger le CV', style: const TextStyle(color: Colors.blueAccent)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blueAccent),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Langues
                      if (languages.isNotEmpty) ...[
                         Text(
                          lang.tr('languages') ?? 'Langues',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: languages.map((l) => Chip(
                            avatar: Icon(Icons.language, size: 16, color: subTextColor),
                            label: Text('${l['name'] ?? l['language'] ?? ''} (${l['proficiency'] ?? ''})'),
                            backgroundColor: contentBgColor,
                            labelStyle: TextStyle(color: textColor),
                            side: BorderSide.none,
                          )).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Competences (from Resume) - separate from application specific skills
                      if (resumeData != null && resumeData['skills'] != null && (resumeData['skills'] as List).isNotEmpty) ...[
                        Text(
                          lang.tr('skills') ?? 'Compétences',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (resumeData['skills'] as List).map((skill) {
                             String skillName = '';
                             if (skill is Map) {
                               skillName = skill['name'] ?? '';
                             } else {
                               skillName = skill.toString();
                             }
                             return Chip(
                              label: Text(skillName),
                              backgroundColor: Colors.purple.withOpacity(0.2),
                              labelStyle: const TextStyle(color: Colors.purpleAccent),
                              side: BorderSide.none,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Info Profil
                      if (applicant != null) ...[
                        Text(
                          lang.tr('candidate_details') ?? 'Détails du candidat',
                          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        const SizedBox(height: 16),
                        if (applicant.showPhoneNumber == true) ...[
                           _buildInfoRow(context, Icons.phone, 'Téléphone', applicant.phoneNumber, textColor, subTextColor),
                           const SizedBox(height: 12),
                        ],
                        _buildInfoRow(context, Icons.location_on, 'Adresse', '${applicant.address ?? ''} ${applicant.postalCode ?? ''} ${applicant.city ?? ''} ${applicant.country ?? ''}', textColor, subTextColor),
                      ],

                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                if (applicant != null) {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(otherUser: applicant)));
                                }
                              },
                              icon: const Icon(Icons.chat, size: 20),
                              label: Text(lang.tr('send_message') ?? 'Envoyer un message'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: isDark ? Colors.white10 : Colors.grey[300],
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(lang.tr('close') ?? 'Fermer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                 ),
               );
              }
            );
        }
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ApplicationItem app) {
      final lang = context.watch<AppSettings>().language;
      // If already accepted or rejected, show current status state prominently
      if (app.status == 'accepted' || app.status == 'contract_signed') {
         return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
                 Text(lang.tr('candidate_accepted') ?? 'Candidature acceptée', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        );
      }
      
      if (app.status == 'rejected') {
         return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: Colors.red),
              const SizedBox(width: 12),
              Text(lang.tr('candidate_rejected') ?? 'Candidature refusée', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        );
      }

      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(context, app, 'rejected'),
              icon: const Icon(Icons.close, color: Colors.white),
              label: Text(lang.tr('reject') ?? 'Refuser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(context, app, 'accepted'),
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(lang.tr('accept') ?? 'Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
  }

  Future<void> _updateStatus(BuildContext context, ApplicationItem app, String status, {bool closeModal = true}) async {
    try {
      final auth = context.read<AuthState>();
      await ApplicationService(auth).updateStatus(app.id, status);
      if (mounted) {
        if (closeModal) {
          Navigator.pop(context); // Close modal
        }
        setState(() {
          _future = _load(); // Refresh list
        });
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      if (mounted && closeModal) { // Only show error for user-initiated actions to avoid spam
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildPlaceholderAvatar(String? name) {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: (name != null && name.isNotEmpty)
        ? Text(
            name[0].toUpperCase(),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          )
        : const Icon(Icons.person, size: 48, color: Colors.white70),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String? value, Color textColor, Color subTextColor) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(icon, size: 20, color: subTextColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: subTextColor.withOpacity(0.7), fontSize: 12)),
            Text(value, style: TextStyle(color: textColor, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildCandidateName(AppUser? applicant, AppLanguage lang, Color textColor) {
    String name = lang.tr('candidate') ?? 'Candidat';
    if (applicant != null) {
      final hasFirst = applicant.firstName != null && applicant.firstName!.isNotEmpty;
      final hasName = applicant.name.isNotEmpty;
      if (hasFirst && hasName) {
        name = '${applicant.firstName} ${applicant.name}';
      } else if (hasFirst) {
        name = applicant.firstName!;
      } else if (hasName) {
        name = applicant.name;
      }
    }
    return Text(
      name,
      style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Future<void> _downloadCV(String fileData) async {
    // Check if it's likely a Base64 string (long and no extension pattern typically)
    // or just try to decode it.
    bool isBase64 = fileData.length > 200 && !fileData.startsWith('http');

    if (isBase64) {
      try {
        final bytes = base64Decode(fileData);
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final link = html.AnchorElement(href: url)
          ..setAttribute('download', 'CV_Candidat.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
        return;
      } catch (e) {
        // Validation failed, proceed to try as URL
        debugPrint('Failed to decode base64 CV, trying as URL: $e');
      }
    }

    // Fallback: Try as URL (legacy or if backend served)
    final url = '${ApiConfig.baseUrl}/uploads/resumes/$fileData';
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error launching CV: $e')),
        );
      }
    }
  }


  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is DateTime) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      if (date is String) {
        if (date.contains('T')) {
           final parsed = DateTime.parse(date);
           return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
        }
        return date;
      }
    } catch (_) {}
    return '';
  }

  String _getTimeAgo(DateTime date, AppLanguage lang) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays} ${lang.tr('days_ago') ?? 'jours'}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ${lang.tr('hours_ago') ?? 'heures'}';
    } else {
      return lang.tr('just_now') ?? 'À l\'instant';
    }
  }

  void _showFullCoverLetter(BuildContext context, String content, AppLanguage lang) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(lang.tr('cover_letter') ?? 'Lettre de motivation'),
            backgroundColor: bgColor,
            iconTheme: IconThemeData(color: textColor),
            titleTextStyle: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                height: 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteApplication(ApplicationItem app, AppLanguage lang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.tr('delete_application') ?? 'Supprimer'),
        content: Text(lang.tr('delete_application_confirm') ?? 'Êtes-vous sûr de vouloir supprimer cette candidature ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(lang.tr('cancel') ?? 'Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
             style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang.tr('delete') ?? 'Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final auth = context.read<AuthState>();
      await ApplicationService(auth).delete(app.id);
      
      setState(() {
        _future = _load(); // Reload to update list and stats
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(lang.tr('application_deleted') ?? 'Candidature supprimée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('${lang.tr('error')}: $e')),
        );
      }
    }
  }
}

