# Kichook - Grocery Shopping List Android App

## Project Overview
Kichook is a modern, high-performance Android mobile application built with Flutter to help users seamlessly create, manage, and optimize their grocery shopping lists.

## Mandatory Agent Protocol
- **Pre-Edit Explanation Requirement**: Before creating, updating, or modifying any code or project files, the AI agent MUST explain the planned changes, target files, and rationale clearly to the user.
- **Android Target**: The project is a native-feeling mobile Android app built in Flutter.

## Plan & Roadmap

### Phase 1: Environment & Setup Inspection
1. Locate Flutter SDK on the system (or verify path) and check dependencies.
2. Generate high-quality visual assets using AI image generation:
   - Impressive Splash Screen Banner & Animated/Branded Splash Assets.
   - App Logo & Icon (`kichook_logo.png`).
   - Fresh Fruit & Grocery Category & Product Thumbnails (Avocado, Dragon Fruit, Orange, Berries, Fresh Veggies, Dairy, Beverages, Bakery).

### Phase 2: Core Features & Architecture
1. **Splash Screen (`lib/screens/splash_screen.dart`)**:
   - Modern animated splash screen featuring the **Kichook Logo**, slogan ("Smart Grocery Shopping, Simplified"), smooth scale/fade animations, and seamless transition to the main screen.

2. **Main Shopping & Grocery List UI (`lib/screens/home_screen.dart`)**:
   - **Top Header**: Back button, Page Title ("Fresh Fruits"), Search Bar with live search, Filter buttons ("Sort By", "Price Drop").
   - **Left Category Sidebar**: Vertical scrollable category bar with icons (Fresh Fruits, Seasonal, Exotic, Cut Fruits, Organic, Dairy, Snacks, etc.).
   - **Product Grid**: Responsive 2-column grid featuring:
     - High-res product images
     - Badges ("Ad", "25% OFF", "7 MINS delivery", "Veg Tag", "Perfect Ripe")
     - Product title, weight/quantity selector pills ("180 - 220 g")
     - Rating stars & review counts (e.g. ★ 4.4 [383])
     - Struck-through original price & discounted price
     - **Interactive Add Stepper**: White/Blue `+` button that morphs into a `- count +` stepper when added to shopping list.
     - Bookmark / Wishlist toggle icon.

3. **Floating Shopping List / Cart Drawer (`lib/widgets/cart_bottom_bar.dart` & `lib/screens/cart_screen.dart`)**:
   - Bottom floating cart banner showing item count, preview thumbnail, total price, and "View Shopping List / Checkout" action.
   - Expandable Shopping List view where users can check off items while in the store, edit quantities, see budget total, and share/export the list.

### Phase 3: Verification & Polishing
1. Check dependencies and ensure zero compilation/lint errors.
2. Verify visual aesthetics, responsive layout, animations, and touch targets.
