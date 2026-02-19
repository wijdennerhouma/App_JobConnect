/// Model for a saved job search (filters + optional alert).
class SavedSearch {
  final String id;
  final String title;
  final String? city;
  final String? contract;
  final bool alertOnNewJob;
  final DateTime createdAt;

  SavedSearch({
    required this.id,
    required this.title,
    this.city,
    this.contract,
    this.alertOnNewJob = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'city': city,
        'contract': contract,
        'alertOnNewJob': alertOnNewJob,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedSearch.fromJson(Map<String, dynamic> json) => SavedSearch(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        city: json['city'] as String?,
        contract: json['contract'] as String?,
        alertOnNewJob: json['alertOnNewJob'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
