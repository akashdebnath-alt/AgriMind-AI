class Farm {
  final int? id;
  final String name;
  final String location;
  final double area;
  final String areaUnit;
  final String soilType;
  final int cropCount;
  final double? areaHectares;
  final double? areaAcres;
  final double? latitude;
  final double? longitude;

  Farm({
    this.id,
    required this.name,
    required this.location,
    required this.area,
    required this.areaUnit,
    required this.soilType,
    this.cropCount = 0,
    this.areaHectares,
    this.areaAcres,
    this.latitude,
    this.longitude,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name'] ?? json['farm_name'] ?? '',
      location: json['location'] ?? '',
      area: (json['area'] is num)
          ? (json['area'] as num).toDouble()
          : double.tryParse(json['area']?.toString() ?? '0') ?? 0.0,
      areaUnit: json['area_unit'] ?? 'Acres',
      soilType: json['soil_type'] ?? 'Loamy',
      cropCount: json['crop_count'] is int
          ? json['crop_count']
          : int.tryParse(json['crop_count']?.toString() ?? '0') ?? 0,
      areaHectares: json['area_hectares'] != null
          ? (json['area_hectares'] as num).toDouble()
          : null,
      areaAcres: json['area_acres'] != null
          ? (json['area_acres'] as num).toDouble()
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'location': location,
      'area': area,
      'area_unit': areaUnit,
      'soil_type': soilType,
    };
  }

  Farm copyWith({
    int? id,
    String? name,
    String? location,
    double? area,
    String? areaUnit,
    String? soilType,
    int? cropCount,
    double? areaHectares,
    double? areaAcres,
    double? latitude,
    double? longitude,
  }) {
    return Farm(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      soilType: soilType ?? this.soilType,
      cropCount: cropCount ?? this.cropCount,
      areaHectares: areaHectares ?? this.areaHectares,
      areaAcres: areaAcres ?? this.areaAcres,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
