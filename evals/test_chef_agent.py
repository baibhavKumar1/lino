import os
import sys

# Ensure current directory is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import pytest
import json
from test_dataset import build_ideate_meals_prompt, build_chat_system_prompt
from run_evals import (
    call_openrouter,
    clean_and_parse_json,
    run_llm_judge,
)


def assert_recipe_schema(recipe: dict) -> None:
    """Validates complete MealRecipe schema conformity."""
    required_keys = [
        "dishName",
        "prepTime",
        "servings",
        "dietType",
        "ingredientsWithQuantities",
        "usedInventory",
        "missingItems",
        "cavemanSteps",
        "macros",
    ]
    for key in required_keys:
        assert key in recipe, f"Missing required recipe key: '{key}' in {recipe}"

    assert isinstance(recipe["ingredientsWithQuantities"], list), "ingredientsWithQuantities must be a list"
    assert len(recipe["ingredientsWithQuantities"]) > 0, "ingredientsWithQuantities must not be empty"
    assert isinstance(recipe["cavemanSteps"], list), "cavemanSteps must be a list"
    assert len(recipe["cavemanSteps"]) > 0, "cavemanSteps must not be empty"
    assert isinstance(recipe["macros"], dict), "macros must be an object"


def test_ideate_meals_zero_restock_lock():
    """Guarantee: When restock_time_minutes is 0, missingItems MUST be strictly empty []."""
    inventory = [
        {"name": "Fresh Spinach (Palak)", "quantity": 1, "unit": "250 g", "isAdded": True},
        {"name": "Fresh Bhindi (Ladyfinger)", "quantity": 1, "unit": "250 g", "isAdded": True},
        {"name": "Paneer", "quantity": 1, "unit": "200 g", "isAdded": True},
        {"name": "Green Capsicum", "quantity": 2, "unit": "piece", "isAdded": True},
        {"name": "Tomatoes", "quantity": 3, "unit": "piece", "isAdded": True},
        {"name": "Onions", "quantity": 2, "unit": "piece", "isAdded": True},
        {"name": "Basmati Rice", "quantity": 1, "unit": "1 kg", "isAdded": True},
        {"name": "Toor Dal", "quantity": 1, "unit": "500 g", "isAdded": True},
        {"name": "Desi Ghee", "quantity": 1, "unit": "500 ml", "isAdded": True},
        {"name": "Mustard Seeds", "quantity": 1, "unit": "100 g", "isAdded": True},
        {"name": "Cumin Seeds (Jeera)", "quantity": 1, "unit": "100 g", "isAdded": True},
        {"name": "Turmeric Powder", "quantity": 1, "unit": "100 g", "isAdded": True},
        {"name": "Salt", "quantity": 1, "unit": "1 kg", "isAdded": True},
    ]

    prompt = build_ideate_meals_prompt(
        inventory=inventory,
        meal_time="Lunch",
        max_cook_time_minutes=25,
        num_people=2,
        restock_time_minutes=0,  # Strict In-Stock
        diet_type="Veg",
    )

    actual_output = call_openrouter(prompt)
    data = clean_and_parse_json(actual_output)

    assert "recipes" in data, "Output JSON must contain 'recipes' key"
    recipes = data["recipes"]
    assert len(recipes) >= 1, f"Expected recipes, got {len(recipes)}"

    for r in recipes:
        assert_recipe_schema(r)
        missing = r.get("missingItems", [])
        assert len(missing) == 0, f"Zero restock lock violated! Found missingItems: {missing}"


def test_ideate_meals_universal_water_ice():
    """Guarantee: Water and Ice must never be in missingItems."""
    inventory = [
        {"name": "Raw Rice", "quantity": 1, "unit": "500 g", "isAdded": True},
        {"name": "Salt", "quantity": 1, "unit": "1 kg", "isAdded": True},
    ]

    prompt = build_ideate_meals_prompt(
        inventory=inventory,
        meal_time="Dinner",
        max_cook_time_minutes=20,
        num_people=2,
        restock_time_minutes=15,
        diet_type="Veg",
    )

    actual_output = call_openrouter(prompt)
    data = clean_and_parse_json(actual_output)
    recipes = data.get("recipes", [])

    forbidden = {"water", "drinking water", "tap water", "ice", "ice cubes"}
    for r in recipes:
        missing = [str(m).lower().strip() for m in r.get("missingItems", [])]
        for f in forbidden:
            assert f not in missing, f"Water lock violated! '{f}' listed in missingItems: {missing}"


def test_ideate_meals_diet_strictness_non_veg():
    """Guarantee: Non-Veg preference must never return vegetarian or mushroom-only dishes."""
    inventory = [
        {"name": "Chicken Breast", "quantity": 1, "unit": "500 g", "isAdded": True},
        {"name": "Eggs", "quantity": 6, "unit": "pack", "isAdded": True},
        {"name": "Basmati Rice", "quantity": 1, "unit": "1 kg", "isAdded": True},
        {"name": "Onions", "quantity": 1, "unit": "1 kg", "isAdded": True},
    ]

    prompt = build_ideate_meals_prompt(
        inventory=inventory,
        meal_time="Dinner",
        max_cook_time_minutes=30,
        num_people=2,
        restock_time_minutes=15,
        diet_type="Non-Veg",
    )

    actual_output = call_openrouter(prompt)
    passed, reason = run_llm_judge(
        criteria="Verify all suggested recipes are Non-Vegetarian or Egg dishes. No purely vegetarian dishes allowed.",
        input_prompt=prompt,
        actual_output=actual_output,
    )
    assert passed, f"Non-Veg diet test failed: {reason}"


def test_chat_agent_mode_a_brainstorming():
    """Guarantee: General question ('what can I cook?') MUST return recipes: [] and idea chips."""
    inventory = [
        {"name": "Basmati Rice", "quantity": 1, "unit": "1 kg", "isAdded": True},
        {"name": "Ghee", "quantity": 1, "unit": "200 ml", "isAdded": True},
        {"name": "Jeera", "quantity": 1, "unit": "50 g", "isAdded": True},
    ]
    system_prompt = build_chat_system_prompt(
        inventory=inventory,
        user_profile={"dietPreference": "Veg", "householdSize": "2"},
        delivery_horizon="quick",
    )
    user_query = "What can I cook for dinner tonight with what I have?"

    combined_prompt = f"{system_prompt}\n\nUSER MESSAGE: {user_query}"
    actual_output = call_openrouter(combined_prompt)
    data = clean_and_parse_json(actual_output)

    assert "recipes" in data, "Output must contain 'recipes' key"
    assert len(data["recipes"]) == 0, f"Mode A violation! 'recipes' must be empty for general inquiry, got {data['recipes']}"
    assert "message" in data and len(data["message"]) > 20, "Must provide thoughtful message text"
    assert "suggestions" in data and len(data["suggestions"]) >= 2, "Must provide interactive suggestion chips"


def test_chat_agent_mode_b_explicit_recipe():
    """Guarantee: Explicit request ('Give me recipe for Jeera Rice') MUST return exactly 1 complete recipe in recipes."""
    inventory = [
        {"name": "Basmati Rice", "quantity": 1, "unit": "1 kg", "isAdded": True},
        {"name": "Ghee", "quantity": 1, "unit": "200 ml", "isAdded": True},
        {"name": "Jeera", "quantity": 1, "unit": "50 g", "isAdded": True},
        {"name": "Salt", "quantity": 1, "unit": "1 kg", "isAdded": True},
    ]
    system_prompt = build_chat_system_prompt(
        inventory=inventory,
        user_profile={"dietPreference": "Veg", "householdSize": "2"},
        delivery_horizon="inPantry",
    )
    user_query = "Please give me the full recipe for Jeera Rice."

    combined_prompt = f"{system_prompt}\n\nUSER MESSAGE: {user_query}"
    actual_output = call_openrouter(combined_prompt)
    data = clean_and_parse_json(actual_output)

    assert "recipes" in data, "Output must contain 'recipes' key"
    assert len(data["recipes"]) == 1, f"Mode B violation! Expected exactly 1 recipe, got {len(data['recipes'])}"

    recipe = data["recipes"][0]
    assert_recipe_schema(recipe)
    assert len(recipe["missingItems"]) == 0, "In-pantry lock: missingItems must be []"
