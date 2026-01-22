# Match-3 Combat Prototype (Godot 4.4)

A modular and scalable Match-3 core implementation designed for easy integration with RPG/Combat systems. Built with Godot 4.4, fully optimized for Android mobile devices.

## Key Features

* **Modular Architecture:** The Puzzle logic (`GridManager`) is completely decoupled from the Combat logic (`CombatManager`) using a Signal Bus pattern.
* **Mobile Optimized:** Input system handles both Mouse and Touch events seamlessly, preventing "double-click" issues on Android.
* **Scalable Grid:** Procedural grid generation with support for different board sizes and match detection algorithms.
* **Smooth Animations:** Tween-based animations for swapping, falling, and cascading pieces.

## Project Structure

* **`GridManager.gd`**: Handles the core puzzle mechanics (Input, Swapping, Match Finding, Gravity/Refill).
* **`CombatManager.gd`**: Listens for match events and calculates damage/healing. This is the integration point for future battle systems.
* **`Piece.gd`**: Represents individual tiles. Handles its own input detection and visual state.
* **`SignalBus.gd`**: (Autoload) The communication bridge that allows systems to talk without direct dependencies.

## Combat Hook Documentation

The system uses a **Global Signal** to broadcast puzzle events to the combat system.

**Signal:** `match_found(gem_type: int, amount: int)`

* **Trigger:** Emitted by `GridManager` whenever a match is cleared.
* **Payload:**
    * `gem_type`: The ID of the matched tile (0: Red, 1: Blue, etc.).
    * `amount`: How many tiles were destroyed.
* **Usage:** The `CombatManager` connects to this signal to apply damage multipliers based on the gem color.

## How to Test (Android)

1.  **APK:** A pre-compiled `.apk` file is included in the delivery for immediate testing on an Android device.
2.  **Controls:** Tap a piece to select it, then tap an adjacent piece to swap.
3.  **Orientation:** The project is configured for **Portrait Mode**.

---
*Developed by Santiago*