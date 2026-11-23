"""Shared farm/crop categories used by training and live irrigation inference."""
from app.database_models import Farm

CROP_TYPES = (
    "rice", "cereal", "pulse", "oilseed", "fiber", "tuber", "vegetable",
    "fruit", "other", "mixed", "none", "unknown",
)
GROWTH_STAGES = (
    "Initial", "Development", "Mid-season", "Late-season", "Harvest", "Mixed", "Unknown",
)
SOIL_TYPES = ("sandy", "clay", "loamy", "silty", "red", "black", "unknown")

_CROP_KEYWORDS = (
    ("rice", ("rice", "paddy")),
    ("cereal", ("wheat", "maize", "corn", "millet", "barley")),
    ("pulse", ("pulse", "lentil", "gram", "chickpea", "bean", "pea")),
    ("oilseed", ("mustard", "oilseed", "groundnut", "sesame", "soybean")),
    ("fiber", ("cotton", "jute")),
    ("tuber", ("potato", "cassava", "yam")),
    ("vegetable", ("tomato", "onion", "chilli", "cabbage", "okra", "brinjal", "vegetable")),
    ("fruit", ("mango", "banana", "citrus", "apple", "fruit")),
)


def crop_type_for(name: str) -> str:
    lowered = name.lower()
    for crop_type, keywords in _CROP_KEYWORDS:
        if any(keyword in lowered for keyword in keywords):
            return crop_type
    return "other" if lowered else "unknown"


def soil_type_for(name: str | None) -> str:
    lowered = (name or "").lower()
    for soil_type in ("black", "red", "sandy", "clay", "silty", "loamy"):
        if soil_type == "sandy":
            found = "sand" in lowered
        elif soil_type == "loamy":
            found = "loam" in lowered
        elif soil_type == "silty":
            found = "silt" in lowered
        else:
            found = soil_type in lowered
        if found:
            return soil_type
    return "unknown"


def farm_features(farm: Farm) -> dict:
    crops = list(farm.crops)
    crop_types = {crop_type_for(crop.crop_name) for crop in crops}
    growth_stages = {crop.growth_stage for crop in crops}
    return {
        "crop_type": next(iter(crop_types)) if len(crop_types) == 1 else ("mixed" if crop_types else "none"),
        "growth_stage": next(iter(growth_stages)) if len(growth_stages) == 1 else ("Mixed" if growth_stages else "Unknown"),
        "soil_type": soil_type_for(farm.soil_type),
        "soil_type_label": farm.soil_type or "Unknown",
        "crop_names": sorted({crop.crop_name for crop in crops}),
        "crop_area_hectares": round(sum(float(crop.area_hectares) for crop in crops), 4),
        "farm_area_hectares": round(float(farm.area_hectares), 4),
    }
