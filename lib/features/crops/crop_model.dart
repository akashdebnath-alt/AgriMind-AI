class Crop {
  final int? id;
  final int? farmId;
  final String name;
  final String variety;
  final String farmName;
  final double area;
  final String areaUnit;
  final double? areaHectares;
  final DateTime plantingDate;
  final String growthStage;
  final String season;
  final int? _daysSincePlanting;

  Crop({
    this.id,
    this.farmId,
    required this.name,
    required this.variety,
    required this.farmName,
    required this.area,
    this.areaUnit = 'Acres',
    this.areaHectares,
    required this.plantingDate,
    required this.growthStage,
    required this.season,
    this._daysSincePlanting,
  });

  int get daysSincePlanting {
    final d = _daysSincePlanting;
    if (d != null) return d;
    return DateTime.now().difference(plantingDate).inDays;
  }

  factory Crop.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['planting_date'] is String) {
      parsedDate = DateTime.tryParse(json['planting_date']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Crop(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      farmId: json['farm_id'] is int
          ? json['farm_id']
          : int.tryParse(json['farm_id']?.toString() ?? ''),
      name: json['name'] ?? json['crop_name'] ?? '',
      variety: json['variety'] ?? 'Not specified',
      farmName: json['farm_name'] ?? '',
      area: (json['area'] is num)
          ? (json['area'] as num).toDouble()
          : double.tryParse(json['area']?.toString() ?? '0') ?? 0.0,
      areaUnit: json['area_unit'] ?? 'Acres',
      areaHectares: json['area_hectares'] != null
          ? (json['area_hectares'] as num).toDouble()
          : null,
      plantingDate: parsedDate,
      growthStage: json['growth_stage'] ?? 'Initial',
      season: json['season'] ?? 'Kharif',
      daysSincePlanting: json['days_since_planting'] is int
          ? json['days_since_planting']
          : int.tryParse(json['days_since_planting']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final year = plantingDate.year.toString().padLeft(4, '0');
    final month = plantingDate.month.toString().padLeft(2, '0');
    final day = plantingDate.day.toString().padLeft(2, '0');

    return {
      if (id != null) 'id': id,
      if (farmId != null) 'farm_id': farmId,
      'farm_name': farmName,
      'name': name,
      'variety': variety,
      'area': area,
      'area_unit': areaUnit,
      'planting_date': '$year-$month-$day',
      'growth_stage': growthStage,
      'season': season,
    };
  }

  Crop copyWith({
    int? id,
    int? farmId,
    String? name,
    String? variety,
    String? farmName,
    double? area,
    String? areaUnit,
    double? areaHectares,
    DateTime? plantingDate,
    String? growthStage,
    String? season,
    int? daysSincePlanting,
  }) {
    return Crop(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      name: name ?? this.name,
      variety: variety ?? this.variety,
      farmName: farmName ?? this.farmName,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      areaHectares: areaHectares ?? this.areaHectares,
      plantingDate: plantingDate ?? this.plantingDate,
      growthStage: growthStage ?? this.growthStage,
      season: season ?? this.season,
      daysSincePlanting: daysSincePlanting ?? _daysSincePlanting,
    );
  }
}
