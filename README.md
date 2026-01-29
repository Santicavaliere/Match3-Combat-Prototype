# Match-3 RPG Combat Prototype (Godot 4.4)

A modular Match-3 core integrated with a turn-based RPG combat system. Built with Godot 4.4 and fully optimized for Android mobile devices in landscape orientation.

## Key Features

* **Modular Architecture:** The Puzzle logic (GridManager) is strictly decoupled from the Combat logic (CombatManager) using a Signal Bus pattern, allowing for independent testing and scalability.
* **Panoramic Grid System:** Implements a 12-column by 7-row grid designed for landscape displays. The viewport dynamically scales to occupy the bottom 70% of the screen, leaving the top 30% for combat visualization.
* **Turn-Based Combat:** Features a robust state machine managing Player and Enemy phases. The player operates on an Action Point (AP) system (3 moves per turn), with automatic input locking during enemy phases.
* **Mana Generation System:** Matching tiles generates mana specific to the tile color. This data is tracked in the backend to support future ability activation.
* **Mobile Optimized Input:** Touch input system handles swipe and tap detection seamlessly on Android devices.
* **Smooth Animations:** Tween-based animations for swapping, falling, and cascading pieces.

## Project Structure

* **GridManager.gd:** Handles the core puzzle mechanics including input detection, swapping logic, match finding algorithms, gravity, and board refilling.
* **CombatManager.gd:** The central brain of the RPG layer. It orchestrates the turn order, manages the Action Point (AP) counter, calculates mana generation based on matches, and handles state transitions between Player and Enemy turns.
* **Piece.gd:** Represents individual tiles. Handles its own visual state and input signals.
* **SignalBus.gd (Autoload):** The communication bridge that allows the Grid and Combat systems to exchange data without direct dependencies.

## Technical Documentation: Combat Integration

The system uses a Global Signal architecture to drive the combat state based on puzzle actions.

### 1. Match & Mana Logic
* **Signal:** match_found(gem_type: int, amount: int)
* **Trigger:** Emitted by GridManager whenever a match is cleared.
* **Behavior:** The CombatManager receives this signal and increments the mana pool for the corresponding color.

### 2. Turn System & Action Points
* **Constraint:** The player is limited to 3 Action Points (moves) per turn.
* **Flow:**
    1.  **Player Turn:** Grid input is unlocked. Every valid swap consumes 1 AP.
    2.  **Turn End:** When AP reaches 0, the Grid input is strictly locked.
    3.  **Enemy Turn:** The system simulates an enemy phase (placeholder for AI logic).
    4.  **Reset:** Control returns to the player, and AP is refilled.

## How to Test (Android)

* **APK:** A pre-compiled .apk file is included for immediate testing on Android devices.
* **Orientation:** The project is configured for **Landscape Mode**.
* **Controls:** Tap a piece to select it, then tap an adjacent piece to swap. Alternatively, swipe to swap.
* **Verification:**
    * **Mana:** Check the debug console to see mana values updating upon matches.
    * **Turns:** Perform 3 moves to verify that the board locks and the turn state transitions correctly.

## Developed by Santiago