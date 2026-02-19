import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../services/resume_service.dart';

// Liste de toutes les langues
const List<String> allLanguages = [
  'Français',
  'Anglais',
  'Espagnol',
  'Allemand',
  'Italien',
  'Portugais',
  'Néerlandais',
  'Grec',
  'Suédois',
  'Norvégien',
  'Danois',
  'Finlandais',
  'Polonais',
  'Russe',
  'Ukrainien',
  'Tchèque',
  'Hongrois',
  'Roumain',
  'Bulgare',
  'Croate',
  'Serbe',
  'Turc',
  'Arabe',
  'Hébreu',
  'Persan',
  'Ourdou',
  'Hindi',
  'Bengali',
  'Thaï',
  'Vietnamien',
  'Coréen',
  'Japonais',
  'Chinois (Mandarin)',
  'Chinois (Cantonais)',
];

const List<String> languageLevels = [
  // Deprecated: kept for backward compat; UI should use translated labels.
  'beginner',
  'intermediate',
  'fluent',
];

// Liste de compétences courantes
const List<String> commonSkills = [
  'Communication',
  'Leadership',
  'Gestion de projet',
  'Travail d\'équipe',
  'Résolution de problèmes',
  'Pensée critique',
  'Créativité',
  'Adaptabilité',
  'Gestion du temps',
  'Organisation',
  // Techniques informatiques
  'JavaScript',
  'Python',
  'Java',
  'C++',
  'C#',
  'PHP',
  'Ruby',
  'Go',
  'Rust',
  'TypeScript',
  'HTML/CSS',
  'React',
  'Angular',
  'Vue.js',
  'Node.js',
  'Django',
  'Flask',
  'Spring',
  'SQL',
  'MongoDB',
  'PostgreSQL',
  'MySQL',
  'Firebase',
  'Git',
  'Docker',
  'Kubernetes',
  'AWS',
  'Azure',
  'Google Cloud',
  'API REST',
  'GraphQL',
  'Machine Learning',
  'Data Science',
  'Analyse de données',
  'Excel avancé',
  'Power BI',
  'Tableau',
  'Salesforce',
  'SAP',
  'Oracle',
  // Soft skills supplémentaires
  'Négociation',
  'Présentation',
  'Écoute active',
  'Empathie',
  'Flexibilité',
  'Apprentissage continu',
  'Autonomie',
  'Initiative',
  'Planification stratégique',
  'Analyse SWOT',
];

class ManageCVScreen extends StatefulWidget {
  final Map<String, dynamic>? resumeData;

  const ManageCVScreen({
    super.key,
    this.resumeData,
  });

  @override
  State<ManageCVScreen> createState() => _ManageCVScreenState();
}

class _ManageCVScreenState extends State<ManageCVScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> _localResumeData;
  bool _loading = false;
  late AppLanguage _appLang;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _localResumeData = Map<String, dynamic>.from(widget.resumeData ?? {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final settings = context.watch<AppSettings>();
    _appLang = settings.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(_appLang.tr('manage_cv')),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.work), text: _appLang.tr('experience')),
            Tab(icon: const Icon(Icons.school), text: _appLang.tr('education_tab')),
            Tab(icon: const Icon(Icons.star), text: _appLang.tr('skills_tab')),
            Tab(icon: const Icon(Icons.card_membership), text: _appLang.tr('certifications_tab')),
            Tab(icon: const Icon(Icons.language), text: _appLang.tr('languages_tab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkExperienceTab(),
          _buildEducationTab(),
          _buildSkillsTab(),
          _buildCertificationsTab(),
          _buildLanguagesTab(),
        ],
      ),
    );
  }

  Widget _buildWorkExperienceTab() {
    final workExperience = _localResumeData['workExperience'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...workExperience.map((exp) => _buildExperienceCard(exp)),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: _addWorkExperience,
          icon: const Icon(Icons.add),
          label: Text(_appLang.tr('add_experience')),
        ),
      ],
    );
  }

  Widget _buildEducationTab() {
    final education = _localResumeData['education'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...education.map((edu) => _buildEducationCard(edu)),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: _addEducation,
          icon: const Icon(Icons.add),
          label: Text(_appLang.tr('add_education')),
        ),
      ],
    );
  }

  Widget _buildSkillsTab() {
    final skills = _localResumeData['skills'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...skills.map((skill) => _buildSkillChip(skill)),
          ],
        ),
        const SizedBox(height: 24),
        FloatingActionButton.extended(
          onPressed: _addSkill,
          icon: const Icon(Icons.add),
          label: Text(_appLang.tr('add_skill')),
        ),
      ],
    );
  }

  Widget _buildCertificationsTab() {
    final certifications = _localResumeData['certifications'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...certifications.map((cert) => _buildCertificationCard(cert)),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: _addCertification,
          icon: const Icon(Icons.add),
          label: Text(_appLang.tr('add_certification')),
        ),
      ],
    );
  }

  Widget _buildLanguagesTab() {
    final languages = _localResumeData['languages'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...languages.map((lang) => _buildLanguageCard(lang)),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: _addLanguage,
          icon: const Icon(Icons.add),
          label: Text(_appLang.tr('add_language')),
        ),
      ],
    );
  }

  Widget _buildExperienceCard(dynamic exp) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.work_outline, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exp['jobTitle'] ?? 'Sans titre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        exp['company'] ?? _appLang.tr('company'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text(_appLang.tr('delete')),
                      onTap: () => _deleteItem('workExperience', exp),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${exp['startDate']} - ${exp['endDate'] ?? _appLang.tr('currently')}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            if (exp['description'] != null && exp['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                exp['description'],
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEducationCard(dynamic edu) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.school_outlined, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        edu['degree'] ?? _appLang.tr('education'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        edu['school'] ?? _appLang.tr('school'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text(_appLang.tr('delete')),
                      onTap: () => _deleteItem('education', edu),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${edu['startDate']} - ${edu['endDate'] ?? _appLang.tr('currently')}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            if (edu['field'] != null && edu['field'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_appLang.tr('field')}: ${edu['field']}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(dynamic skill) {
    final skillName = skill is Map ? (skill['name'] ?? _appLang.tr('skill_name')) : skill.toString();
    final skillLevelKey = skill is Map ? (skill['level'] ?? '') : '';
    final skillLevel = _appLang.tr(skillLevelKey);
    
    return Chip(
      label: Text(
        skillLevel.isNotEmpty ? '$skillName ($skillLevel)' : skillName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => _deleteItem('skills', skill),
      backgroundColor: Colors.blue.withOpacity(0.15),
      labelStyle: const TextStyle(color: Colors.blue),
      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
    );
  }

  Widget _buildCertificationCard(dynamic cert) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.card_membership, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert['name'] ?? _appLang.tr('certification_name'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    cert['issuer'] ?? 'Émetteur',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(_appLang.tr('delete')),
                  onTap: () => _deleteItem('certifications', cert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(dynamic lang) {
    final langName = lang is Map ? (lang['name'] ?? 'Langue') : lang.toString();
    final langTitle = lang is Map ? (lang['level'] ?? 'level') : 'level';
    final langLevel = _appLang.tr(langTitle);
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.language, size: 18, color: Colors.purple),
        ),
        title: Text(
          langName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(langLevel, style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () => _deleteItem('languages', lang),
        ),
      ),
    );
  }

  void _addWorkExperience() {
    String jobTitle = '';
    String company = '';
    String startDate = '2023-01';
    String endDate = '2024-01';
    String description = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_appLang.tr('add_work_experience')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: _appLang.tr('job_title'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => jobTitle = value,
                      controller: TextEditingController(text: jobTitle),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: _appLang.tr('company'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => company = value,
                      controller: TextEditingController(text: company),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: _appLang.tr('start_date'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        hintText: 'YYYY-MM',
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _parseDate(startDate),
                          firstDate: DateTime(1990),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            startDate = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      controller: TextEditingController(text: startDate),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: _appLang.tr('end_date'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        hintText: 'YYYY-MM',
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _parseDate(endDate),
                          firstDate: DateTime(1990),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            endDate = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      controller: TextEditingController(text: endDate),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: _appLang.tr('description'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) => description = value,
                      controller: TextEditingController(text: description),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_appLang.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final workData = {
                      'jobTitle': jobTitle,
                      'company': company,
                      'startDate': startDate,
                      'endDate': endDate,
                      'description': description,
                    };
                    _saveToDatabase('workExperience', workData);
                    Navigator.pop(context);
                  },
                  child: Text(_appLang.tr('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addEducation() {
    String degree = 'Diplôme';
    String school = 'École/Université';
    String startDate = '2020-09';
    String endDate = '2023-06';
    String field = 'Domaine';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_appLang.tr('add_education_dialog')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: _appLang.tr('degree'),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => degree = value,
                      controller: TextEditingController(text: degree),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(labelText: _appLang.tr('school'),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => school = value,
                      controller: TextEditingController(text: school),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: _appLang.tr('study_field'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => field = value,
                      controller: TextEditingController(text: field),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(labelText: _appLang.tr('start_date'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'YYYY-MM',
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _parseDate(startDate),
                          firstDate: DateTime(1990),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            startDate = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      controller: TextEditingController(text: startDate),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(labelText: _appLang.tr('end_date'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'YYYY-MM',
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _parseDate(endDate),
                          firstDate: DateTime(1990),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            endDate = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      controller: TextEditingController(text: endDate),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_appLang.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final eduData = {
                      'degree': degree,
                      'school': school,
                      'startDate': startDate,
                      'endDate': endDate,
                      'field': field,
                    };
                    _saveToDatabase('education', eduData);
                    Navigator.pop(context);
                  },
                  child: Text(_appLang.tr('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addSkill() {
    String selectedSkill = 'Communication';
    String selectedLevel = 'intermediate'; // Use key directly
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_appLang.tr('add_skill_dialog')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sélection de la compétence avec autocomplétion
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return commonSkills;
                          }
                          return commonSkills.where((String option) {
                            return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          setState(() {
                            selectedSkill = selection;
                          });
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(labelText: _appLang.tr('skill_name'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.star),
                            ),
                            onChanged: (value) {
                              selectedSkill = value;
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Dropdown pour le niveau
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLevel,
                      decoration: InputDecoration(labelText: _appLang.tr('level'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assessment),
                      ),
                      items: languageLevels.map((level) {
                        return DropdownMenuItem(
                          value: level, // Use key
                          child: Text(_appLang.tr(level)), // Translate for display
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLevel = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_appLang.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final skillData = {
                      'name': selectedSkill,
                      'level': selectedLevel,
                    };
                    _saveToDatabase('skills', skillData);
                    Navigator.pop(context);
                  },
                  child: Text(_appLang.tr('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addCertification() {
    String name = 'Certification';
    String issuer = 'Émetteur';
    String date = '2024-01';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_appLang.tr('add_certification_dialog')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: _appLang.tr('certification_name'),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => name = value,
                      controller: TextEditingController(text: name),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: _appLang.tr('issuer'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => issuer = value,
                      controller: TextEditingController(text: issuer),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(labelText: _appLang.tr('date'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: 'YYYY-MM',
                      ),
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _parseDate(date),
                          firstDate: DateTime(1990),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            date = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      controller: TextEditingController(text: date),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_appLang.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final certData = {
                      'name': name,
                      'issuer': issuer,
                      'date': date,
                    };
                    _saveToDatabase('certifications', certData);
                    Navigator.pop(context);
                  },
                  child: Text(_appLang.tr('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addLanguage() {
    String selectedLanguage = '';
    String selectedLevel = 'fluent'; // Use key directly
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredLanguages = allLanguages
                .where((lang) => lang.toLowerCase().contains(selectedLanguage.toLowerCase()))
                .toList();

            return AlertDialog(
              title: Text(_appLang.tr('add_language_dialog')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sélection de la langue avec autocomplétion
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return allLanguages;
                          }
                          return allLanguages.where((String option) {
                            return option.toLowerCase().contains(
                                textEditingValue.text.toLowerCase());
                          });
                        },
                        onSelected: (String selection) {
                          setState(() {
                            selectedLanguage = selection;
                          });
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(labelText: _appLang.tr('language_name'),
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.language),
                            ),
                            onChanged: (value) {
                              selectedLanguage = value;
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Dropdown pour le niveau
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLevel,
                      decoration: InputDecoration(labelText: _appLang.tr('level'),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assessment),
                      ),
                      items: languageLevels.map((level) {
                        return DropdownMenuItem(
                          value: level, // Use key
                          child: Text(_appLang.tr(level)), // Translate for display
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedLevel = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_appLang.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    final langData = {
                      'name': selectedLanguage,
                      'level': selectedLevel,
                    };
                    _saveToDatabase('languages', langData);
                    Navigator.pop(context);
                  },
                  child: Text(_appLang.tr('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddDialog(String title, Map<String, String> fields) {
    final formData = Map<String, String>.from(fields);
    final controllers = <String, TextEditingController>{};
    
    formData.forEach((key, value) {
      controllers[key] = TextEditingController(text: value);
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controllers.entries
                  .map(
                    (e) {
                      final isDateField = e.key.toLowerCase().contains('date');
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: isDateField
                            ? _buildDateField(e.key, e.value, context)
                            : TextField(
                                controller: e.value,
                                decoration: InputDecoration(
                                  labelText: e.key,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                      );
                    },
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_appLang.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${title.split(" ").sublist(2).join(" ")} ${_appLang.tr('item_added')}')),
                );
                Navigator.pop(context);
              },
              child: Text(_appLang.tr('add')),
            ),
          ],
        );
      },
    ).then((_) {
      // Cleanup controllers only once when dialog closes
      controllers.forEach((_, controller) {
        try {
          controller.dispose();
        } catch (e) {
          // Controller already disposed, ignore
        }
      });
    });
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    BuildContext context,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        hintText: 'YYYY-MM',
      ),
      readOnly: true,
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _parseDate(controller.text),
          firstDate: DateTime(1990),
          lastDate: DateTime(2030),
        );

        if (pickedDate != null) {
          controller.text = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  DateTime _parseDate(String dateStr) {
    try {
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length >= 2) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          return DateTime(year, month);
        }
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }
    return DateTime.now();
  }

  void _deleteItem(String type, dynamic item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_appLang.tr('item_deleted_from')} $type')),
    );
  }

  Future<void> _saveToDatabase(String type, Map<String, dynamic> data) async {
    try {
      setState(() => _loading = true);
      
      final auth = context.read<AuthState>();
      final resumeService = ResumeService(auth);

      // Mettre à jour l'état local immédiatement
      if (!_localResumeData.containsKey(type)) {
        _localResumeData[type] = [];
      }
      
      (_localResumeData[type] as List).add(data);

      if (mounted) {
        setState(() {});
      }

      // Vérifier si un CV existe déjà
      bool hasSavedResume = _localResumeData.containsKey('_id');

      if (hasSavedResume) {
        // Mettre à jour le CV existant
        final resumeId = _localResumeData['_id'];
        await resumeService.update(resumeId.toString(), _localResumeData);
      } else {
        // Créer un nouveau CV
        final newResume = {
          'userId': auth.userId,
          ...Map<String, dynamic>.from(_localResumeData)
            ..removeWhere((k, v) => k == '_id'),
        };
        
        final savedResume = await resumeService.create(newResume);
        
        if (savedResume != null && savedResume.containsKey('_id')) {
          _localResumeData['_id'] = savedResume['_id'];
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_appLang.tr('saved_successfully')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_appLang.tr('error_prefix')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}



