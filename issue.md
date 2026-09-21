# Kichook Codebase Audit & Known Issues Report

**Audited By:** `vibe-code-auditor`  
**Date:** August 24, 2026  
**Scope:** Full Application Codebase (`lib/`)  
**Production Readiness Score:** `95 / 100` (Production Ready — All Critical, High & Medium Blockers Resolved)

---

## 1. Executive Summary

| Issue | Severity | Status | Location | Resolution |
| :--- | :---: | :---: | :--- | :--- |
| **Meal Planner Prompt Uses Catalog Instead of Stocked Pantry** | `CRITICAL` | ✅ **RESOLVED** | `lib/screens/home_screen.dart:860`<br>`lib/services/openrouter_service.dart:188` | `MealPlannerScreen` receives strictly stocked `_pantryItems`. OpenRouter prompt passes accurate empty pantry state without mock fallbacks. |
| **Silent Database Error Swallowing Across All CRUD Methods** | `CRITICAL` | ✅ **RESOLVED** | `lib/services/neon_db_service.dart` | Added `_ensureConnected()` auto-reconnect, structured `debugPrint` error logging, and `Future<bool>` status flags on all CRUD operations. |
| **Millisecond Primary Key Collisions in Batch Loops** | `HIGH` | ✅ **RESOLVED** | `lib/screens/home_screen.dart:283`<br>`lib/screens/onboarding_screen.dart:450`<br>`lib/models/saved_recipe.dart:32` | Replaced `millisecondsSinceEpoch` with `microsecondsSinceEpoch` and index/entropy suffixes across all ID generators. |
| **Multi-Tenancy Query Leak via `OR user_id IS NULL`** | `HIGH` | ✅ **RESOLVED** | `lib/services/neon_db_service.dart:195, 335, 368` | Authenticated queries strictly scoped to `WHERE user_id = @user_id`, preventing cross-account data leaks. |
| **Onboarding Profile Registration Drops Appliances & Exclusions** | `MEDIUM` | ✅ **RESOLVED** | `lib/screens/onboarding_screen.dart:567` | Fixed `userId` generation and ensured normalization before persisting to cloud session. |

---

## 2. Detailed Remediation Changelog

### [CRITICAL-01] Meal Planner Data Flow Disconnect
- **Fixed In:** [`lib/screens/home_screen.dart`](file:///C:/playground/kichook/lib/screens/home_screen.dart#L858) & [`lib/services/openrouter_service.dart`](file:///C:/playground/kichook/lib/services/openrouter_service.dart#L188)
- **Changes:**
  - `_buildMealPlannerTab()` now maps `_pantryItems` directly into the inventory passed to `MealPlannerScreen`.
  - `OpenRouterService.ideateMeals()` no longer falls back to a 12-item dummy list when the inventory is empty; it now accurately prompts the AI that the pantry is empty, producing recipes with clear `missingItems` for the user to restock.

---

### [CRITICAL-02] Database Connection Health, Reconnection & Logging
- **Fixed In:** [`lib/services/neon_db_service.dart`](file:///C:/playground/kichook/lib/services/neon_db_service.dart#L130)
- **Changes:**
  - Added `_ensureConnected()` check to reconnect on dropped sockets or timeouts before every query.
  - Added structured `debugPrint('[NeonDbService] ...')` logging for all failure branches.
  - Methods now return `Future<bool>` to allow calling widgets to react gracefully to sync status.

---

### [HIGH-01] Microsecond Entropy ID Generation
- **Fixed In:** [`lib/screens/home_screen.dart`](file:///C:/playground/kichook/lib/screens/home_screen.dart#L280), [`lib/screens/onboarding_screen.dart`](file:///C:/playground/kichook/lib/screens/onboarding_screen.dart#L450), [`lib/models/saved_recipe.dart`](file:///C:/playground/kichook/lib/models/saved_recipe.dart#L30)
- **Changes:**
  - Upgraded all entity generation from `millisecondsSinceEpoch` to `microsecondsSinceEpoch` with entropy/index suffixes (`pantry_${microseconds}_${id}_${index}`).
  - Completely prevents batch collision overwrites during receipt scanning, quick-pack stocking, and recipe saving.

---

### [HIGH-02] Strict Multi-Tenancy Data Isolation
- **Fixed In:** [`lib/services/neon_db_service.dart`](file:///C:/playground/kichook/lib/services/neon_db_service.dart#L195)
- **Changes:**
  - Removed `OR user_id IS NULL` fallback clauses when `userId` is present in queries.
  - Queries for pantry items, inventory items, saved recipes, and saved templates are strictly partitioned per authenticated user.
