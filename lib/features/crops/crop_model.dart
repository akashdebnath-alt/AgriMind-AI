
class Crop {
  final String name;
  final String variety;
  final String farmName;
  final double area;
  final DateTime plantingDate;
  final String growthStage;
  final String season;

  Crop({
    required this.name,
    required this.variety,
    required this.farmName,
    required this.area,
    required this.plantingDate,
    required this.growthStage,
    required this.season,
  });

  int get daysSincePlanting =>
      DateTime.now().difference(plantingDate).inDays;

  Crop copyWith({
    String? name,
    String? variety,
    String? farmName,
    double? area,
    DateTime? plantingDate,
    String? growthStage,
    String? season,
  }) {
    return Crop(
      name: name ?? this.name,
      variety: variety ?? this.variety,
      farmName: farmName ?? this.farmName,
      area: area ?? this.area,
      plantingDate: plantingDate ?? this.plantingDate,
      growthStage: growthStage ?? this.growthStage,
      season: season ?? this.season,
    );
  }
}
