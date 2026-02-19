import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_settings.dart';
import '../../core/auth_state.dart';
import '../../core/translations.dart';
import '../../services/user_service.dart';
import '../../services/application_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _isLoading = true;
  bool _isPublicProfile = true;
  bool _showEmail = false;
  bool _showPhone = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final auth = context.read<AuthState>();
      if (auth.userId == null) return;
      
      final userService = UserService(auth);
      final profile = await userService.getProfile(auth.userId!);
      
      if (mounted) {
        setState(() {
          _isPublicProfile = profile['isPublicProfile'] ?? true;
          _showEmail = profile['showEmail'] ?? false;
          _showPhone = profile['showPhoneNumber'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    // Optimistic update
    final backupPublic = _isPublicProfile;
    final backupEmail = _showEmail;
    final backupPhone = _showPhone;

    setState(() {
      if (key == 'isPublicProfile') _isPublicProfile = value;
      if (key == 'showEmail') _showEmail = value;
      if (key == 'showPhoneNumber') _showPhone = value;
    });

    try {
      final auth = context.read<AuthState>();
      final userService = UserService(auth);
      
      await userService.updateProfile(auth.userId!, {
        key: value,
      });

    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isPublicProfile = backupPublic;
          _showEmail = backupEmail;
          _showPhone = backupPhone;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Future<void> _downloadData() async {
    final lang = context.read<AppSettings>().language;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lang.tr('download_data_in_progress'))),
    );

    try {
      final auth = context.read<AuthState>();
      if (auth.userId == null) return;

      final userService = UserService(auth);
      final applicationService = ApplicationService(auth);

      // 1. Profile
      final profile = await userService.getProfile(auth.userId!);

      // 2. Saved Jobs
      List<dynamic> savedJobs = [];
      try {
        savedJobs = await userService.getSavedJobs(auth.userId!);
      } catch (e) {
        debugPrint('Error fetching saved jobs: $e');
      }

      // 3. Applications
      List<Map<String, dynamic>> applicationsList = [];
      try {
        final apps = await applicationService.byApplicant(auth.userId!);
        applicationsList = apps.map((app) => {
          'id': app.id,
          'jobId': app.jobId,
          'entrepriseId': app.entrepriseId,
          'status': app.status,
          'jobTitle': app.job?.title,
        }).toList();
      } catch (e) {
        debugPrint('Error fetching applications: $e');
      }

      final fullData = {
        'user_profile': profile,
        'saved_jobs': savedJobs,
        'applications': applicationsList,
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(fullData);
      
      final xFile = XFile.fromData(
        Uint8List.fromList(utf8.encode(jsonString)),
        mimeType: 'application/json', 
        name: 'jobconnect_data_${auth.userId}.json',
      );

      final box = context.findRenderObject() as RenderBox?;
      
      await Share.shareXFiles(
        [xFile], 
        text: lang.tr('download_my_data'),
        subject: 'JobConnect Data Export',
        sharePositionOrigin: box != null ? (box.localToGlobal(Offset.zero) & box.size) : null,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lang.tr('error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.tr('privacy_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('privacy_title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.visibility, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        lang.tr('profile_visibility'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(lang.tr('public_profile')),
                    subtitle: Text(lang.tr('allow_companies_view_profile')),
                    value: _isPublicProfile,
                    onChanged: (value) => _updateSetting('isPublicProfile', value),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(lang.tr('show_my_email')),
                    subtitle: Text(lang.tr('allow_companies_view_email')),
                    value: _showEmail,
                    onChanged: (value) => _updateSetting('showEmail', value),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(lang.tr('show_my_phone')),
                    subtitle: Text(lang.tr('allow_companies_view_phone')),
                    value: _showPhone,
                    onChanged: (value) => _updateSetting('showPhoneNumber', value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.data_usage, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        lang.tr('data_section'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: Text(lang.tr('download_my_data')),
                    subtitle: Text(lang.tr('get_copy_of_data')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _downloadData();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: Text(lang.tr('delete_account'), style: const TextStyle(color: Colors.red)),
                    subtitle: Text(lang.tr('irreversible_action')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showDeleteAccountDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final lang = context.read<AppSettings>().language;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.tr('delete_account')),
        content: Text(lang.tr('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final auth = context.read<AuthState>();
                if (auth.userId != null) {
                  final userService = UserService(auth);
                  await userService.deleteAccount(auth.userId!);
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Close loading
                    await auth.clear(); // Logout
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${lang.tr('error')}: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang.tr('delete')),
          ),
        ],
      ),
    );
  }
}
