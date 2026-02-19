class AppUser {
  final String id;
  final String name;
  final String? firstName;
  final String email;
  final String type;
  final String? city;
  final String? avatar;
  final String? phoneNumber;
  final String? address;
  final String? bio;
  final String? country;
  final String? postalCode;
  final bool isPublicProfile;
  final bool showEmail;
  final bool showPhoneNumber;

  AppUser({
    required this.id,
    required this.name,
    this.firstName,
    required this.email,
    required this.type,
    this.city,
    this.avatar,
    this.phoneNumber,
    this.address,
    this.bio,
    this.country,
    this.postalCode,
    this.isPublicProfile = true,
    this.showEmail = false,
    this.showPhoneNumber = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['_id']?.toString() ?? '',
        name: json['name'] ?? '',
        firstName: json['firstName'],
        email: json['email'] ?? '',
        type: json['type'] ?? '',
        city: json['city'],
        avatar: json['avatar'],
        phoneNumber: json['phoneNumber'],
        address: json['address'],
        bio: json['bio'],
        country: json['country'],
        postalCode: json['postalCode'],
        isPublicProfile: json['isPublicProfile'] ?? true,
        showEmail: json['showEmail'] ?? false,
        showPhoneNumber: json['showPhoneNumber'] ?? false,
      );
}

