# Tech Context: Godot ARPG

## 1. Game Engine
- **Engine:** Godot 4.x
- **Rationale:** The user has specified Godot as the engine of choice. Version 4.x offers significant improvements in rendering, scripting, and performance, making it suitable for an ARPG.

## 2. Primary Language
- **Language:** GDScript
- **Rationale:** GDScript is tightly integrated with the Godot API, offering a rapid development workflow. Its syntax is clear and easy to learn. We will assume GDScript unless the user specifies a preference for C#.
- **Typing:** All new GDScript code **must** use static typing (`var my_var: Type = value`) to improve code clarity, enable better autocompletion, and reduce runtime errors.

## 3. Core Godot Features to Leverage
- **`Resource` System:** This is the cornerstone of our data-driven design. All game data (items, skills, enemy stats, etc.) will be defined as custom `Resource` types. This decouples data from code, making it easy for designers to manage and for the game to load.
- **Scene Composition:** We will favor composition over inheritance. Game objects will be built by composing smaller, reusable scenes (e.g., a `HealthComponent` scene, an `ActorSprite` scene) rather than creating deep inheritance hierarchies.
- **Signals:** Signals will be the primary method for communication between decoupled systems. This helps avoid hard-coded references and keeps components modular. For example, a `HealthComponent` will emit a `died` signal, which a `LootDropComponent` can listen for.
- **Autoloads (Singletons):** Global systems like the `EventManager`, `GameManager`, or `SaveManager` will be implemented as Autoloads for easy access from anywhere in the project. Use sparingly to avoid over-reliance on global state.

## 4. Version Control
- **System:** Git
- **Recommendation:** It is highly recommended to use a version control system like Git from the very beginning to track changes and collaborate effectively. We should configure it to handle Godot's text-based scene files (`.tscn`) and resources (`.tres`) properly.
