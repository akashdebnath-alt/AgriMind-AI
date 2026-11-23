"""Inference for the synthetic-data Random Forest irrigation model."""
from functools import lru_cache
import math
from pathlib import Path

import joblib
import sklearn

from app.services.irrigation_features import CROP_TYPES, GROWTH_STAGES, SOIL_TYPES

MODEL_PATH = Path(__file__).resolve().parents[1] / "data" / "irrigation_rf.joblib"
NUMERIC_FEATURES = (
    "soil_moisture_pct", "air_temperature_c", "humidity_pct",
    "soil_temperature_c", "rainfall_mm", "et0_mm",
)
CATEGORICAL_FEATURES = ("crop_type", "growth_stage", "soil_type")
FEATURES = (*NUMERIC_FEATURES, *CATEGORICAL_FEATURES)
_LIMITS = {
    "soil_moisture_pct": (0.0, 100.0),
    "air_temperature_c": (-10.0, 60.0),
    "humidity_pct": (0.0, 100.0),
    "soil_temperature_c": (-10.0, 60.0),
    "rainfall_mm": (0.0, 300.0),
    "et0_mm": (0.0, 20.0),
}
_CATEGORIES = {
    "crop_type": CROP_TYPES,
    "growth_stage": GROWTH_STAGES,
    "soil_type": SOIL_TYPES,
}


@lru_cache(maxsize=1)
def _load_model():
    if not MODEL_PATH.is_file():
        raise RuntimeError(
            f"Irrigation model is missing at {MODEL_PATH}. "
            "Train it with `python -m app.services.train_irrigation_model`."
        )
    saved = joblib.load(MODEL_PATH)
    if saved.get("features") != list(FEATURES) or "model" not in saved:
        raise RuntimeError(f"Irrigation model at {MODEL_PATH} has an unsupported format.")
    if saved.get("scikit_learn_version") != sklearn.__version__:
        raise RuntimeError(
            "The irrigation model was trained with a different scikit-learn version. "
            "Install the pinned backend requirements or retrain it with "
            "`python -m app.services.train_irrigation_model`."
        )
    return saved


def _validate_features(readings: dict, farm_context: dict) -> dict[str, float | str]:
    if not isinstance(readings, dict) or not isinstance(farm_context, dict):
        raise TypeError("Sensor readings and farm context must be objects.")

    features: dict[str, float | str] = {}
    for name, (minimum, maximum) in _LIMITS.items():
        if name not in readings:
            raise ValueError(f"Missing irrigation model input: {name}")
        try:
            value = float(readings[name])
        except (TypeError, ValueError):
            raise ValueError(f"Irrigation model input {name} must be numeric.") from None
        if not math.isfinite(value) or not minimum <= value <= maximum:
            raise ValueError(f"Irrigation model input {name} must be between {minimum} and {maximum}.")
        features[name] = value

    for name, allowed in _CATEGORIES.items():
        value = farm_context.get(name)
        if not isinstance(value, str) or value not in allowed:
            raise ValueError(f"Farm context {name} must be one of: {', '.join(allowed)}.")
        features[name] = value
    return features


def predict_irrigation(readings: dict, farm_context: dict) -> dict:
    model_data = _load_model()
    features = [_validate_features(readings, farm_context)]
    model = model_data["model"]
    prediction = bool(model.predict(features)[0])
    class_probabilities = model.predict_proba(features)[0]
    positive_index = list(model.classes_).index(1)
    probability = float(class_probabilities[positive_index])
    return {
        "irrigation_needed": prediction,
        "label": "Irrigation may be needed" if prediction else "Irrigation may not be needed",
        "probability": round(probability, 3),
        "confidence": round(max(probability, 1.0 - probability), 3),
        "confidence_note": "Classifier score from synthetic training data; not real-world accuracy.",
        "model_type": "RandomForestClassifier",
        "model": model_data["model_name"],
        "training_data": "synthetic",
    }
