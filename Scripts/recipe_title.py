"""Infer human-readable recipe titles from cleaned ingredient lists."""

from __future__ import annotations

import re

SKIP = {
    "salt", "pepper", "water", "sugar", "flour", "oil", "butter", "egg", "eggs",
    "garlic", "onion", "milk", "cream", "cheese", "juice", "vinegar", "honey",
    "vanilla", "baking powder", "baking soda", "yeast", "cornstarch",
}

PROTEIN_PHRASES: list[tuple[str, str]] = [
    ("chicken breast", "Chicken"),
    ("chicken thighs", "Chicken"),
    ("chicken thigh", "Chicken"),
    ("ground chicken", "Chicken"),
    ("rotisserie chicken", "Chicken"),
    ("chicken", "Chicken"),
    ("ground beef", "Beef"),
    ("beef steak", "Steak"),
    ("beef", "Beef"),
    ("pork chop", "Pork"),
    ("pork", "Pork"),
    ("salmon", "Salmon"),
    ("shrimp", "Shrimp"),
    ("prawn", "Shrimp"),
    ("cod", "Cod"),
    ("tilapia", "Tilapia"),
    ("tuna", "Tuna"),
    ("turkey", "Turkey"),
    ("lamb", "Lamb"),
    ("tofu", "Tofu"),
    ("sausage", "Sausage"),
    ("bacon", "Bacon"),
    ("ham", "Ham"),
    ("fish", "Fish"),
]

BASE_PHRASES: list[tuple[str, str]] = [
    ("lasagna", "Lasagna"),
    ("spaghetti", "Spaghetti"),
    ("fettuccine", "Fettuccine"),
    ("penne", "Penne Pasta"),
    ("macaroni", "Mac and Cheese"),
    ("pasta", "Pasta"),
    ("noodles", "Noodle Bowl"),
    ("pizza", "Pizza"),
    ("tortilla", "Tacos"),
    ("taco", "Tacos"),
    ("rice", "Rice Bowl"),
    ("quinoa", "Quinoa Bowl"),
    ("potato", "Potato Dish"),
    ("bread", "Sandwich"),
    ("oats", "Oatmeal"),
    ("pancake", "Pancakes"),
    ("beans", "Beans"),
    ("lentils", "Lentil Dish"),
    ("chickpeas", "Chickpea Bowl"),
]

STYLE_RULES: list[tuple[set[str], str]] = [
    ({"soy sauce", "ginger", "sesame oil"}, "Asian"),
    ({"cumin", "chili powder", "cilantro"}, "Mexican"),
    ({"basil", "oregano", "mozzarella", "parmesan"}, "Italian"),
    ({"curry powder", "coconut milk", "turmeric"}, "Curry"),
    ({"tahini", "lemon", "cucumber"}, "Mediterranean"),
]

FLAVOR_RULES: list[tuple[set[str], str]] = [
    ({"molasses", "barbecue sauce"}, "BBQ"),
    ({"bbq sauce"}, "BBQ"),
    ({"lemon", "lemon juice"}, "Lemon"),
    ({"lime", "lime juice"}, "Lime"),
    ({"honey", "maple syrup"}, "Honey"),
    ({"pesto"}, "Pesto"),
    ({"teriyaki"}, "Teriyaki"),
    ({"coconut milk"}, "Coconut"),
    ({"peanut butter"}, "Peanut"),
    ({"jalapeno", "chili sauce", "hot sauce"}, "Spicy"),
    ({"garlic", "butter"}, "Garlic Butter"),
    ({"cream cheese", "cream"}, "Creamy"),
    ({"tomato sauce", "marinara"}, "Marinara"),
]

METHOD_RULES: list[tuple[set[str], str]] = [
    ({"broth", "stock"}, "Soup"),
    ({"lettuce", "romaine", "spinach", "arugula"}, "Salad"),
    ({"cake mix", "frosting"}, "Cake"),
    ({"chocolate chips", "cocoa"}, "Chocolate Dessert"),
]

# Ingredient-set patterns -> fixed classic dish names
NAMED_DISHES: list[tuple[set[str], str]] = [
    ({"bacon", "beans", "molasses"}, "BBQ Baked Beans"),
    ({"black beans", "rice"}, "Black Bean Rice Bowl"),
    ({"chicken", "rice", "broccoli"}, "Chicken Broccoli Rice Bowl"),
    ({"chicken", "pasta", "tomato"}, "Chicken Tomato Pasta"),
    ({"salmon", "avocado"}, "Salmon Avocado Plate"),
    ({"eggs", "tortilla", "salsa"}, "Huevos Rancheros"),
    ({"ground beef", "pasta", "tomato"}, "Beef Pasta Bake"),
    ({"shrimp", "pasta"}, "Shrimp Pasta"),
    ({"tuna", "mayonnaise", "bread"}, "Tuna Salad Sandwich"),
    ({"chicken", "lettuce", "tomato"}, "Chicken Salad"),
    ({"beef", "potato", "carrot"}, "Beef Stew"),
    ({"chicken", "potato"}, "Roasted Chicken & Potatoes"),
    ({"mushroom", "rice"}, "Mushroom Rice Pilaf"),
    ({"lentils", "carrot", "onion"}, "Lentil Soup"),
    ({"chickpeas", "spinach", "curry powder"}, "Chickpea Curry"),
    ({"oats", "milk", "banana"}, "Banana Oatmeal"),
    ({"flour", "sugar", "chocolate"}, "Chocolate Chip Cookies"),
]


def _ing_set(ingredients: list[str]) -> set[str]:
    return {i.strip().lower() for i in ingredients if i.strip()}


def _match_phrase(ingredients: set[str], phrases: list[tuple[str, str]]) -> str | None:
    joined = " ".join(sorted(ingredients))
    for phrase, label in sorted(phrases, key=lambda x: -len(x[0])):
        if phrase in joined or phrase in ingredients:
            return label
    return None


def _match_rules(ingredients: set[str], rules: list[tuple[set[str], str]]) -> str | None:
    for triggers, label in rules:
        if len(triggers & ingredients) >= max(1, len(triggers) - 1):
            return label
    return None


def _named_dish(ingredients: set[str]) -> str | None:
    best: tuple[float, str] | None = None
    for pattern, title in NAMED_DISHES:
        overlap = pattern & ingredients
        if not overlap:
            continue
        score = len(overlap) / len(pattern)
        if score >= 0.6 and (best is None or score > best[0]):
            best = (score, title)
    return best[1] if best else None


def _main_ingredients(ingredients: list[str], limit: int = 3) -> list[str]:
    main = [i for i in ingredients if i.lower() not in SKIP]
    return main[:limit]


def _join_title(*parts: str) -> str:
    words: list[str] = []
    for part in parts:
        part = part.strip(" &")
        if not part:
            continue
        for word in part.split():
            if word == "&":
                continue
            if not words or words[-1].lower() != word.lower():
                words.append(word)
    title = " ".join(words[:5])
    return title.strip() or "House Recipe"


def infer_recipe_title(ingredients: list[str]) -> str:
    """Turn a cleaned ingredient list into a dish-style title."""
    if not ingredients:
        return "House Recipe"

    ing = _ing_set(ingredients)

    if named := _named_dish(ing):
        return named

    protein = _match_phrase(ing, PROTEIN_PHRASES)
    base = _match_phrase(ing, BASE_PHRASES)
    style = _match_rules(ing, STYLE_RULES)
    flavor = _match_rules(ing, FLAVOR_RULES)
    method = _match_rules(ing, METHOD_RULES)

    # Dessert/breakfast hints
    if ing & {"chocolate", "cocoa", "chocolate chips"} and ing & {"flour", "sugar", "eggs"}:
        return _join_title(flavor or "Chocolate", "Cookies" if "chip" in " ".join(ing) else "Dessert")
    if ing & {"apple", "apples", "cinnamon"} and ing & {"pie", "crust", "flour", "sugar"}:
        return _join_title(flavor or "Apple", "Pie")
    if ing & {"banana", "oats"}:
        return _join_title(flavor or "Banana", "Oatmeal")

    prefix = " ".join(p for p in [flavor, style] if p)

    if protein and base:
        return _join_title(prefix, protein, base)
    if protein and method:
        return _join_title(prefix, protein, method)
    if protein:
        return _join_title(prefix, protein, "Plate")
    if base:
        return _join_title(prefix, base)
    if method:
        mains = _main_ingredients(ingredients, 2)
        if len(mains) >= 2:
            return _join_title(f"{mains[0].title()} & {mains[1].title()}", method)
        if mains:
            return _join_title(mains[0].title(), method)
        return _join_title(prefix, method)

    mains = _main_ingredients(ingredients, 2)
    if len(mains) >= 2:
        a, b = mains[0].title(), mains[1].title()
        return _join_title(f"{a} & {b}", "Bake")
    if mains:
        return _join_title(mains[0].title(), "Dish")
    return "House Recipe"
