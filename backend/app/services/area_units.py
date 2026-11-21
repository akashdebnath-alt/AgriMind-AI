ACRE_IN_HECTARES = 0.40468564224


def to_hectares(value: float, unit: str) -> float:
    return round(value * ACRE_IN_HECTARES, 4) if unit == "Acres" else round(value, 4)


def from_hectares(hectares: float, unit: str) -> float:
    hectares = float(hectares)
    return round(hectares / ACRE_IN_HECTARES, 2) if unit == "Acres" else round(hectares, 2)
