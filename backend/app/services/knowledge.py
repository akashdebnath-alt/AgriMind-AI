"""Small curated knowledge base for the AI Adviser (retrieval-only, no generated agronomy).

This is the first step of the RAG layer in the project report: grounded answers from
curated entries. It can later be replaced by a vector index + LLM explanation layer.
"""
import re

ENTRIES = [
    {"id": "yellow-leaves", "title": "Yellowing leaves",
     "keywords": ["yellow", "yellowing", "leaves", "leaf", "chlorosis", "pale"],
     "text": "Yellow leaves have several common causes: nitrogen deficiency (older, lower leaves yellow first), "
             "overwatering or poor drainage (roots lack oxygen), pest or disease damage, and iron or sulphur "
             "deficiency (young leaves yellow). Check which leaves are affected, whether the soil stays soggy, "
             "and look under leaves for pests. A soil test confirms nutrient problems before you add fertiliser."},
    {"id": "irrigation-frequency", "title": "How often to irrigate",
     "keywords": ["often", "frequency", "irrigate", "irrigation", "water", "watering", "schedule", "when"],
     "text": "There is no single schedule: crop water need depends on weather, crop stage, soil type and rainfall. "
             "Sandy soils need lighter, more frequent irrigation; clay soils hold water longer. Crop demand is "
             "highest at the mid-season stage and lowest at the initial and harvest stages. Check soil moisture "
             "in the root zone before irrigating and skip irrigation after meaningful rain. The Water tab's "
             "estimate combines these factors."},
    {"id": "pests", "title": "Protecting crops from pests",
     "keywords": ["pest", "pests", "insect", "insects", "protect", "disease", "aphid", "worm", "bug"],
     "text": "Scout fields regularly (at least weekly) and identify the pest before treating. Use cultural "
             "controls first: crop rotation, clean field borders, resistant varieties and correct spacing. "
             "Use pesticides only when the pest level justifies it, follow the label, and consult your local "
             "agriculture extension office (for example a Krishi Vigyan Kendra) for recommended products."},
    {"id": "heavy-rainfall", "title": "Heavy rainfall",
     "keywords": ["rain", "rainfall", "heavy", "flood", "flooding", "waterlogging", "drain", "storm"],
     "text": "Pause irrigation when heavy rain is forecast. Clear drainage channels so water does not stand around "
             "roots, since waterlogging starves roots of oxygen and favours root diseases. After the rain, avoid "
             "walking on wet fields, check for lodging or washed-out seedlings, and watch for fungal disease as "
             "humidity stays high."},
    {"id": "soil-moisture", "title": "Checking soil moisture",
     "keywords": ["soil", "moisture", "dry", "wet", "check", "test", "root"],
     "text": "A simple field check: dig 10-15 cm near the roots and squeeze a handful of soil. If it crumbles and "
             "will not hold a shape it is dry; if it forms a ball and leaves water on your hand it is very wet. "
             "Check at root depth rather than only at the surface. Moisture sensors give more consistent readings."},
    {"id": "et-kc", "title": "How the irrigation estimate works",
     "keywords": ["evapotranspiration", "et0", "etc", "kc", "estimate", "calculate", "calculation", "requirement", "need"],
     "text": "The app estimates crop water use as ETc = Kc x ET0. ET0 is reference evapotranspiration from weather "
             "(how much water the atmosphere can pull from a reference crop). Kc is a crop coefficient that "
             "adjusts for crop type and growth stage. Rainfall is then subtracted. It is a baseline estimate, "
             "not a guarantee, so confirm with field conditions."},
    {"id": "drip-vs-flood", "title": "Irrigation methods",
     "keywords": ["drip", "flood", "sprinkler", "method", "methods", "efficiency", "save"],
     "text": "Drip irrigation delivers water to the root zone and usually wastes less water than flood irrigation "
             "or sprinklers. Flood irrigation is simple but has higher losses to evaporation, runoff and deep "
             "percolation. Rice is commonly grown with standing water, so suitability depends on the crop."},
    {"id": "mulching", "title": "Mulching to save water",
     "keywords": ["mulch", "mulching", "evaporation", "conserve", "conservation", "straw"],
     "text": "A layer of straw or crop residue on the soil surface reduces evaporation, keeps soil temperature "
             "steadier and suppresses weeds, which can reduce how often you need to irrigate."},
]

SUGGESTIONS = [
    "Why are my leaves turning yellow?",
    "How often should I irrigate my crops?",
    "How can I protect crops from pests?",
    "What should I do during heavy rainfall?",
]

_STOP = set("a an the is are was were be to of for in on at my i me we you your do does how what why when should can "
            "with and or it this that from by as about".split())


def _tokens(text: str) -> set[str]:
    return {t for t in re.findall(r"[a-z0-9]+", text.lower()) if t not in _STOP}


def retrieve(query: str, limit: int = 2) -> list[dict]:
    q = _tokens(query)
    scored = []
    for e in ENTRIES:
        score = len(q & set(e["keywords"])) * 2 + len(q & _tokens(e["title"]))
        if score > 0:
            scored.append((score, e))
    scored.sort(key=lambda s: -s[0])
    if not scored:
        return []
    best = scored[0][0]
    return [e for s, e in scored[:limit] if s >= max(1, best - 1)]
