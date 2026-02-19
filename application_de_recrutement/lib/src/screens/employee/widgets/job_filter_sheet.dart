import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_settings.dart';
import '../../../core/translations.dart';

class JobFilterSheet extends StatefulWidget {
  final String initialTitle;
  final String initialCity;
  final Function(String title, String city) onApply;
  final void Function(String title, String city)? onSaveSearch;

  const JobFilterSheet({
    super.key,
    required this.initialTitle,
    required this.initialCity,
    required this.onApply,
    this.onSaveSearch,
  });

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  late TextEditingController _titleController;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _cityController = TextEditingController(text: widget.initialCity);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _titleController.clear();
    _cityController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppSettings>().language;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.tr('filter_jobs_title'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text(lang.tr('clear')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Job Title Filter
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: lang.tr('job_title_placeholder'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 16),
          // City Filter
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: lang.tr('city_placeholder'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(
                  _titleController.text.trim().toLowerCase(),
                  _cityController.text.trim().toLowerCase(),
                );
                Navigator.pop(context);
              },
              child: Text(lang.tr('apply_filters')),
            ),
          ),
          if (widget.onSaveSearch != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final title = _titleController.text.trim();
                  final city = _cityController.text.trim();
                  widget.onSaveSearch!(title, city);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                label: Text(lang.tr('save_this_search')),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
