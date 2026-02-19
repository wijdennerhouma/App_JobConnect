import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_state.dart';
import '../../core/app_settings.dart';
import '../../core/translations.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';

class JobFormScreen extends StatefulWidget {
  const JobFormScreen({super.key});

  @override
  State<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends State<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  final _startTime = TextEditingController();
  final _endTime = TextEditingController();
  final _duration = TextEditingController();
  final _contract = TextEditingController();
  final _workHours = TextEditingController(text: '8');
  final _price = TextEditingController();
  String _pricingType = 'per day';

  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _address.dispose();
    _startDate.dispose();
    _endDate.dispose();
    _startTime.dispose();
    _endTime.dispose();
    _duration.dispose();
    _contract.dispose();
    _workHours.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (mounted) {
         setState(() {
          controller.text = picked.format(context);
        });
      }
    }
  }

  void _resetForm() {
    _title.clear();
    _description.clear();
    _address.clear();
    _startDate.clear();
    _endDate.clear();
    _startTime.clear();
    _endTime.clear();
    _duration.clear();
    _contract.clear();
    _workHours.text = '8';
    _price.clear();
    setState(() {
      _pricingType = 'per day';
      _message = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = context.read<AppSettings>().language;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final auth = context.read<AuthState>();
      final service = JobService(auth);
      final job = Job(
        id: '',
        title: _title.text,
        description: _description.text,
        startTime: _startTime.text,
        endTime: _endTime.text,
        duration: _duration.text,
        contract: _contract.text,
        entrepriseId: auth.userId!,
        startDate: _startDate.text,
        endDate: _endDate.text,
        workHours: int.tryParse(_workHours.text) ?? 0,
        applicantsIds: const [],
        price: num.tryParse(_price.text) ?? 0,
        pricingType: _pricingType,
        address: _address.text,
      );
      await service.create(job);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.tr('job_published_success') ?? 'Offre publiée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
        DefaultTabController.of(context).animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _message = '${lang.tr('error_prefix')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.tr('job_details'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      TextFormField(
                        controller: _title,
                        decoration: InputDecoration(
                          labelText: lang.tr('job_title_label'),
                          prefixIcon: const Icon(Icons.work_outline),
                        ),
                        validator: (v) => v == null || v.isEmpty ? lang.tr('not_provided') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _address,
                        decoration: InputDecoration(
                          labelText: lang.tr('job_address_label'),
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) => v == null || v.isEmpty ? lang.tr('not_provided') : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        decoration: InputDecoration(
                          labelText: lang.tr('job_description_label'),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (v) => v == null || v.isEmpty ? lang.tr('not_provided') : null,
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(),
                      ),
                      
                      Text(
                        lang.tr('date'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDate,
                              readOnly: true,
                              onTap: () => _selectDate(_startDate),
                              decoration: InputDecoration(
                                labelText: lang.tr('job_start_date_label'),
                                prefixIcon: const Icon(Icons.calendar_today),
                              ),
                              validator: (v) => v == null || v.isEmpty ? lang.tr('not_provided') : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endDate,
                              readOnly: true,
                              onTap: () => _selectDate(_endDate),
                              decoration: InputDecoration(
                                labelText: lang.tr('job_end_date_label'),
                                prefixIcon: const Icon(Icons.event),
                              ),
                              validator: (v) => v == null || v.isEmpty ? lang.tr('not_provided') : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startTime,
                              readOnly: true,
                              onTap: () => _selectTime(_startTime),
                              decoration: InputDecoration(
                                labelText: lang.tr('job_start_time_label'),
                                prefixIcon: const Icon(Icons.access_time),
                              ),
                              validator: (v) => v == null || v.isEmpty ? lang.tr('not_provided') : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endTime,
                              readOnly: true,
                              onTap: () => _selectTime(_endTime),
                              decoration: InputDecoration(
                                labelText: lang.tr('job_end_time_label'),
                                prefixIcon: const Icon(Icons.access_time_filled),
                              ),
                              validator: (v) => v == null || v.isEmpty ? lang.tr('not_provided') : null,
                            ),
                          ),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(),
                      ),
                      
                      Text(
                         lang.tr('contract'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _contract.text.isNotEmpty ? _contract.text : null,
                              decoration: InputDecoration(
                                labelText: lang.tr('job_contract_label'),
                                prefixIcon: const Icon(Icons.description_outlined),
                              ),
                              items: [
                                'CDI',
                                'CDD',
                                'Freelance',
                                'Stage',
                                'Autre'
                              ].map((type) {
                                String labelKey = 'contract_other';
                                switch(type) {
                                  case 'CDI': labelKey = 'contract_cdi'; break;
                                  case 'CDD': labelKey = 'contract_cdd'; break;
                                  case 'Freelance': labelKey = 'contract_freelance'; break;
                                  case 'Stage': labelKey = 'internship'; break;
                                }
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(lang.tr(labelKey) ?? type),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _contract.text = val;
                                    if (val == 'CDI') _duration.clear();
                                  });
                                }
                              },
                              validator: (v) => v == null || v.isEmpty ? lang.tr('not_provided') : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // CDI = pas de durée ; Durée affichée uniquement pour CDD, Freelance, Stage, Autre
                          if (_contract.text != 'CDI')
                            Expanded(
                              child: TextFormField(
                                controller: _duration,
                                decoration: InputDecoration(
                                  labelText: lang.tr('job_duration_label'),
                                  prefixIcon: const Icon(Icons.timer_outlined),
                                ),
                                validator: (v) {
                                  if (_contract.text == 'CDI' || _contract.text.isEmpty) return null;
                                  return v == null || v.toString().trim().isEmpty ? lang.tr('not_provided') : null;
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _workHours,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: lang.tr('job_hours_per_week_label'),
                          prefixIcon: const Icon(Icons.schedule),
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(),
                      ),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _price,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: lang.tr('job_rate_label'),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    lang.tr('currency') ?? 'DT',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? lang.tr('not_provided') : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Container(
                             height: 56, // Match text field height generally
                             padding: const EdgeInsets.symmetric(horizontal: 12),
                             decoration: BoxDecoration(
                               border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                               borderRadius: BorderRadius.circular(16),
                               color: theme.inputDecorationTheme.fillColor,
                             ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _pricingType,
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'per day',
                                      child: Text(lang.tr('per_day')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'per hour',
                                      child: Text(lang.tr('per_hour')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'per month',
                                      child: Text(lang.tr('per_month')),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _pricingType = v);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                             backgroundColor: theme.colorScheme.secondary,
                             padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onSecondary,
                                  ),
                                )
                              : Text(lang.tr('publish')),
                        ),
                      ),
                      if (_message != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _message!.startsWith(lang.tr('error_prefix')) 
                              ? theme.colorScheme.errorContainer 
                              : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _message!.startsWith(lang.tr('error_prefix'))
                                ? theme.colorScheme.error.withOpacity(0.5)
                                : Colors.green.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _message!.startsWith(lang.tr('error_prefix')) ? Icons.error_outline : Icons.check_circle_outline,
                                color: _message!.startsWith(lang.tr('error_prefix')) ? theme.colorScheme.error : Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _message!,
                                  style: TextStyle(
                                    color: _message!.startsWith(lang.tr('error_prefix')) 
                                      ? theme.colorScheme.onErrorContainer 
                                      : Colors.green[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

