#!/usr/bin/env python3
"""Export a subset of simplified-recipes-1M.npz to recipes.json for the iOS app."""

import json
import random
import re
import sys
from pathlib import Path
from typing import Optional

import numpy as np

from recipe_title import infer_recipe_title

NPZ_PATH = Path("/Users/caelc/Downloads/simplified-recipes-1M.npz")
OUT_PATH = Path("/Users/caelc/Desktop/AutoPantry/AutoPantry/Resources/recipes.json")

# Optional: place epicurious JSON here for real titles (ingredient-keyed lookup)
TITLE_SOURCE_PATHS = [
    Path("/Users/caelc/Downloads/epicurious/full_format_recipes.json"),
    Path.home() / "epicurious/full_format_recipes.json",
]

MAX_RECIPES = 4000
MIN_INGREDIENTS = 4
MAX_INGREDIENTS = 18
SEED = 42


def normalize_ingredient(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9\s-]", "", text)
    return " ".join(text.split())


def load_title_lookup() -> dict:
    """Build title lookup from epicurious if available."""
    for path in TITLE_SOURCE_PATHS:
        if not path.exists():
            continue
        print(f"Loading titles from {path}...")
        with path.open(encoding="utf-8") as f:
            records = json.load(f)
        lookup = {}
        for record in records:
            title = record.get("title") or record.get("name")
            raw_ingredients = record.get("ingredients") or []
            if not title or not raw_ingredients:
                continue
            tokens: set[str] = set()
            for item in raw_ingredients:
                if isinstance(item, str):
                    normalized = normalize_ingredient(item)
                    for word in normalized.split():
                        if len(word) > 2:
                            tokens.add(word)
            if tokens:
                lookup[frozenset(tokens)] = str(title).strip()
        print(f"  {len(lookup):,} title keys loaded")
        return lookup
    return {}


def lookup_title(names: list[str], lookup: dict) -> Optional[str]:
    if not lookup:
        return None
    key = frozenset(names)
    if key in lookup:
        return lookup[key]

    name_words = frozenset(" ".join(names).split())
    best_score = 0.0
    best_title: str | None = None
    for candidate_key, title in lookup.items():
        overlap = len(name_words & candidate_key)
        if overlap < 3:
            continue
        score = overlap / max(len(name_words), len(candidate_key))
        if score > best_score and score >= 0.55:
            best_score = score
            best_title = title
    return best_title


def main() -> None:
    if not NPZ_PATH.exists():
        print(f"Missing dataset: {NPZ_PATH}", file=sys.stderr)
        sys.exit(1)

    title_lookup = load_title_lookup()

    data = np.load(NPZ_PATH, allow_pickle=True)
    vocabulary = [str(x) for x in data["ingredients"]]
    indexed = data["recipes"]

    candidates: list[tuple[int, list[str]]] = []
    for idx, entry in enumerate(indexed):
        if entry is None or len(entry) == 0:
            continue
        count = len(entry)
        if count < MIN_INGREDIENTS or count > MAX_INGREDIENTS:
            continue
        names = [vocabulary[int(i)] for i in entry]
        candidates.append((idx, names))

    random.seed(SEED)
    random.shuffle(candidates)
    selected = candidates[:MAX_RECIPES]

    recipes = []
    matched_external = 0
    for idx, names in selected:
        title = lookup_title(names, title_lookup)
        if title:
            matched_external += 1
        else:
            title = infer_recipe_title(names)

        recipes.append(
            {
                "id": f"r-{idx}",
                "title": title,
                "imageURL": None,
                "cookMinutes": None,
                "calories": None,
                "proteinGrams": None,
                "carbsGrams": None,
                "fatGrams": None,
                "ingredientCount": len(names),
                "estimatedPrice": None,
                "cuisines": [],
                "ingredients": [{"name": n, "amount": ""} for n in names],
                "instructions": [],
            }
        )

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": 3,
        "source": "simplified-recipes-1M.npz",
        "ingredientVocabularyCount": len(vocabulary),
        "exportedRecipeCount": len(recipes),
        "titleSource": "epicurious" if matched_external else "inferred",
        "recipes": recipes,
    }
    with OUT_PATH.open("w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)

    print(f"Exported {len(recipes)} recipes -> {OUT_PATH}")
    print(f"External title matches: {matched_external}")
    print(f"From {len(indexed):,} indexed recipes, {len(candidates):,} passed filters")


if __name__ == "__main__":
    main()
