class Complaint {
  final int? id;
  final String deviceType;
  final String brand;
  final String model;
  final String customerName;
  final String customerNumber;
  final String issueDescription;
  final String? extraNotes;
  final String? spareIssue;
  final String? photoPath;
  final String address;
  final double? latitude;
  final double? longitude;
  final int priority;
  final String status;
  final String createdAt;

  Complaint({
    this.id,
    required this.deviceType,
    required this.brand,
    required this.model,
    required this.customerName,
    required this.customerNumber,
    required this.issueDescription,
    this.extraNotes,
    this.spareIssue,
    this.photoPath,
    required this.address,
    this.latitude,
    this.longitude,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceType': deviceType,
      'brand': brand,
      'model': model,
      'customerName': customerName,
      'customerNumber': customerNumber,
      'issueDescription': issueDescription,
      'extraNotes': extraNotes,
      'spareIssue': spareIssue,
      'photoPath': photoPath,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'priority': priority,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'],
      deviceType: map['deviceType'] ?? 'Unknown',
      brand: map['brand'],
      model: map['model'],
      customerName: map['customerName'],
      customerNumber: map['customerNumber'],
      issueDescription: map['issueDescription'],
      extraNotes: map['extraNotes'],
      spareIssue: map['spareIssue'],
      photoPath: map['photoPath'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      priority: map['priority'],
      status: map['status'],
      createdAt: map['createdAt'],
    );
  }

  Complaint copyWith({
    int? id,
    String? deviceType,
    String? brand,
    String? model,
    String? customerName,
    String? customerNumber,
    String? issueDescription,
    String? extraNotes,
    String? spareIssue,
    String? photoPath,
    String? address,
    double? latitude,
    double? longitude,
    int? priority,
    String? status,
    String? createdAt,
  }) {
    return Complaint(
      id: id ?? this.id,
      deviceType: deviceType ?? this.deviceType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      customerName: customerName ?? this.customerName,
      customerNumber: customerNumber ?? this.customerNumber,
      issueDescription: issueDescription ?? this.issueDescription,
      extraNotes: extraNotes ?? this.extraNotes,
      spareIssue: spareIssue ?? this.spareIssue,
      photoPath: photoPath ?? this.photoPath,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
