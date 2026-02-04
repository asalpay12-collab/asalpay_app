/// Location Risk Model
class LocationRisk {
  final int? id;
  final String? region;
  final String? district;
  final double? riskScore;
  final String? riskLevel;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? riskCategory;

  LocationRisk({
    this.id,
    this.region,
    this.district,
    this.riskScore,
    this.riskLevel,
    this.metadata,
    this.createdAt,
    this.updatedAt,
    this.riskCategory,
  });

  // Computed getters
  bool get isHighRisk => riskLevel?.toLowerCase() == 'high';
  bool get isMediumRisk => riskLevel?.toLowerCase() == 'medium';

  factory LocationRisk.fromJson(Map<String, dynamic> json) {
    return LocationRisk(
      id: json['id'] as int?,
      region: json['region'] as String?,
      district: json['district'] as String?,
      riskScore: json['risk_score'] != null
          ? double.tryParse(json['risk_score'].toString())
          : null,
      riskLevel: json['risk_level'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      riskCategory: json['risk_category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region': region,
      'district': district,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'metadata': metadata,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'risk_category': riskCategory,
    };
  }
}
