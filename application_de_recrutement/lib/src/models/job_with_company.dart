
import 'job.dart';
import 'user.dart';

class JobWithCompany {
  final Job job;
  final AppUser? company;

  JobWithCompany({required this.job, this.company});
}
