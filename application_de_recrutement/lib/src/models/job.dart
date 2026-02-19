class Job {
  final String id;
  final String title;
  final String description;
  final String startTime;
  final String endTime;
  final String duration;
  final String contract;
  final String entrepriseId;
  final String startDate;
  final String endDate;
  final int workHours;
  final List<String> applicantsIds;
  final num price;
  final String pricingType;
  final String address;

  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.contract,
    required this.entrepriseId,
    required this.startDate,
    required this.endDate,
    required this.workHours,
    required this.applicantsIds,
    required this.price,
    required this.pricingType,
    required this.address,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      duration: json['duration'] ?? '',
      contract: json['contract'] ?? '',
      entrepriseId: json['entreprise_id']?.toString() ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      workHours: (json['work_hours'] ?? 0) is int
          ? json['work_hours']
          : int.tryParse(json['work_hours'].toString()) ?? 0,
      applicantsIds: (json['applicants_ids'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      price: json['price'] ?? 0,
      pricingType: json['pricing_type'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

