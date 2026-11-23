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
    {"id": "heat-stress", "title": "Hot and dry weather",
     "keywords": ["heat", "hot", "temperature", "dry", "stress", "et0", "evapotranspiration", "wind", "drought"],
     "text": "Hot, dry or windy weather can increase crop water use. Check moisture in the root zone and use "
             "local weather and crop-stage estimates before changing irrigation. Do not irrigate solely because "
             "the soil surface looks dry; avoid overwatering and follow local agricultural guidance."},
    {"id": "soil-moisture", "title": "Checking soil moisture",
     "keywords": ["soil", "moisture", "dry", "wet", "check", "test", "root"],
     "text": "A simple field check: dig 10-15 cm near the roots and squeeze a handful of soil. If it crumbles and "
             "will not hold a shape it is dry; if it forms a ball and leaves water on your hand it is very wet. "
             "Check at root depth rather than only at the surface. Moisture sensors give more consistent readings."},
    {"id": "et-kc", "title": "How the irrigation estimate works",
     "keywords": ["evapotranspiration", "et0", "etc", "kc", "estimate", "calculate", "calculation", "requirement", "need"],
     "text": "Each day, the app soil water balance estimates crop water use as ETc = Kc x ET0. Rain and irrigation add water back to the root-zone soil bucket, while crop use removes water. When the bucket is empty enough, the app recommends refilling it and estimates how much to apply. This is an estimate, so confirm soil moisture and field conditions before irrigating."},
    {"id": "drip-vs-flood", "title": "Irrigation methods",
     "keywords": ["drip", "flood", "sprinkler", "method", "methods", "efficiency", "save"],
     "text": "Drip irrigation delivers water to the root zone and usually wastes less water than flood irrigation "
             "or sprinklers. Flood irrigation is simple but has higher losses to evaporation, runoff and deep "
             "percolation. Rice is commonly grown with standing water, so suitability depends on the crop."},
    {"id": "mulching", "title": "Mulching to save water",
     "keywords": ["mulch", "mulching", "evaporation", "conserve", "conservation", "straw"],
     "text": "A layer of straw or crop residue on the soil surface reduces evaporation, keeps soil temperature "
             "steadier and suppresses weeds, which can reduce how often you need to irrigate."},
    {"id": "overwatering-signs", "title": "Signs of overwatering",
     "keywords": ["overwatering", "overwater", "soggy", "waterlogged", "too much", "oxygen", "roots"],
     "text": "Overwatering can leave soil soggy, reduce oxygen around roots and encourage yellowing or wilting. Check drainage and soil moisture in the root zone before adding more water. If water stands in the field, improve drainage and pause irrigation until the soil drains."},
    {"id": "underwatering-signs", "title": "Signs of underwatering",
     "keywords": ["underwatering", "underwater", "drought", "dry", "wilting", "thirsty", "crisp"],
     "text": "Underwatering commonly causes wilting, dry or curling leaves, slow growth and brittle leaf edges. Surface dryness alone can be misleading, so check moisture near the roots. Irrigate when the field plan and soil check both indicate depletion."},
    {"id": "best-time-irrigate", "title": "Best time to irrigate",
     "keywords": ["time", "morning", "evening", "hottest", "6", "8", "schedule", "evaporation"],
     "text": "Early morning is generally a good time to irrigate, especially about 6-8 AM, because evaporation is lower and wind is often calmer. Avoid the hottest hours of the day. Local wind, disease risk and labour availability may affect the timing."},
    {"id": "soil-types", "title": "Soil types and irrigation",
     "keywords": ["soil", "types", "sandy", "loam", "clay", "black", "red", "compost", "drainage"],
     "text": "Sandy soil drains fast and usually needs lighter, more frequent irrigation; loam is more balanced. Clay and black soils hold more water and usually need irrigation less often. Red soils drain fairly quickly. Compost can improve water holding and structure in many soils."},
    {"id": "rice-water", "title": "Rice water management",
     "keywords": ["rice", "paddy", "standing", "tillering", "panicle", "flowering", "harvest", "water"],
     "text": "Rice commonly has thin standing water for much of the season, but exact practice depends on variety and local recommendation. Tillering, panicle initiation and flowering are sensitive periods. Drain the field before harvest and confirm the schedule with local extension advice."},
    {"id": "wheat-water", "title": "Wheat irrigation stages",
     "keywords": ["wheat", "crown", "root", "initiation", "tillering", "flowering", "grain", "filling"],
     "text": "Wheat needs few, well-timed irrigations. Crown root initiation, roughly 3 weeks after sowing, is especially important, along with tillering, flowering and grain filling. Check soil moisture and skip an irrigation after meaningful rain."},
    {"id": "tomato-water", "title": "Tomato irrigation",
     "keywords": ["tomato", "cracking", "blossom", "end", "rot", "base", "wet", "leaves", "moisture"],
     "text": "Tomatoes need even soil moisture because dry-wet swings can cause cracking and blossom end rot. Apply water at the base and keep leaves as dry as practical. Mulching helps reduce evaporation and moisture swings."},
    {"id": "potato-water", "title": "Potato irrigation",
     "keywords": ["potato", "tuber", "initiation", "bulking", "steady", "harvest", "moisture"],
     "text": "Keep potato soil moisture steady, especially during tuber initiation and bulking. Avoid both severe drought and waterlogging. Reduce irrigation toward harvest as recommended locally, and confirm soil conditions in the field."},
    {"id": "onion-water", "title": "Onion irrigation",
     "keywords": ["onion", "shallow", "roots", "light", "frequent", "irrigation", "last", "weeks"],
     "text": "Onions have shallow roots and usually need light, frequent irrigation rather than long dry spells. Check moisture near the upper root zone. Reduce and stop irrigation in the last weeks before harvest according to local practice."},
    {"id": "cabbage-water", "title": "Cabbage irrigation",
     "keywords": ["cabbage", "consistent", "moisture", "split", "heads", "dry", "wet"],
     "text": "Cabbage performs best with consistent soil moisture. Long dry periods followed by heavy irrigation can contribute to split heads. Irrigate based on soil moisture and forecast rain, and keep water away from unnecessary leaf wetting."},
    {"id": "chilli-water", "title": "Chilli irrigation",
     "keywords": ["chilli", "chili", "pepper", "drought", "waterlogging", "flower", "drop"],
     "text": "Chilli is sensitive to both drought and waterlogging, and severe stress can increase flower drop. Maintain even moisture in the root zone and improve drainage in wet soil. Check moisture before each irrigation."},
    {"id": "cotton-water", "title": "Cotton irrigation",
     "keywords": ["cotton", "flowering", "boll", "formation", "open", "bolls", "irrigation"],
     "text": "Cotton water demand is important during flowering and boll formation. Irrigation is generally reduced as bolls open, with the exact schedule depending on soil, rain and local advice. Avoid excess moisture late in the season."},
    {"id": "mustard-water", "title": "Mustard irrigation",
     "keywords": ["mustard", "few", "irrigations", "flowering", "pod", "filling", "rain"],
     "text": "Mustard often needs only a few well-timed irrigations. Flowering and pod filling are especially important periods to protect from drought. Use soil moisture and rainfall rather than a fixed routine."},
    {"id": "maize-water", "title": "Maize irrigation",
     "keywords": ["maize", "corn", "tasselling", "silking", "drought", "flower", "sensitive"],
     "text": "Maize is most sensitive to water stress at tasselling and silking. Protect these stages with timely irrigation based on root-zone moisture and forecast rain. Avoid prolonged waterlogging."},
    {"id": "leaf-curl", "title": "Possible causes of leaf curl",
     "keywords": ["curl", "curled", "curling", "leaf", "viral", "whitefly", "thrips", "mites", "herbicide", "heat", "stress"],
     "text": "Leaf curl can come from viral disease carried by whiteflies, heat or water stress, thrips or mites, or herbicide drift. Check undersides of leaves and compare nearby plants. Confirm the cause with an agriculture extension office before choosing treatment."},
    {"id": "fungal-disease", "title": "Managing fungal disease risk",
     "keywords": ["fungus", "fungal", "humid", "humidity", "disease", "morning", "base", "spacing", "infected", "leaves", "fungicide"],
     "text": "Humid weather and wet leaves can favour fungal disease. Water in the morning at the base, maintain sensible spacing and remove infected plant material where appropriate. Where a fungicide is needed, follow the label and ask the local agriculture office."},
    {"id": "nutrient-deficiency", "title": "Recognising nutrient deficiency",
     "keywords": ["nutrient", "nitrogen", "phosphorus", "potassium", "yellow", "purple", "burn", "soil", "test", "fertiliser"],
     "text": "Nitrogen deficiency often shows first on older leaves, phosphorus may reduce growth or add purpling, and potassium can cause edge scorch. Symptoms can overlap with disease or drought, so confirm with a soil test and field diagnosis. For fertiliser use, follow the label and ask local experts."},
    {"id": "compost-organic", "title": "Compost and organic matter",
     "keywords": ["compost", "organic", "matter", "mulch", "manure", "soil", "structure", "water"],
     "text": "Compost and other organic matter can improve soil structure, water infiltration and moisture holding over time. Apply it evenly and avoid excessive fresh material around seedlings. Composted material is generally safer and easier to manage than uncomposted residue."},
    {"id": "soil-salinity", "title": "Soil salinity",
     "keywords": ["salinity", "saline", "salt", "white", "crust", "leaf", "burn", "test", "drainage"],
     "text": "Salinity can show as white crust, poor germination, leaf burn and uneven growth. Use an approved soil or water test to confirm it. Improve drainage and manage irrigation quality only with local expert guidance."},
    {"id": "frost-cold", "title": "Frost and cold protection",
     "keywords": ["frost", "cold", "freeze", "young", "plants", "cover", "irrigation", "morning"],
     "text": "Light irrigation earlier on a cold day can sometimes reduce frost stress by storing soil heat, but it is not suitable for every crop or soil. Protect young plants with covers where practical and remove them after frost risk passes."},
    {"id": "water-saving", "title": "Saving irrigation water",
     "keywords": ["save", "saving", "water", "efficient", "drip", "mulch", "stages", "forecast"],
     "text": "Prioritise water for sensitive growth stages, check soil moisture, use drip or careful furrow irrigation where suitable and mulch exposed soil. Avoid irrigating just before meaningful rain and repair leaks or drainage losses."},
    {"id": "weeds", "title": "Weed control",
     "keywords": ["weed", "weeds", "grass", "competition", "water", "mulch", "hand", "herbicide"],
     "text": "Weeds compete for soil moisture and nutrients, especially around young crops. Use timely hand removal, hoeing or mulching where practical and keep field borders clean. Where a herbicide is needed, follow the label and ask the local agriculture office."},
    {"id": "seedling-care", "title": "Seedling care",
     "keywords": ["seedling", "young", "plant", "germination", "light", "frequent", "water", "damping"],
     "text": "Seedlings need shallow, regular moisture without waterlogging. Check the upper soil frequently and protect young plants from heat, wind and heavy rain. Good drainage and clean tools help reduce damping-off and disease."},
    {"id": "harvest-irrigation", "title": "Irrigation before harvest",
     "keywords": ["harvest", "last", "irrigation", "cut", "dry", "stop", "field", "mature"],
     "text": "Harvest irrigation needs vary by crop. Rice and some field crops require drainage or water reduction before harvest, while other crops may need a final timely irrigation. Follow the crop-specific stage and local recommendation."},
    {"id": "crop-rotation", "title": "Crop rotation",
     "keywords": ["rotation", "rotate", "sequence", "pest", "disease", "soil", "legume", "water"],
     "text": "Crop rotation can improve soil use, interrupt pest and disease cycles and spread water demand across seasons. Choose a sequence suited to local climate and market needs, and consider legumes and residue management as part of a sound plan."},
    {"id": "forecast-planning", "title": "Planning irrigation with forecasts",
     "keywords": ["forecast", "rain", "delay", "irrigation", "soil", "moisture", "planning", "meaningful"],
     "text": "Delay irrigation if a meaningful rain event is forecast, then confirm soil moisture and actual rainfall before applying water. Forecasts can change, so retain a moisture check and a short decision window."},
    {"id": "irrigation-log", "title": "Recording irrigation",
     "keywords": ["log", "record", "mark", "irrigated", "applied", "water", "amount", "liters"],
     "text": "Mark as irrigated to record the water applied and the irrigation event. Use the actual amount when known, and update the log promptly. The app can then use recent irrigation records in its soil water balance."},
    {"id": "sensor-readings", "title": "Understanding soil moisture readings",
     "keywords": ["sensor", "sensors", "reading", "trend", "soil", "moisture", "placement", "physical"],
     "text": "Soil moisture sensor readings are one trend and depend on soil type, sensor depth and placement. Check the same root-zone location consistently and compare readings with a simple field check. The app's virtual readings are estimates, not connected physical sensors."},
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
