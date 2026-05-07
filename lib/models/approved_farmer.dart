class ApprovedFarmer {
  const ApprovedFarmer({
    required this.id,
    required this.saadIdNo,
    required this.rsbsaFishrIdNo,
    required this.firstName,
    required this.middleName,
    required this.surname,
    required this.extensionName,
    required this.municipality,
    required this.sitioPurok,
    required this.dateOfBirth,
    required this.sex,
    required this.isIndigenous,
    required this.isPWD,
    required this.spouseName,
    required this.trainings,
    required this.updatedAt,
  });

  final String id;
  final String saadIdNo;
  final String rsbsaFishrIdNo;
  final String firstName;
  final String middleName;
  final String surname;
  final String extensionName;
  final String municipality;
  final String sitioPurok;
  final String dateOfBirth;
  final String sex;
  final bool isIndigenous;
  final bool isPWD;
  final String spouseName;
  final List<Map<String, dynamic>> trainings;
  final String updatedAt;

  String get fullName {
    return [firstName, middleName, surname, extensionName]
        .where((part) => part.trim().isNotEmpty)
        .join(' ')
        .trim();
  }

  String get displayLabel {
    final name = fullName.isEmpty ? 'Unnamed Farmer' : fullName;
    return saadIdNo.isEmpty ? name : '$saadIdNo - $name';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saadIdNo': saadIdNo,
      'rsbsaFishrIdNo': rsbsaFishrIdNo,
      'firstName': firstName,
      'middleName': middleName,
      'surname': surname,
      'extensionName': extensionName,
      'municipality': municipality,
      'sitioPurok': sitioPurok,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
      'isIndigenous': isIndigenous,
      'isPWD': isPWD,
      'spouseName': spouseName,
      'trainings': trainings,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toMonitoringSnapshot() {
    return {
      'saadIdNo': saadIdNo,
      'rsbsaFishrIdNo': rsbsaFishrIdNo,
      'firstName': firstName,
      'middleName': middleName,
      'surname': surname,
      'extensionName': extensionName,
      'municipality': municipality,
      'sitioPurok': sitioPurok,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
      'isIndigenous': isIndigenous,
      'isPWD': isPWD,
      'spouseName': spouseName,
      'trainings': trainings,
      'updatedAt': updatedAt,
      'fullName': fullName,
    };
  }

  factory ApprovedFarmer.fromJson(Map<String, dynamic> json) {
    return ApprovedFarmer(
      id: (json['id'] as String? ?? '').trim(),
      saadIdNo: (json['saadIdNo'] as String? ?? '').trim(),
      rsbsaFishrIdNo: (json['rsbsaFishrIdNo'] as String? ?? '').trim(),
      firstName: (json['firstName'] as String? ?? '').trim(),
      middleName: (json['middleName'] as String? ?? '').trim(),
      surname: (json['surname'] as String? ?? '').trim(),
      extensionName: (json['extensionName'] as String? ?? '').trim(),
      municipality: (json['municipality'] as String? ?? '').trim(),
      sitioPurok: (json['sitioPurok'] as String? ?? '').trim(),
      dateOfBirth: (json['dateOfBirth'] as String? ?? '').trim(),
      sex: (json['sex'] as String? ?? '').trim(),
      isIndigenous: _readBool(json['isIndigenous']),
      isPWD: _readBool(json['isPWD']),
      spouseName: (json['spouseName'] as String? ?? '').trim(),
      trainings: _readTrainings(json['trainings']),
      updatedAt: (json['updatedAt'] as String? ?? '').trim(),
    );
  }

  static List<Map<String, dynamic>> _readTrainings(Object? value) {
    if (value is List) {
      return value
          .cast<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final raw = value?.toString().trim().toLowerCase() ?? '';
    return raw == 'true' || raw == 'yes' || raw == '1';
  }
}
