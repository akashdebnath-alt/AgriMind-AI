"""Generate a reproducible synthetic dataset, train, and evaluate the irrigation model.

Run from the backend directory with:
    python -m app.services.train_irrigation_model

The label uses each crop type's depletion fraction p: threshold =
(1 - p) * 100 + (ET0 - 4.5) - min(rainfall, 20). Irrigation is needed when
soil_moisture_pct is below that threshold. This field is the percentage of
plant-available water remaining in the root zone. The resulting model is
synthetic data, not real-world accuracy.
"""
import csv
import json
from pathlib import Path

import joblib
import numpy as np
import sklearn
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction import DictVectorizer
from sklearn.metrics import accuracy_score, confusion_matrix, f1_score, precision_score, recall_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline

from app.services.irrigation_features import CROP_TYPES, GROWTH_STAGES, SOIL_TYPES
from app.services.irrigation_ml import FEATURES, MODEL_PATH, NUMERIC_FEATURES

DATA_DIR = Path(__file__).resolve().parents[1] / "data"
DATASET_PATH = DATA_DIR / "irrigation_synthetic_dataset.csv"
METRICS_PATH = DATA_DIR / "irrigation_model_metrics.json"
RANDOM_STATE = 42


def generate_dataset(path: Path = DATASET_PATH, samples: int = 5_000) -> None:
    rng = np.random.default_rng(RANDOM_STATE)
    rows = []
    depletion_fraction = {
        "rice": 0.20, "cereal": 0.55, "pulse": 0.50, "oilseed": 0.60,
        "fiber": 0.65, "tuber": 0.35, "vegetable": 0.40, "fruit": 0.50,
        "other": 0.50, "mixed": 0.45, "none": 0.50, "unknown": 0.50,
    }
    for sample_index in range(samples):
        moisture = float(rng.uniform(5.0, 90.0))
        air_temperature = float(rng.uniform(10.0, 45.0))
        humidity = float(rng.uniform(20.0, 100.0))
        soil_temperature = min(60.0, max(
            -10.0, air_temperature - 2.5 + float(rng.normal(0.0, 1.5)),
        ))
        rainfall = min(float(rng.exponential(4.0)), 300.0)
        et0 = min(12.0, max(
            0.5, 3.2 + (air_temperature - 25.0) * 0.16
            + (50.0 - humidity) * 0.025 + float(rng.normal(0.0, 0.8)),
        ))
        crop_type = str(rng.choice(
            CROP_TYPES,
            p=[0.14, 0.13, 0.10, 0.08, 0.05, 0.06, 0.18, 0.08, 0.10, 0.03, 0.03, 0.02],
        ))
        growth_stage = str(rng.choice(
            GROWTH_STAGES,
            p=[0.17, 0.20, 0.25, 0.17, 0.11, 0.05, 0.05],
        ))
        soil_type = str(rng.choice(
            SOIL_TYPES, p=[0.20, 0.20, 0.25, 0.10, 0.10, 0.10, 0.05],
        ))
        boundary_count = len(depletion_fraction) * 5
        if sample_index < boundary_count:
            crop_type = tuple(depletion_fraction)[(sample_index // 5)]
            threshold = (1 - depletion_fraction[crop_type]) * 100
            offset = (-8.0, -4.0, 0.0, 4.0, 8.0)[sample_index % 5]
            moisture = threshold + offset
            air_temperature = 25.0
            humidity = 60.0
            soil_temperature = 25.0
            rainfall = 0.0
            et0 = 4.5
            growth_stage = "Mid-season"
            soil_type = "loamy"
        p = depletion_fraction[crop_type]
        threshold = (1 - p) * 100 + (et0 - 4.5) * 1.0 - min(rainfall, 20.0) * 1.0
        irrigation_needed = int(crop_type != "none" and moisture < threshold)
        rows.append({
            "soil_moisture_pct": round(moisture, 2),
            "air_temperature_c": round(air_temperature, 2),
            "humidity_pct": round(humidity, 2),
            "soil_temperature_c": round(soil_temperature, 2),
            "rainfall_mm": round(rainfall, 2),
            "et0_mm": round(et0, 2),
            "crop_type": crop_type,
            "growth_stage": growth_stage,
            "soil_type": soil_type,
            "irrigation_needed": irrigation_needed,
        })

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as dataset:
        writer = csv.DictWriter(dataset, fieldnames=[*FEATURES, "irrigation_needed"])
        writer.writeheader()
        writer.writerows(rows)


def train_and_evaluate(
    dataset_path: Path = DATASET_PATH,
    model_path: Path = MODEL_PATH,
    metrics_path: Path = METRICS_PATH,
) -> dict:
    with dataset_path.open(newline="", encoding="utf-8") as dataset:
        rows = list(csv.DictReader(dataset))
    if len(rows) < 10:
        raise ValueError("The synthetic dataset must contain at least 10 rows.")

    x = [
        {
            name: float(row[name]) if name in NUMERIC_FEATURES else row[name]
            for name in FEATURES
        }
        for row in rows
    ]
    y = np.asarray([int(row["irrigation_needed"]) for row in rows])
    if len(set(y.tolist())) < 2:
        raise ValueError("The dataset must contain both irrigation classes.")

    x_train, x_test, y_train, y_test = train_test_split(
        x, y, test_size=0.2, random_state=RANDOM_STATE, stratify=y,
    )
    model = make_pipeline(
        DictVectorizer(),
        RandomForestClassifier(
            n_estimators=800, max_depth=None, min_samples_leaf=1,
            class_weight="balanced", random_state=RANDOM_STATE, n_jobs=-1,
        ),
    )
    model.fit(x_train, y_train)
    predicted = model.predict(x_test)
    matrix = confusion_matrix(y_test, predicted, labels=[0, 1]).tolist()
    sample = x_test[0]
    sample_probabilities = model.predict_proba([sample])[0]
    sample_probability = float(sample_probabilities[list(model.classes_).index(1)])
    metrics = {
        "dataset": "synthetic",
        "samples": len(rows),
        "test_samples": len(y_test),
        "positive_rate": round(float(y.mean()), 4),
        "accuracy": round(float(accuracy_score(y_test, predicted)), 4),
        "precision": round(float(precision_score(y_test, predicted, zero_division=0)), 4),
        "recall": round(float(recall_score(y_test, predicted, zero_division=0)), 4),
        "f1": round(float(f1_score(y_test, predicted, zero_division=0)), 4),
        "confusion_matrix": {
            "labels": [0, 1],
            "matrix": matrix,
        },
        "sample_prediction": {
            "input": sample,
            "irrigation_needed": bool(model.predict([sample])[0]),
            "probability": round(sample_probability, 3),
            "confidence": round(max(sample_probability, 1.0 - sample_probability), 3),
        },
        "random_state": RANDOM_STATE,
        "features": list(FEATURES),
        "scikit_learn_version": sklearn.__version__,
    }

    model_path.parent.mkdir(parents=True, exist_ok=True)
    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump({
        "model": model,
        "features": list(FEATURES),
        "model_name": "Random Forest (synthetic irrigation dataset)",
        "scikit_learn_version": sklearn.__version__,
        "random_state": RANDOM_STATE,
        "training_samples": len(y_train),
    }, model_path)
    metrics_path.write_text(json.dumps(metrics, indent=2) + "\n", encoding="utf-8")
    return metrics


if __name__ == "__main__":
    generate_dataset()
    result = train_and_evaluate()
    print(json.dumps(result, indent=2))
