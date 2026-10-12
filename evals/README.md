# Lino OpenRouter Agent Evaluation Suite (DeepEval)

Production evaluation suite designed to guarantee that the Lino OpenRouter agent answers properly, adheres to all JSON schemas, obeys dietary/allergy constraints, enforces in-pantry locks, and handles edge cases accurately.

---

## 1. Setup & Installation

From the project root:

```bash
cd evals
pip install -r requirements.txt
```

Set your OpenRouter environment variables:

```bash
# Windows PowerShell
$env:OPENROUTER_API_KEY="sk-or-v1-..."
$env:TARGET_MODEL="google/gemma-4-26b-a4b-it:free"

# Linux / macOS
export OPENROUTER_API_KEY="sk-or-v1-..."
export TARGET_MODEL="google/gemma-4-26b-a4b-it:free"
```

---

## 2. Running Evaluations

Run all evaluations via `pytest` or `deepeval`:

```bash
pytest test_chef_agent.py -v -s
```

Or run a specific test:

```bash
# Test Zero-Restock In-Pantry Lock
pytest test_chef_agent.py -k "test_ideate_meals_zero_restock" -v -s

# Test Intent Mode A / Mode B Dispatch
pytest test_chef_agent.py -k "test_chat_agent_mode" -v -s

# Test Adversarial Guardrail
pytest test_chef_agent.py -k "test_chat_agent_adversarial_guardrail" -v -s
```

---

## 3. Evaluation Matrix & Guarantees

| Guarantee | Test Function | Evaluation Mechanism |
| :--- | :--- | :--- |
| **Zero-Restock Lock** | `test_ideate_meals_zero_restock_lock` | Deterministic assertion: `missingItems == []` when restock = 0 |
| **Universal Water & Ice** | `test_ideate_meals_zero_restock_lock` | Deterministic assertion: Water / Ice never in missing items |
| **Diet Strictness** | `test_ideate_meals_diet_strictness_non_veg` | G-Eval: Strict non-veg meal verification |
| **Allergy & Exclusions** | `test_ideate_meals_allergy_and_exclusion_lock` | G-Eval + Deterministic string check |
| **Culinary Realism** | `test_ideate_meals_culinary_realism` | G-Eval: Proper water, boiling, cooking steps for raw staples |
| **Mode A Dispatch (Ideation)** | `test_chat_agent_mode_a_brainstorming` | Deterministic (`recipes: []`) + G-Eval suggestion check |
| **Mode B Dispatch (Recipe)** | `test_chat_agent_mode_b_explicit_recipe` | Deterministic (`len(recipes) == 1`) + Full schema validator |
| **Mode C Dispatch (Advice)** | `test_chat_agent_mode_c_culinary_tips` | Deterministic (`recipes: []`) + advice completeness |
| **System Prompt Protection** | `test_chat_agent_adversarial_guardrail` | G-Eval: Injection defense and safety |
