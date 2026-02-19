import 'job.dart';
import 'user.dart';

class ApplicationItem {
  final String id;
  final String jobId;
  final String userId;
  final String entrepriseId;
  final String status;
  final Job? job;
  final AppUser? applicant;
  final AppUser? publisher;
  final String? coverLetter;
  final List<String>? skills;

  ApplicationItem({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.entrepriseId,
    required this.status,
    this.job,
    this.applicant,
    this.publisher,
    this.coverLetter,
    this.skills,
    this.createdAt,
  });

  final DateTime? createdAt;

  factory ApplicationItem.fromJson(Map<String, dynamic> json) {
    // Check if we have the wrapped structure (from byApplicant/byJob) or flat (from create)
    final Map<String, dynamic> appData = (json['application'] is Map<String, dynamic>)
        ? json['application']
        : json;

    var skillsList = <String>[];
    if (appData['skills'] != null) {
      skillsList = List<String>.from(appData['skills']);
    }

    // Robust extraction of applicant data
    Map<String, dynamic>? applicantData;
    if (json['applicant'] is Map<String, dynamic>) {
      applicantData = json['applicant'];
    } else if (json['user'] is Map<String, dynamic>) {
       applicantData = json['user'];
    } else if (appData['user_id'] is Map<String, dynamic>) {
       applicantData = appData['user_id'];
    }

    // Robust extraction of user_id string
    String userId = '';
    if (appData['user_id'] is String) {
      userId = appData['user_id'];
    } else if (appData['user_id'] is Map<String, dynamic>) {
      userId = appData['user_id']['_id']?.toString() ?? appData['user_id']['id']?.toString() ?? '';
    }

    return ApplicationItem(
      // Priority: root id -> appData _id -> appData id
      id: json['id']?.toString() ?? appData['_id']?.toString() ?? appData['id']?.toString() ?? '',
      jobId: appData['job_id']?.toString() ?? '',
      userId: userId,
      entrepriseId: appData['entreprise_id']?.toString() ?? '',
      status: appData['status'] ?? '',
      coverLetter: appData['coverLetter'] ?? appData['cover_letter'],
      skills: skillsList,
      // Nested objects are usually at the root in the 'wrapped' response
      job: json['job'] != null ? Job.fromJson(json['job']) : null,
      applicant: applicantData != null ? AppUser.fromJson(applicantData) : null,
      publisher:
          json['publisher'] != null ? AppUser.fromJson(json['publisher']) : null,
      createdAt: (() {
        if (appData['createdAt'] != null) return DateTime.tryParse(appData['createdAt']);
        if (appData['created_at'] != null) return DateTime.tryParse(appData['created_at']);
        // Fallback: Extract from ObjectId
        final id = appData['_id']?.toString() ?? appData['id']?.toString();
        if (id != null && id.length >= 24) {
          try {
            final timestamp = int.parse(id.substring(0, 8), radix: 16) * 1000;
            return DateTime.fromMillisecondsSinceEpoch(timestamp);
          } catch (_) {}
        }
        return null;
      })(),
    );
  }
}

