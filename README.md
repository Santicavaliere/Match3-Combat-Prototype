# Match-3 RPG Combat Prototype (Godot 4.4)

A modular Match-3 core integrated with a turn-based RPG combat system. Built with Godot 4.4 and optimized for Android mobile devices. This prototype represents the completion of Phase 1 (Milestone 5), featuring a fully scalable backend for class-based abilities, resource management, and advanced grid physics.

## Key Features

* **Modular Architecture:** The Puzzle logic (GridManager) is strictly decoupled from the Combat logic (CombatManager) using a Signal Bus pattern, allowing for independent testing and scalability.
* **Scalable Ability System:** Implementation of a data-driven ability system using Godot Resources. Includes 15 unique skills across 5 player classes (Strategist, Explorer, Guardian, Gunslinger, Pirate).
* **Advanced Grid Physics:** * **Locked Pieces:** Support for immovable/unplayable tiles (e.g., 'Outlaw's Talisman' mechanic) that override standard gravity and swap logic.
    * **Transmutation:** Logic to convert tile types dynamically (e.g., 'Navigator's Route').
    * **Targeted Destruction:** Logic to identify and destroy specific patterns or tile IDs programmatically.
* **Resource Management:** A comprehensive Mana system tracking 4 distinct colors (Red, Blue, Green, Yellow). Costs are validated dynamically before ability execution.
* **Passive Entity System (Minions):** Support for summoned entities (e.g., 'Kraken Tentacles') that exist outside the grid but react to match-events passively via the backend loop.
* **Turn-Based State Machine:** Robust management of Player/Enemy phases, Action Point (AP) limits, and Win/Loss conditions (HP tracking).
* **Debug & QA Tools:** Integrated "AbilityTester" dashboard for immediate testing of backend mechanics, bypassing the need for organic match generation.

## Project Structure

* **GridManager.gd:** Handles core puzzle mechanics: procedural generation, input state machine, match detection algorithms, recursion/gravity, and physics overrides for locked pieces.
* **CombatManager.gd:** The central controller of the RPG layer. Orchestrates turn order, calculates damage/healing, manages the Mana Pool, and executes Ability Resources.
* **Ability.gd (Resource):** The base class for all skills using the Template Method pattern. Defines the interface for costs, description, and execution.
* **Specific Abilities (Scripts):** Individual implementations for complex logic (e.g., `Ability_Outlaw.gd`, `Ability_Kraken.gd`) that inherit from the base class.
* **SignalBus.gd (Autoload):** The communication bridge allowing Grid and Combat systems to exchange data without direct dependencies.

## Technical Documentation: Ability Integration

The system uses a `Resource` based architecture to define skills, making the addition of new content strictly data-driven without modifying core scripts.

### 1. Execution Pipeline
1.  **Trigger:** User selects an ability from the UI.
2.  **Validation:** `CombatManager` checks turn state, grid stability, and mana availability against the specific `Ability` costs.
3.  **Consumption:** If valid, mana is deducted from the respective pools (Red/Blue/Green/Yellow).
4.  **Execution:** The virtual `execute()` method is called, injecting the `CombatManager` dependency to allow access to the Grid or Game State.

### 2. Complex Mechanics Implementation
* **Physics Override (Outlaw Class):** Implemented via a `is_locked` flag in the `Piece` class. The `GridManager` input handler (both click and swipe) intercepts interactions with locked pieces, preventing movement while allowing adjacent matches to clear them.
* **Minion Logic (Pirate Class):** Implemented via an `active_tentacles` array in the `CombatManager`. This array is iterated during the `_on_match_made` signal, applying passive damage derived from the Enemy's current HP.

## How to Test

### Setup
* **Platform:** Android (Landscape) or Windows Debug.
* **Input:** Touch (Swipe/Tap) or Mouse.

### Testing Procedures
1.  **Combat Loop:** Perform matches to generate mana. Verify that Red matches deal damage, and other colors fill the Mana Dashboard.
2.  **Ability Activation:** Use the **AbilityTester** panel at the bottom of the screen.
    * Use the "Full Mana" cheat button to fill resources.
    * Scroll through the list of 15 abilities.
    * Activate abilities like "Outlaw's Talisman" to verify piece locking.
    * Activate "Kraken's Talisman" and perform a match to verify passive damage.
3.  **Win/Loss:** Reduce Enemy HP to 0 to verify the Victory state, or allow the Turn Counter to deplete player actions to trigger the Enemy Phase.

## Development Status
* **Phase:** Milestone 5 (Completed)
* **Next Steps:** Visual Polish (VFX), Enemy AI implementation, and XP/Progression systems.

Developed by Santiago.