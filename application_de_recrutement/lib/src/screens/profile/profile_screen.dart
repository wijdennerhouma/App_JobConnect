import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/api_config.dart';
import '../../core/translations.dart';
import '../../services/resume_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import 'manage_cv_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _resumeData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthState>();
      final userService = UserService(auth);
      final resumeService = ResumeService(auth);

      // Charger les données utilisateur
      final userData = await userService.getProfile(auth.userId!);
      
      // Charger le CV si candidat
      Map<String, dynamic>? resumeData;
      if (auth.isEmployee) {
        try {
          resumeData = await resumeService.getByUser(auth.userId!);
        } catch (e) {
          // CV n'existe pas encore, c'est normal
          resumeData = null;
        }
      }

      setState(() {
        _userData = userData;
        _resumeData = resumeData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement : $e';
        _loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthState>().clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          userData: _userData,
          resumeData: _resumeData,
        ),
      ),
    );

    if (result == true) {
      _loadProfileData(); // Recharger après modification
    }
  }

  Future<void> _updateName(String newName) async {
    try {
      final auth = context.read<AuthState>();
      final userService = UserService(auth);

      // Envoyer la mise à jour au backend
      final updatedUser = await userService.updateProfile(auth.userId!, {'name': newName});

      // Mettre à jour les données localement
      setState(() {
        _userData = updatedUser;
      });

      if (mounted) {
        final lang = context.read<AppSettings>().language;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.tr('name_updated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        final lang = context.read<AppSettings>().language;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lang.tr('error_updating_name')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final settings = context.watch<AppSettings>();
    final lang = settings.language;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.tr('profile_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.tr('profile_title'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfileData,
                child: Text(lang.tr('cancel')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr('profile_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo de profil avec nom et rôle
            Center(
              child: Column(
                children: [
                  ClipOval(
                    child: _userData?['avatar'] != null && _userData!['avatar'].toString().isNotEmpty
                        ? Image.network(
                            '${ApiConfig.baseUrl}/uploads/avatars/${_userData!['avatar']}',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                              );
                            },
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['firstName'] != null && _userData!['firstName'].toString().isNotEmpty
                        ? '${_userData!['firstName']} ${_userData?['name'] ?? ''}' 
                        : (_userData?['name'] ?? 'Nom non renseigné'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: auth.isEmployee ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      auth.isEmployee ? lang.tr('candidate_type') : lang.tr('company_type'),
                      style: TextStyle(
                        color: auth.isEmployee ? Colors.blue[300] : Colors.green[300],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Informations personnelles
            _buildSectionTitle(lang.tr('personal_info')),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.email, lang.tr('email_label'), _userData?['email'] ?? lang.tr('not_provided')),
              if (_userData?['phoneNumber'] != null && _userData!['phoneNumber'].toString().isNotEmpty)
                _buildInfoRow(Icons.phone, lang.tr('phone_label'), _userData!['phoneNumber']),
              if (_userData?['city'] != null && _userData!['city'].toString().isNotEmpty)
                _buildInfoRow(Icons.location_city, lang.tr('city_label'), _userData!['city']),
              if (_userData?['address'] != null && _userData!['address'].toString().isNotEmpty)
                _buildInfoRow(Icons.home, lang.tr('address_label'), _userData!['address']),
              if (_userData?['country'] != null && _userData!['country'].toString().isNotEmpty)
                _buildInfoRow(Icons.public, lang.tr('country_label'), _userData!['country']),
              if (_userData?['postalCode'] != null && _userData!['postalCode'].toString().isNotEmpty)
                _buildInfoRow(Icons.markunread_mailbox, lang.tr('postal_code_label'), _userData!['postalCode']),
            ]),

            const SizedBox(height: 24),

            // CV (pour les candidats)
            if (auth.isEmployee) ...[
              // Section À propos / Résumé professionnel
              // Section À propos / Résumé professionnel
              _buildSectionTitle(lang.tr('about_me')),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    (_userData != null && _userData!['bio'] != null && _userData!['bio'].toString().isNotEmpty)
                        ? _userData!['bio']
                        : lang.tr('candidate_placeholder_bio'),
                    style: TextStyle(
                      fontSize: 14,
                      color: (_userData != null && _userData!['bio'] != null && _userData!['bio'].toString().isNotEmpty)
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Message informatif si pas de données
              if (_resumeData == null || 
                  ((_resumeData!['workExperience'] == null || (_resumeData!['workExperience'] as List).isEmpty) &&
                   (_resumeData!['education'] == null || (_resumeData!['education'] as List).isEmpty) &&
                   (_resumeData!['skills'] == null || (_resumeData!['skills'] as List).isEmpty) &&
                   (_resumeData!['languages'] == null || (_resumeData!['languages'] as List).isEmpty) &&
                   (_resumeData!['certifications'] == null || (_resumeData!['certifications'] as List).isEmpty))) ...[
                Card(
                  color: Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          lang.tr('complete_profile'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang.tr('complete_profile_promo'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              _buildSectionTitle(lang.tr('curriculum_vitae')),
              const SizedBox(height: 12),
              _buildResumeCard(),
              const SizedBox(height: 24),

              // Expérience professionnelle
              if (_resumeData?['workExperience'] != null && (_resumeData!['workExperience'] as List).isNotEmpty) ...[
                _buildSectionTitle(lang.tr('professional_experience')),
                const SizedBox(height: 12),
                _buildInfoCard(
                  (_resumeData!['workExperience'] as List).map<Widget>((exp) {
                    String startDate = lang.tr('n_a');
                    String endDate = lang.tr('currently');
                    
                    try {
                      if (exp['startDate'] != null) {
                        final date = DateTime.parse(exp['startDate'].toString());
                        startDate = '${date.month.toString().padLeft(2, '0')}/${date.year}';
                      }
                      if (exp['endDate'] != null) {
                        final date = DateTime.parse(exp['endDate'].toString());
                        endDate = '${date.month.toString().padLeft(2, '0')}/${date.year}';
                      }
                    } catch (e) {
                      // Si erreur de parsing, utiliser les valeurs par défaut
                    }
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.work, color: Colors.blue, size: 28),
                        title: Text(
                          exp['jobTitle'] ?? lang.tr('job_not_specified'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.business, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  exp['company'] ?? lang.tr('company_not_specified'),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '$startDate - $endDate',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            if (exp['description'] != null && exp['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                exp['description'],
                                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: exp['description'] != null && exp['description'].toString().isNotEmpty,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Formation
              if (_resumeData?['education'] != null && (_resumeData!['education'] as List).isNotEmpty) ...[
                _buildSectionTitle(lang.tr('education')),
                const SizedBox(height: 12),
                _buildInfoCard(
                  (_resumeData!['education'] as List).map<Widget>((edu) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.school, color: Colors.purple, size: 28),
                        title: Text(
                          edu['degree'] ?? lang.tr('degree'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.account_balance, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(edu['school'] ?? lang.tr('school')),
                              ],
                            ),
                            if (edu['field'] != null && edu['field'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.category, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${lang.tr('field')}: ${edu['field']}'),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${edu['startDate'] ?? lang.tr('n_a')} - ${edu['endDate'] ?? lang.tr('n_a')}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Compétences
              if (_resumeData?['skills'] != null && (_resumeData!['skills'] as List).isNotEmpty) ...[
                _buildSectionTitle(lang.tr('skills')),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_resumeData!['skills'] as List).map<Widget>((skill) {
                    return Chip(
                      avatar: const Icon(Icons.star, size: 16),
                      label: Text('${skill['name'] ?? lang.tr('skill_name')} (${(skill['proficiency'] != null ? lang.tr(skill['proficiency']) : (skill['level'] != null ? lang.tr(skill['level']) : null)) ?? skill['proficiency'] ?? skill['level'] ?? lang.tr('n_a')})'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Langues
              if (_resumeData?['languages'] != null && (_resumeData!['languages'] as List).isNotEmpty) ...[
                _buildSectionTitle(lang.tr('languages')),
                const SizedBox(height: 12),
                _buildInfoCard(
                  (_resumeData!['languages'] as List).map<Widget>((langItem) {
                    return ListTile(
                      leading: const Icon(Icons.language, color: Colors.green),
                      title: Text(langItem['name'] ?? lang.tr('language_name'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text((langItem['proficiency'] != null ? lang.tr(langItem['proficiency']) : (langItem['level'] != null ? lang.tr(langItem['level']) : null)) ?? langItem['proficiency'] ?? langItem['level'] ?? lang.tr('n_a'), style: TextStyle(color: Colors.grey[600])),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Certifications
              if (_resumeData?['certifications'] != null && (_resumeData!['certifications'] as List).isNotEmpty) ...[
                _buildSectionTitle(lang.tr('certifications')),
                const SizedBox(height: 12),
                _buildInfoCard(
                  (_resumeData!['certifications'] as List).map<Widget>((cert) {
                    String dateStr = lang.tr('date_not_specified');
                    try {
                      if (cert['date'] != null) {
                        final date = DateTime.parse(cert['date'].toString());
                        dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                      }
                    } catch (e) {
                      // Utiliser la valeur par défaut
                    }
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.verified, color: Colors.orange, size: 28),
                        title: Text(
                          cert['name'] ?? lang.tr('certification_name'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.business_center, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${lang.tr('issuer')}: ${cert['issuer'] ?? lang.tr('not_provided')}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${lang.tr('date')}: $dateStr', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ],

            // Boutons d'action
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _navigateToEditProfile,
                icon: const Icon(Icons.edit),
                label: Text(lang.tr('edit_profile')),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: Text(lang.tr('logout_button')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(value),
    );
  }

  Widget _buildResumeCard() {
    final hasResume = _resumeData?['file'] != null;
    final lang = context.read<AppSettings>().language;
    
    return GestureDetector(
      onTap: hasResume
          ? () => _displayResume()
          : () => _navigateToEditProfile(),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: hasResume ? Colors.green[300]! : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasResume ? Colors.green[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: hasResume ? Colors.green[600] : Colors.grey[400],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CV',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasResume ? lang.tr('click_to_view') : lang.tr('add_my_cv'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasResume ? Icons.check_circle : Icons.add_circle_outline,
              color: hasResume ? Colors.green[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(String type, dynamic item) async {
    try {
      final auth = context.read<AuthState>();
      final resumeService = ResumeService(auth);

      // We need to work with a copy of the resume data to modify it
      // But _resumeData is just a display map here coming from _loadProfileData
      // So we need to perform the backend update directly and then reload

      if (_resumeData == null) return;
      
      // Construct the list without the deleted item to send to backend update
      final currentList = List<Map<String, dynamic>>.from(_resumeData![type] ?? []);
      
      // Determine which item to remove based on content equality or id if available
      // For now we assume the item object passed is from the list directly
      // But since we are rebuilding, we might need to find it by ID if referenced,
      // or simple value equality if they are small objects.
      // However, for this fix, we will try to remove the matching map.
      
      // Since 'item' comes from the map, we can iterate and remove the one that looks consistent.
      // But wait, the backend update expects the NEW list.
      
      currentList.removeWhere((element) {
          // Compare unique fields or just simple map equality check for now
          // For skills: check name
          if (type == 'skills') return element['name'] == item['name'];
          // For languages: check name
          if (type == 'languages') return element['name'] == item['name'];
          // For education/experience/certifications: check slightly more
          return element.toString() == item.toString(); 
      });

      // Prepare update payload
      // Ideally we should use the schema structure. 
      // If we are just updating one field, we can send { type: newList } to resume update endpoint
      // if the endpoint supports partial updates of the resume document.
      
      // If _resumeData has _id, use it.
      if (_resumeData!.containsKey('_id')) {
        final resumeId = _resumeData!['_id'];
        // Create a payload with just the updated list
        final updatePayload = { type: currentList };
        
        // We need to preserve other fields? The update method usually patches.
        // Let's assume resumeService.update patches.
        await resumeService.update(resumeId.toString(), updatePayload);
        
        await _loadProfileData(); // Reload UI
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item deleted')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting item: $e')));
      }
    }
  }

  Future<void> _displayResume() async {
    if (_resumeData?['file'] == null) return;

    final String fileData = _resumeData!['file'] as String;
    Uint8List bytes;

    try {
      // Si c'est du base64
      bytes = base64Decode(fileData);
    } catch (e) {
      if (mounted) {
        final lang = context.read<AppSettings>().language;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.tr('error_reading_cv'))),
        );
      }
      return;
    }

    // Créer un blob avec le type PDF
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Créer un lien de téléchargement
    final link = html.AnchorElement(href: url)
      ..setAttribute('download', 'CV.pdf')
      ..click();
    
    // Nettoyer
    html.Url.revokeObjectUrl(url);
  }
}

// ==============================================================================
// ÉCRAN DE MODIFICATION DU PROFIL
// ==============================================================================

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? resumeData;

  const EditProfileScreen({
    super.key,
    this.userData,
    this.resumeData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _firstNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _postalCodeController;
  // Nouveau controller pour "A propos" (bio)
  late TextEditingController _bioController;
  
  Uint8List? _profileImageBytes;
  String? _profileImageBase64;
  
  Uint8List? _cvBytes;
  String? _cvFileName;
  
  bool _uploading = false;
  String? _message;

  // Liste des pays
  final List<String> _countries = [
    'France',
    'Tunisie',
    'Maroc',
    'Algérie',
    'Belgique',
    'Suisse',
    'Canada',
    'États-Unis',
    'Royaume-Uni',
    'Allemagne',
    'Espagne',
    'Italie',
    'Autre'
  ];


  late Map<String, dynamic> _localResumeData;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData?['name'] ?? '');
    _firstNameController = TextEditingController(text: widget.userData?['firstName'] ?? '');
    _emailController = TextEditingController(text: widget.userData?['email'] ?? '');
    _phoneController = TextEditingController(text: widget.userData?['phoneNumber'] ?? '');
    _addressController = TextEditingController(text: widget.userData?['address'] ?? '');
    _cityController = TextEditingController(text: widget.userData?['city'] ?? '');
    _countryController = TextEditingController(text: widget.userData?['country'] ?? '');
    _postalCodeController = TextEditingController(text: widget.userData?['postalCode'] ?? '');
    
    // Initialisation du champ bio
    _bioController = TextEditingController(text: widget.userData?['bio'] ?? '');
    
    _localResumeData = Map<String, dynamic>.from(widget.resumeData ?? {});

    // Charger l'image existante depuis l'avatar
    _loadCurrentAvatar();
  }

  Future<void> _loadCurrentAvatar() async {
    final avatar = widget.userData?['avatar'];
    if (avatar != null && avatar.toString().isNotEmpty) {
      try {
        final imageUrl = '${ApiConfig.baseUrl}/uploads/avatars/$avatar';
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          setState(() {
            _profileImageBytes = response.bodyBytes;
            _profileImageBase64 = base64Encode(_profileImageBytes!);
          });
        }
      } catch (e) {
        // Ignorer l'erreur si l'image ne peut pas être chargée
        // L'image sera chargée via NetworkImage dans l'UI
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // --- Helpers for Inline CV Management ---

  DateTime _parseDate(String dateStr) {
    try {
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length >= 2) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          return DateTime(year, month);
        }
      }
    } catch (e) {
      // Ignore
    }
    return DateTime.now();
  }

  String _formatDateForDisplay(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = _parseDate(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _saveToDatabase(String type, Map<String, dynamic> data) async {
    try {
      setState(() => _uploading = true);
      
      final auth = context.read<AuthState>();
      final resumeService = ResumeService(auth);

      // Update local state immediately
      if (!_localResumeData.containsKey(type)) {
        _localResumeData[type] = [];
      }
      (_localResumeData[type] as List).add(data);

      // Check if resume exists
      bool hasSavedResume = _localResumeData.containsKey('_id');

      if (hasSavedResume) {
        final resumeId = _localResumeData['_id'];
        await resumeService.update(resumeId.toString(), _localResumeData);
      } else {
        final newResume = {
          'userId': auth.userId,
          ...Map<String, dynamic>.from(_localResumeData)..removeWhere((k, v) => k == '_id'),
        };
        final savedResume = await resumeService.create(newResume);
        if (savedResume != null && savedResume.containsKey('_id')) {
          _localResumeData['_id'] = savedResume['_id'];
        }
      }
      
      setState(() => _uploading = false);
    } catch (e) {
      setState(() => _uploading = false);
      _showMessage('Error saving $type: $e', isError: true);
    }
  }

  Future<void> _deleteItem(String type, dynamic item) async {
    try {
      setState(() => _uploading = true);
      final auth = context.read<AuthState>();
      final resumeService = ResumeService(auth);

      if (_localResumeData.containsKey(type)) {
        (_localResumeData[type] as List).remove(item);
      }

      if (_localResumeData.containsKey('_id')) {
        await resumeService.update(_localResumeData['_id'].toString(), _localResumeData);
      }
      
      setState(() => _uploading = false);
    } catch (e) {
      setState(() => _uploading = false);
      _showMessage('Error deleting item: $e', isError: true);
    }
  }

  void _addWorkExperience() {
    final lang = context.read<AppSettings>().language;
    String jobTitle = '';
    String company = '';
    String startDate = '2023-01';
    String endDate = '2024-01';
    String description = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lang.tr('add_work_experience')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: lang.tr('job_title'), border: const OutlineInputBorder()),
                  onChanged: (v) => jobTitle = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(labelText: lang.tr('company'), border: const OutlineInputBorder()),
                  onChanged: (v) => company = v,
                ),
                const SizedBox(height: 12),
                _buildDateDialogField(lang.tr('start_date'), startDate, (val) => setState(() => startDate = val)),
                const SizedBox(height: 12),
                _buildDateDialogField(lang.tr('end_date'), endDate, (val) => setState(() => endDate = val)),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(labelText: lang.tr('description'), border: const OutlineInputBorder()),
                  maxLines: 3,
                  onChanged: (v) => description = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.tr('cancel'))),
            ElevatedButton(
              onPressed: () {
                _saveToDatabase('workExperience', {
                  'jobTitle': jobTitle,
                  'company': company,
                  'startDate': startDate,
                  'endDate': endDate,
                  'description': description,
                });
                Navigator.pop(context);
              },
              child: Text(lang.tr('add')),
            ),
          ],
        ),
      ),
    );
  }

  void _addEducation() {
    final lang = context.read<AppSettings>().language;
    String degree = 'Diplôme';
    String school = 'École/Université';
    String startDate = '2020-09';
    String endDate = '2023-06';
    String field = 'Domaine';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lang.tr('add_education_dialog')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: lang.tr('degree'), border: const OutlineInputBorder()),
                  onChanged: (v) => degree = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(labelText: lang.tr('school'), border: const OutlineInputBorder()),
                  onChanged: (v) => school = v,
                ),
                const SizedBox(height: 12),
                TextField(
                   decoration: InputDecoration(labelText: lang.tr('study_field'), border: const OutlineInputBorder()),
                   onChanged: (v) => field = v,
                ),
                const SizedBox(height: 12),
                _buildDateDialogField(lang.tr('start_date'), startDate, (val) => setState(() => startDate = val)),
                const SizedBox(height: 12),
                 _buildDateDialogField(lang.tr('end_date'), endDate, (val) => setState(() => endDate = val)),
              ],
            ),
          ),
           actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.tr('cancel'))),
            ElevatedButton(
              onPressed: () {
                _saveToDatabase('education', {
                  'degree': degree,
                  'school': school,
                  'startDate': startDate,
                  'endDate': endDate,
                  'field': field,
                });
                Navigator.pop(context);
              },
              child: Text(lang.tr('add')),
            ),
          ],
        ),
      ),
    );
  }

  void _addSkill() {
    final lang = context.read<AppSettings>().language;
    String selectedSkill = ''; // Start empty to force user interaction
    String selectedLevel = 'intermediate';

    // List of common skills for autocomplete
    final List<String> commonSkills = [
      'Flutter', 'Dart', 'Java', 'Python', 'JavaScript', 'TypeScript', 'React', 'Angular', 'Vue.js',
      'Node.js', 'Express', 'NestJS', 'Spring Boot', 'PHP', 'Laravel', 'Symfony',
      'C++', 'C#', '.NET', 'Go', 'Rust', 'Swift', 'Kotlin', 'Objective-C',
      'SQL', 'PostgreSQL', 'MySQL', 'MongoDB', 'Redis', 'Firebase', 'Supabase',
      'Docker', 'Kubernetes', 'AWS', 'Google Cloud', 'Azure', 'DevOps', 'CI/CD',
      'Git', 'GitHub', 'GitLab', 'Jira', 'Agile', 'Scrum',
      'Communication', 'Leadership', 'Teamwork', 'Problem Solving', 'Time Management', 'Critical Thinking',
      'English', 'French', 'Arabic', 'Spanish', 'German'
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lang.tr('add_skill_dialog')),
          content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return commonSkills.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    selectedSkill = selection;
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                    // Update selectedSkill whenever text changes, to allow custom skills
                    fieldTextEditingController.addListener(() {
                      selectedSkill = fieldTextEditingController.text;
                    });
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        labelText: lang.tr('skill_name'), 
                        border: const OutlineInputBorder(),
                        hintText: 'Ex: Flutter, Python...',
                      ),
                    );
                  },
               ),
               const SizedBox(height: 12),
               DropdownButtonFormField<String>(
                 value: selectedLevel,
                 decoration: InputDecoration(labelText: lang.tr('level'), border: const OutlineInputBorder()),
                 items: ['beginner', 'intermediate', 'fluent'].map((l) => DropdownMenuItem(value: l, child: Text(lang.tr(l)))).toList(),
                 onChanged: (v) => setState(() => selectedLevel = v!),
               ),
             ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.tr('cancel'))),
            ElevatedButton(
              onPressed: () {
                if (selectedSkill.trim().isEmpty) return;
                
                _saveToDatabase('skills', {'name': selectedSkill.trim(), 'proficiency': selectedLevel});
                Navigator.pop(context);
                
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(lang.tr('skill_added_success') ?? 'Compétence ajoutée avec succès')),
                   );
                }
              },
              child: Text(lang.tr('add')),
            ),
          ],
        ),
      ),
    );
  }

  void _addLanguage() {
    final lang = context.read<AppSettings>().language;
    String selectedLanguage = '';
    String selectedLevel = 'fluent';

    // List of common languages
    final List<String> commonLanguages = [
      'Anglais', 'Français', 'Arabe', 'Espagnol', 'Allemand', 'Italien', 
      'Chinois', 'Japonais', 'Russe', 'Portugais', 'Néerlandais', 'Coréen',
      'Turc', 'Hindi', 'Bengali', 'Ourdou', 'Indonésien', 'Swahili'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(lang.tr('add_language_dialog')),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return commonLanguages.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    selectedLanguage = selection;
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                    fieldTextEditingController.addListener(() {
                      selectedLanguage = fieldTextEditingController.text;
                    });
                    return TextField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: InputDecoration(
                        labelText: lang.tr('language_name'), 
                        border: const OutlineInputBorder(),
                        hintText: 'Ex: Anglais, Français...',
                      ),
                    );
                  },
               ),
               const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                 value: selectedLevel,
                 decoration: InputDecoration(labelText: lang.tr('level'), border: const OutlineInputBorder()),
                 items: ['beginner', 'intermediate', 'fluent'].map((l) => DropdownMenuItem(value: l, child: Text(lang.tr(l)))).toList(),
                 onChanged: (v) => setState(() => selectedLevel = v!),
               ),
             ],
           ),
            actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.tr('cancel'))),
            ElevatedButton(
              onPressed: () {
                if (selectedLanguage.trim().isEmpty) return;
                
                _saveToDatabase('languages', {'name': selectedLanguage.trim(), 'proficiency': selectedLevel});
                Navigator.pop(context);
                
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(lang.tr('language_added_success') ?? 'Langue ajoutée avec succès')),
                   );
                }
              },
              child: Text(lang.tr('add')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDialogField(String label, String currentDate, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        hintText: 'YYYY-MM',
      ),
      readOnly: true,
      controller: TextEditingController(text: currentDate),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _parseDate(currentDate),
          firstDate: DateTime(1990),
          lastDate: DateTime(2030),
        );
        if (pickedDate != null) {
          onChanged('${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}');
        }
      },
    );
  }

  void _showImageDialog() {
    ImageProvider? imageProvider;
    if (_profileImageBytes != null) {
      imageProvider = MemoryImage(_profileImageBytes!);
    } else if (widget.userData?['avatar'] != null && widget.userData!['avatar'].toString().isNotEmpty) {
      imageProvider = NetworkImage('${ApiConfig.baseUrl}/uploads/avatars/${widget.userData!['avatar']}');
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 10),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageProvider != null
                      ? Image(
                          image: imageProvider,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 300,
                              height: 300,
                              color: Colors.grey[800],
                              child: const Icon(Icons.person, size: 100, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          width: 300,
                          height: 300,
                          color: Colors.grey[800],
                          child: const Icon(Icons.person, size: 100, color: Colors.grey),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickProfileImage();
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Modifier la photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _profileImageBytes = result.files.single.bytes;
          _profileImageBase64 = base64Encode(_profileImageBytes!);
        });
      }
    } catch (e) {
      _showMessage('Erreur lors de la sélection de l\'image : $e', isError: true);
    }
  }

  Future<void> _pickCv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _cvBytes = result.files.single.bytes;
          _cvFileName = result.files.single.name;
          _localResumeData['file'] = _cvFileName; // Update local state for UI
        });
      }
    } catch (e) {
      _showMessage('Erreur lors de la sélection du CV : $e', isError: true);
    }
  }

  void _deleteCv() {
    setState(() {
      _cvBytes = null;
      _cvFileName = null;
      _localResumeData['file'] = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _uploading = true;
      _message = null;
    });

    try {
      final auth = context.read<AuthState>();
      final userService = UserService(auth);
      final resumeService = ResumeService(auth);

      // Mettre à jour les informations utilisateur
      final userUpdateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty) 'phoneNumber': _phoneController.text.trim(),
        if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
        if (_cityController.text.trim().isNotEmpty) 'city': _cityController.text.trim(),
        if (_countryController.text.trim().isNotEmpty) 'country': _countryController.text.trim(),
        if (_postalCodeController.text.trim().isNotEmpty) 'postalCode': _postalCodeController.text.trim(),
        // Ajouter le champ bio si supporté par le backend
        if (_bioController.text.trim().isNotEmpty) 'bio': _bioController.text.trim(),
        if (auth.isEmployee && _firstNameController.text.trim().isNotEmpty) 'firstName': _firstNameController.text.trim(),
      };
      await userService.updateProfile(auth.userId!, userUpdateData);

      // Mettre à jour l'avatar si une nouvelle image a été sélectionnée
      if (_profileImageBytes != null) {
        final tempFile = PlatformFile(
          name: 'avatar.jpg',
          bytes: _profileImageBytes,
          size: _profileImageBytes!.length,
        );
        await userService.updateAvatar(auth.userId!, tempFile);
      }

      // Mettre à jour ou créer le CV si candidat
      if (auth.isEmployee) {
        final resumeId = widget.resumeData?['_id']?.toString() ?? _localResumeData['_id']?.toString();
        
        if (resumeId != null) {
          final Map<String, dynamic> updateData = {};
          
          if (_cvBytes != null) {
            updateData['file'] = base64Encode(_cvBytes!);
          } else if (_localResumeData['file'] == null) {
             // Si le fichier est null localement, c'est qu'il a été supprimé
             updateData['file'] = null;
          }
          
          if (updateData.isNotEmpty) {
            await resumeService.update(resumeId, updateData);
          }
        } else if (_cvBytes != null) {
          // Créer un nouveau CV seulement si un fichier est sélectionné
          await resumeService.create({
            'userId': auth.userId,
            'file': base64Encode(_cvBytes!),
          });
        }
      }

      final lang = context.read<AppSettings>().language;
      _showMessage(lang.tr('profile_updated_success'), isError: false);
      
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      final lang = context.read<AppSettings>().language;
      _showMessage('${lang.tr('error_updating_profile')}: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showMessage(String msg, {required bool isError}) {
    setState(() => _message = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthState>();
    final lang = context.watch<AppSettings>().language;

    return Scaffold(
      appBar: AppBar(title: Text(lang.tr('edit_profile_title')), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImageDialog,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _profileImageBytes != null
                                ? MemoryImage(_profileImageBytes!)
                                : (widget.userData?['avatar'] != null && widget.userData!['avatar'].toString().isNotEmpty
                                    ? NetworkImage('${ApiConfig.baseUrl}/uploads/avatars/${widget.userData!['avatar']}')
                                    : null),
                            child: _profileImageBytes == null && (widget.userData?['avatar'] == null || widget.userData!['avatar'].toString().isEmpty)
                                ? Icon(Icons.person, size: 60, color: Colors.grey[400]) : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(lang.tr('edit_photo'), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- About Me ---
              if (auth.isEmployee) ...[
                Text(lang.tr('about_me'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: lang.tr('candidate_placeholder_bio'),
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // --- Personal Info ---
              Text(lang.tr('personal_info'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (auth.isEmployee) ...[
                        _buildTextField(
                          controller: _firstNameController, 
                          label: lang.tr('first_name_label') ?? 'Prénom', 
                          icon: Icons.person_outline, 
                          validator: (v) => (v == null || v.trim().isEmpty) ? lang.tr('required_field') : null
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField(controller: _nameController, label: lang.tr('name_label'), icon: Icons.person_outline, validator: (v) => (v == null || v.trim().isEmpty) ? lang.tr('please_enter_name') : null),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _emailController, label: lang.tr('email'), icon: Icons.email_outlined, readOnly: true, filled: true),
                      const SizedBox(height: 16),
                      _buildTextField(controller: _phoneController, label: lang.tr('phone_label'), icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Location ---
              Text(lang.tr('location'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(controller: _addressController, label: lang.tr('address_label'), icon: Icons.home_outlined),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller: _cityController, label: lang.tr('city_label'), icon: Icons.location_city_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(controller: _postalCodeController, label: lang.tr('postal_code_label'), icon: Icons.markunread_mailbox_outlined, keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _countries.contains(_countryController.text) ? _countryController.text : null,
                        decoration: InputDecoration(
                          labelText: lang.tr('country_label'),
                          prefixIcon: Icon(Icons.public_outlined, color: Colors.grey[600]),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _countries.map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _countryController.text = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ============================================
              // INLINE CV MANAGEMENT (Work, Education, Skills, Lang)
              // ============================================
              if (auth.isEmployee) ...[
                // --- Experience ---
                _buildSectionHeader(lang.tr('experience'), _addWorkExperience),
                if ((_localResumeData['workExperience'] as List? ?? []).isEmpty)
                   Padding(padding: const EdgeInsets.only(bottom: 24), child: Text(lang.tr('no_data'), style: TextStyle(color: Colors.grey[500]))),
                ...(_localResumeData['workExperience'] as List? ?? []).map((exp) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.work_outline, color: Colors.blue)),
                    title: Text(exp['jobTitle'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${exp['company'] ?? ""} • ${_formatDateForDisplay(exp['startDate'])} - ${_formatDateForDisplay(exp['endDate'])}'),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteItem('workExperience', exp)),
                  ),
                )),
                const SizedBox(height: 12),

                // --- Education ---
                _buildSectionHeader(lang.tr('education_tab'), _addEducation),
                if ((_localResumeData['education'] as List? ?? []).isEmpty)
                   Padding(padding: const EdgeInsets.only(bottom: 24), child: Text(lang.tr('no_data'), style: TextStyle(color: Colors.grey[500]))),
                 ...(_localResumeData['education'] as List? ?? []).map((edu) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.school_outlined, color: Colors.green)),
                    title: Text(edu['degree'] ?? 'Diplôme', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${edu['school'] ?? ""} • ${_formatDateForDisplay(edu['startDate'])} - ${_formatDateForDisplay(edu['endDate'])}'),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteItem('education', edu)),
                  ),
                )),
                const SizedBox(height: 12),

                // --- Skills ---
                _buildSectionHeader(lang.tr('skills_tab'), _addSkill),
                 if ((_localResumeData['skills'] as List? ?? []).isEmpty)
                   Padding(padding: const EdgeInsets.only(bottom: 24), child: Text(lang.tr('no_data'), style: TextStyle(color: Colors.grey[500]))),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: (_localResumeData['skills'] as List? ?? []).map((skill) {
                     final name = skill is Map ? skill['name'] : skill.toString();
                     final levelKey = skill is Map ? skill['level'] : '';
                     return Chip(
                       label: Text('$name ${levelKey != null ? "(${lang.tr(levelKey)})" : ""}'),
                       onDeleted: () => _deleteItem('skills', skill),
                       backgroundColor: Colors.blue.withOpacity(0.1),
                     );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // --- Languages ---
                _buildSectionHeader(lang.tr('languages_tab'), _addLanguage),
                 if ((_localResumeData['languages'] as List? ?? []).isEmpty)
                   Padding(padding: const EdgeInsets.only(bottom: 24), child: Text(lang.tr('no_data'), style: TextStyle(color: Colors.grey[500]))),
                ...(_localResumeData['languages'] as List? ?? []).map((l) {
                   final name = l is Map ? l['name'] : l.toString();
                   final levelKey = l is Map ? l['level'] : '';
                   return Card(
                     margin: const EdgeInsets.only(bottom: 8),
                     child: ListTile(
                       leading: const Icon(Icons.language, color: Colors.purple),
                       title: Text(name),
                       trailing: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           if(levelKey != null) Text(lang.tr(levelKey), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                           IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => _deleteItem('languages', l)),
                         ],
                       ),
                     ),
                   );
                }),
                const SizedBox(height: 24),
              ],


              // --- CV File ---
              if (auth.isEmployee) ...[
                Text(lang.tr('curriculum_vitae'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: (_localResumeData['file'] != null) ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.description_outlined, color: (_localResumeData['file'] != null) ? Colors.green : Colors.grey),
                          ),
                          title: Text((_localResumeData['file'] != null) ? lang.tr('cv_available') : lang.tr('no_cv'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(_cvFileName != null ? '${lang.tr('new_cv')}: $_cvFileName' : _localResumeData['file'] != null ? lang.tr('pdf_uploaded') : lang.tr('no_file'), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_localResumeData['file'] != null)
                                IconButton(
                                   onPressed: _deleteCv,
                                   icon: const Icon(Icons.delete_outline, color: Colors.red),
                                   tooltip: lang.tr('delete'),
                                ),
                              FilledButton.icon(
                                onPressed: _pickCv,
                                icon: Icon(_localResumeData['file'] != null ? Icons.edit : Icons.upload_file, size: 18),
                                label: Text(_localResumeData['file'] != null ? lang.tr('change') : lang.tr('add')),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2), // Professional Blue
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

               // Message
              if (_message != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _message!.startsWith('Error') ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_message!, style: TextStyle(color: _message!.startsWith('Error') ? Colors.red : Colors.green)),
                ),
                const SizedBox(height: 16),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _uploading ? null : _saveProfile,
                  icon: _uploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                  label: Text(_uploading ? lang.tr('saving_in_progress') : lang.tr('save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
         IconButton(onPressed: onAdd, icon: const Icon(Icons.add_circle_outline, color: Colors.blue)),
       ],
     );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool readOnly = false, bool filled = false, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller, readOnly: readOnly, keyboardType: keyboardType, validator: validator,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: Colors.grey[600]), filled: filled, fillColor: filled ? Colors.grey.withOpacity(0.1) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }
}