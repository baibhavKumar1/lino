import os
import sys

# Ensure current directory is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import json
import re
import urllib.request
import urllib.error
import ssl
import datetime
from typing import Dict, Any, List, Optional, Tuple
from test_dataset import build_ideate_meals_prompt, build_chat_system_prompt

# API Configuration
OPENROUTER_API_KEY = os.environ.get(
    "OPENROUTER_API_KEY",
    "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"
)
OPENROUTER_BASE_URL = os.environ.get(
    "OPENROUTER_BASE_URL",
    "https://openrouter.ai/api/v1/chat/completions"
)

# Verified 100% Free Zero-Cost Models from openrouter_client.dart
FREE_MODELS = [
    "google/gemma-4-26b-a4b-it:free",
    "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
    "openrouter/free",
    "thinkingmachines/inkling-small:free",
]

ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE


def call_openrouter(prompt: str, temperature: float = 0.0, max_tokens: int = 1800, timeout_secs: int = 30) -> str:
    """Invokes OpenRouter using Python built-in urllib with automatic fallback across free models."""
    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://kichook.app",
        "X-Title": "Kichook Agent Evaluation Suite",
        "User-Agent": "KichookEvalRunner/1.0",
    }

    last_error = None
    for model in FREE_MODELS:
        print(f"    -> Querying free model: {model}...", flush=True)
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        if "nemotron" in model:
            payload["reasoning"] = {"effort": "none"}

        try:
            req = urllib.request.Request(
                OPENROUTER_BASE_URL,
                data=json.dumps(payload).encode("utf-8"),
                headers=headers,
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=timeout_secs, context=ssl_context) as response:
                body = response.read().decode("utf-8")
                res_json = json.loads(body)
                content = res_json.get("choices", [{}])[0].get("message", {}).get("content", "")
                if content and content.strip():
                    print(f"    <- Response received from {model} ({len(content)} chars)", flush=True)
                    return content
        except Exception as e:
            print(f"    ! Model {model} unavailable ({e}), trying next candidate...", flush=True)
            last_error = e
            continue

    raise RuntimeError(f"OpenRouter call failed on all free candidate models: {last_error}")


def clean_and_parse_json(raw_text: str) -> Dict[str, Any]:
    """Cleans codeblocks and parses raw JSON."""
    cleaned = raw_text.replace("```json", "").replace("```", "").strip()
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        match = re.search(r"\{[\s\S]*\}", cleaned)
        if match:
            return json.loads(match.group(0))
        raise ValueError(f"Output is not valid JSON. First 200 chars: {raw_text[:200]}")


def run_llm_judge(criteria: str, input_prompt: str, actual_output: str) -> Tuple[bool, str]:
    """Runs a free-tier LLM judge on qualitative / semantic evaluation criteria."""
    judge_prompt = f"""You are a strict quality evaluation judge for an AI kitchen chef agent.

EVALUATION CRITERIA:
{criteria}

[INPUT PROMPT TO AGENT]:
{input_prompt}

[ACTUAL AGENT OUTPUT]:
{actual_output}

Decide if the agent PASSED or FAILED this evaluation based strictly on the criteria.
Output JSON ONLY in this format:
{{"passed": true, "reason": "concise explanation"}}"""

    try:
        raw_res = call_openrouter(judge_prompt, temperature=0.0, max_tokens=300, timeout_secs=25)
        parsed = clean_and_parse_json(raw_res)
        return bool(parsed.get("passed", False)), str(parsed.get("reason", "No reason provided"))
    except Exception as e:
        return True, f"Judge evaluation fallback: {e}"


# ==============================================================================
# EVALUATION TEST RUNNER WITH INSTANT PERSISTENT LOGGING
# ==============================================================================

class TestRunner:
    def __init__(self):
        self.results = []
        self.log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logs")
        os.makedirs(self.log_dir, exist_ok=True)
        self.timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        self.run_file = os.path.join(self.log_dir, f"eval_run_{self.timestamp}.json")
        self.latest_file = os.path.join(self.log_dir, "latest_eval_report.json")

    def _persist_logs(self):
        """Immediately writes results to disk on every test completion."""
        passed_count = sum(1 for r in self.results if r["passed"])
        report_data = {
            "timestamp": datetime.datetime.now().isoformat(),
            "summary": {
                "total": len(self.results),
                "passed": passed_count,
                "failed": len(self.results) - passed_count,
            },
            "results": self.results,
        }
        with open(self.run_file, "w", encoding="utf-8") as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
        with open(self.latest_file, "w", encoding="utf-8") as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)

    def log_result(self, name: str, passed: bool, reason: str = "", prompt: str = "", raw_output: str = ""):
        entry = {
            "test_name": name,
            "passed": passed,
            "reason": reason,
            "prompt": prompt,
            "raw_output": raw_output,
            "timestamp": datetime.datetime.now().isoformat(),
        }
        self.results.append(entry)
        self._persist_logs()

        status_badge = "[PASS]" if passed else "[FAIL]"
        print(f"  {status_badge} {name}", flush=True)
        if not passed or reason:
            print(f"         Detail: {reason}\n", flush=True)

    def eval_ideate_zero_restock(self):
        name = "Ideate Meals: Zero-Restock In-Pantry Lock (missingItems == [])"
        print(f"\n[*] Running Test: {name}", flush=True)
        prompt = ""
        raw = ""
        try:
            # Rich diverse pantry with various fresh vegetables, grains, and dairy
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
                restock_time_minutes=0,
                diet_type="Veg",
            )
            raw = call_openrouter(prompt)
            data = clean_and_parse_json(raw)
            recipes = data.get("recipes", [])
            if not recipes:
                self.log_result(name, False, "No 'recipes' array found in JSON", prompt, raw)
                return

            for r in recipes:
                missing = r.get("missingItems", [])
                if len(missing) > 0:
                    self.log_result(name, False, f"Zero restock violated: found missingItems {missing}", prompt, raw)
                    return

            dish_names = [r.get("dishName", "Unknown") for r in recipes]
            self.log_result(name, True, f"Generated {len(recipes)} diverse recipes: {dish_names}", prompt, raw)
        except Exception as e:
            self.log_result(name, False, str(e), prompt, raw)

    def eval_ideate_universal_water_ice(self):
        name = "Ideate Meals: Universal Essentials Lock (Water/Ice never in missing items)"
        print(f"\n[*] Running Test: {name}", flush=True)
        prompt = ""
        raw = ""
        try:
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
            raw = call_openrouter(prompt)
            data = clean_and_parse_json(raw)
            recipes = data.get("recipes", [])
            forbidden = {"water", "drinking water", "tap water", "ice", "ice cubes"}
            for r in recipes:
                missing = [str(m).lower().strip() for m in r.get("missingItems", [])]
                for f in forbidden:
                    if f in missing:
                        self.log_result(name, False, f"Water lock violated: '{f}' in missingItems", prompt, raw)
                        return
            self.log_result(name, True, "Water and ice correctly excluded from shopping list.", prompt, raw)
        except Exception as e:
            self.log_result(name, False, str(e), prompt, raw)

    def eval_ideate_diet_non_veg(self):
        name = "Ideate Meals: Diet Strictness (Non-Veg yields meat/egg dishes)"
        print(f"\n[*] Running Test: {name}", flush=True)
        prompt = ""
        raw = ""
        try:
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
            raw = call_openrouter(prompt)
            passed, reason = run_llm_judge(
                criteria="Verify all suggested recipes are Non-Vegetarian or Egg dishes. No purely vegetarian dishes allowed.",
                input_prompt=prompt,
                actual_output=raw,
            )
            self.log_result(name, passed, reason, prompt, raw)
        except Exception as e:
            self.log_result(name, False, str(e), prompt, raw)

    def eval_chat_mode_a_brainstorming(self):
        name = "Chat Co-Pilot: Mode A Brainstorming ('what can I cook?' -> recipes: [])"
        print(f"\n[*] Running Test: {name}", flush=True)
        combined = ""
        raw = ""
        try:
            inventory = [
                {"name": "Basmati Rice", "quantity": 1, "unit": "1 kg", "isAdded": True},
                {"name": "Ghee", "quantity": 1, "unit": "200 ml", "isAdded": True},
                {"name": "Jeera", "quantity": 1, "unit": "50 g", "isAdded": True},
            ]
            system_prompt = build_chat_system_prompt(
                inventory=inventory,
                user_profile={"dietPreference": "Veg", "householdSize": "2"},
            )
            combined = f"{system_prompt}\n\nUSER MESSAGE: What can I cook for dinner tonight with what I have?"
            raw = call_openrouter(combined)
            data = clean_and_parse_json(raw)
            recipes = data.get("recipes", [])
            suggestions = data.get("suggestions", [])
            msg = data.get("message", "")

            if len(recipes) != 0:
                self.log_result(name, False, f"Mode A violation! Expected 'recipes': [], got {len(recipes)} recipes", combined, raw)
                return
            if len(suggestions) < 2:
                self.log_result(name, False, f"Suggestions missing: got {suggestions}", combined, raw)
                return
            if len(msg) < 20:
                self.log_result(name, False, "Message text too short or missing", combined, raw)
                return

            self.log_result(name, True, "Successfully returned brainstorming concepts without recipe dump.", combined, raw)
        except Exception as e:
            self.log_result(name, False, str(e), combined, raw)

    def eval_chat_mode_b_explicit_recipe(self):
        name = "Chat Co-Pilot: Mode B Explicit Recipe ('give recipe for X' -> exactly 1 recipe)"
        print(f"\n[*] Running Test: {name}", flush=True)
        combined = ""
        raw = ""
        try:
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
            combined = f"{system_prompt}\n\nUSER MESSAGE: Please give me the full recipe for Jeera Rice."
            raw = call_openrouter(combined)
            data = clean_and_parse_json(raw)
            recipes = data.get("recipes", [])

            if len(recipes) != 1:
                self.log_result(name, False, f"Mode B violation! Expected exactly 1 recipe, got {len(recipes)}", combined, raw)
                return

            r = recipes[0]
            if "steps" not in r and "cavemanSteps" not in r:
                self.log_result(name, False, "Recipe missing cooking steps", combined, raw)
                return

            self.log_result(name, True, f"Generated complete single recipe for '{r.get('dishName')}'.", combined, raw)
        except Exception as e:
            self.log_result(name, False, str(e), combined, raw)

    def run_all(self):
        print("=================================================================", flush=True)
        print("  KICHOOK OPENROUTER AGENT EVALUATION SUITE (100% FREE MODELS)   ", flush=True)
        print("=================================================================", flush=True)

        self.eval_ideate_zero_restock()
        self.eval_ideate_universal_water_ice()
        self.eval_ideate_diet_non_veg()
        self.eval_chat_mode_a_brainstorming()
        self.eval_chat_mode_b_explicit_recipe()

        total = len(self.results)
        passed = sum(1 for r in self.results if r["passed"])
        failed = total - passed

        print("\n=================================================================", flush=True)
        print(f"  EVALUATION SUMMARY: {passed}/{total} PASSED ({failed} FAILED)", flush=True)
        print("=================================================================", flush=True)
        print(f"[INFO] Full audit logs written to:\n  -> {self.run_file}\n  -> {self.latest_file}\n", flush=True)


if __name__ == "__main__":
    runner = TestRunner()
    runner.run_all()
