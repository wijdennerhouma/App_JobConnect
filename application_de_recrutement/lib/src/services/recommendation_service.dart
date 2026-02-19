import '../models/job_with_company.dart';
import '../models/user.dart';

/// Computes a match score (0-100) for a job given user preferences.
int computeMatchScore({
  required JobWithCompany jobWithCompany,
  String? userCity,
  String? preferredContract,
  Set<String>? appliedJobIds,
}) {
  final job = jobWithCompany.job;
  final company = jobWithCompany.company;
  int score = 50; // base

  if (appliedJobIds != null && appliedJobIds.contains(job.id)) {
    return 0; // already applied, don't recommend as "match"
  }

  final displayCity = company?.city ?? job.address;
  if (userCity != null &&
      userCity.isNotEmpty &&
      displayCity.toLowerCase().contains(userCity.toLowerCase())) {
    score += 25;
  }
  if (preferredContract != null &&
      preferredContract.isNotEmpty &&
      job.contract.toLowerCase().contains(preferredContract.toLowerCase())) {
    score += 15;
  }
  if (job.description.length > 100) score += 5;
  if (company != null) score += 5;

  return score.clamp(0, 100);
}

/// Returns jobs sorted by match score (desc), with score attached.
List<ScoredJob> sortByRecommendation({
  required List<JobWithCompany> jobs,
  String? userCity,
  String? preferredContract,
  Set<String>? appliedJobIds,
}) {
  final scored = jobs.map((jw) {
    final score = computeMatchScore(
      jobWithCompany: jw,
      userCity: userCity,
      preferredContract: preferredContract,
      appliedJobIds: appliedJobIds,
    );
    return ScoredJob(jobWithCompany: jw, score: score);
  }).toList();
  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored;
}

class ScoredJob {
  final JobWithCompany jobWithCompany;
  final int score;

  ScoredJob({required this.jobWithCompany, required this.score});
}
