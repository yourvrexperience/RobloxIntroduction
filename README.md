# 🏉 MultiBall Rugby — Roblox Introduction for Game Developers

A hands-on course for experienced game developers (Unity, Unreal Engine, Godot, etc.) to become productive in Roblox in the shortest time possible.

Build a fully functional **multiplayer rugby game** where players pick up balls, carry them into the rival team's goal, and tackle opponents — all while learning Roblox's architecture, networking, and tooling.

---

## 🎯 What You Will Learn

- Essentials of Roblox Studio
- Connecting Roblox Studio to VS Code via Rojo
- Lua/Luau essentials (class declaration, metatables, singletons)
- Designing a professional, scalable code architecture

## 🚀 What You Will Deliver

- A professional working environment (Roblox Studio + VS Code)
- A clean, scalable code architecture with client/server separation
- A networked event system for multiplayer communication
- A functional multiplayer game

---

## 📐 Project Architecture

The project follows a **Rojo-style** `src/` structure with a clear separation between client, server, and shared code — a pattern familiar to developers coming from other engines.

```
src/
├── client/                          # Runs on each player's machine
│   ├── init.client.luau             # Entry point
│   ├── ClientController.lua         # Singleton: manages client state, services, and sub-modules
│   └── Controller/
│       ├── ClientActions.lua        # Player actions: teleport, freeze, spawn positions
│       ├── ClientAudio.lua          # 2D sound playback (clone + play + cleanup)
│       ├── ClientEvents.lua         # RemoteEvent listeners and senders
│       ├── ClientScreens.lua        # Screen manager: show/hide ScreenGuis by game phase
│       ├── ClientStateChanged.lua   # Reacts to phase transitions on the client
│       ├── ClientUpdate.lua         # Heartbeat loop: timers, countdowns, per-phase logic
│       └── Screens/
│           ├── ScreenMenu.lua       # Main menu with Play button
│           ├── ScreenLoading.lua    # Loading screen
│           ├── ScreenGame.lua       # In-game HUD (score, timer)
│           └── ScreenGameOver.lua   # Game over with reload countdown
│
├── server/                          # Runs on the Roblox server (authoritative)
│   ├── init.server.luau             # Entry point
│   └── Game/
│       ├── Controller.lua           # Singleton: manages server state and all subsystems
│       ├── ServerController/
│       │   ├── ServerState.lua      # State machine: MENU → LOAD → GAME → GAME_OVER
│       │   ├── ServerEvents.lua     # RemoteEvent handling, broadcast, client event routing
│       │   └── ServerUpdate.lua     # Heartbeat loop: game timer, ball updates, phase transitions
│       └── GameControllers/
│           ├── Ball.lua             # Single ball: spawn, pickup, carry, throw, drop, physics
│           ├── BallManager.lua      # Multi-ball pool: creation, destruction, carrier tracking
│           ├── BallSpawner.lua      # Random ball spawning with impulse-based kick behavior
│           ├── GoalDetector.lua     # Touched-based goal zone detection with cooldown
│           ├── GoalManager.lua      # Manages all goal zones, scoring logic, score tracking
│           ├── PlayerCollision.lua  # Tackle mechanic: opposite-team collision forces ball drop
│           └── TeamAssignment.lua   # Team splitting, visual markers (neon sphere above head)
│
└── shared/                          # Accessible by both client and server
    ├── Constants.lua                # All game constants: phases, events, teams, physics, timings
    ├── Utilities.lua                # Helper functions: time formatting, player detection, etc.
    ├── LanguageManager.lua          # i18n system with dot-path keys and interpolation
    └── LanguageData.lua             # Localization strings (English + Spanish)
```

### How It Maps to Other Engines

| Roblox Concept | Unity Equivalent | Unreal Equivalent |
|---|---|---|
| `Controller.lua` (server singleton) | `GameManager` MonoBehaviour | `AGameMode` |
| `ServerState.lua` (state machine) | Custom state machine / `GameState` | `AGameState` |
| `RemoteEvent` / `RemoteFunction` | Netcode RPCs / Mirror `[Command]`/`[ClientRpc]` | RPCs / `Server`/`Client` functions |
| `RunService.Heartbeat` | `Update()` / `FixedUpdate()` | `Tick()` |
| `ReplicatedStorage` | `Resources` folder / Addressables | Content shared between client/server |
| `PlayerGui` / `ScreenGui` | Canvas / UI Toolkit | UMG Widget |
| `Teams` service | Custom team system | `APlayerState` team ID |

---

## 🎮 Game Flow

The game follows a state machine with these phases:

```
INIT → MENU → LOAD → GAME → GAME_OVER → MENU (loop)
```

1. **MENU** — Players see the main menu. Any player can press "Play" to start.
2. **LOAD** — Teams are assigned, markers created, balls spawned, players teleported to spawn positions.
3. **GAME** — ~5 minute match. Players pick up balls, carry them to the rival goal, and can be tackled.
4. **GAME_OVER** — Results shown, countdown to reload. After the countdown, returns to MENU.

---

## 🔧 Setup

### Prerequisites

- [Roblox Studio](https://www.roblox.com/create) installed
- [Visual Studio Code](https://code.visualstudio.com/) installed
- [Rojo](https://rojo.space/) extension for VS Code (bridges Studio ↔ VS Code)

### Getting Started

1. Clone or download this repository.
2. Open the project folder in VS Code.
3. Start the Rojo server (`rojo serve`) from VS Code.
4. Open your Roblox Studio place and connect to the Rojo server.
5. The `src/` folder will sync into your Roblox place automatically.

### Roblox Studio Setup

You will need to create the following assets and objects manually in Roblox Studio (they are not part of the code repository):

- **ReplicatedStorage/Assets/SoccerBall** — A Model with a PrimaryPart set (the ball asset).
- **ReplicatedStorage/Audio/** — Sound instances: `SoundGameStarts`, `SoundGameEnds`, `SoundFxKick`, `SoundFxOuch`, `SoundFxGoal`.
- **ReplicatedStorage/RemoteEvents/** — Remote instances: `GamePhaseChanged` (RemoteEvent), `ServerEvents` (RemoteEvent), `ClientEvents` (RemoteEvent), `ThrowBall` (RemoteEvent), `RequestStart` (RemoteFunction).
- **Teams** — Two Team objects: `RED` and `BLUE`.
- **StarterGui/** — ScreenGuis: `ScreenInit`, `ScreenMenu` (with a `StartButton`), `ScreenLoad`, `ScreenGame` (with a `GameHUD` containing `Time`, `ScoreTeamRed`, `ScoreTeamBlue`), `ScreenGameOver` (with `GameOverHUD/ReloadingGame`), `ScreenGoalScored`.
- **Workspace/Goals/** — Two BaseParts (`GoalTeamBlue`, `GoalTeamRed`) each with a custom attribute `Team` set to `"BLUE"` or `"RED"`.
- **Workspace/SpawnPlayersBlue/** and **Workspace/SpawnPlayersRed/** — Folders with BaseParts marking spawn positions for each team.

---

## 📚 Course Exercises

The course is structured as a progressive series of exercises. Three difficulty levels are available for each exercise:

| Level | Description |
|---|---|
| **Advanced Challenge** | Overall functionality is described — you complete it on your own. |
| **Guided Challenge** | Steps are listed — you implement them independently. |
| **Step-by-Step** | Full walkthrough — follow along and replicate. |

### Exercise 1 — Ball Spawner (Introduction to Instancing)

Create a `SoccerBall` asset, spawn instances using `BallSpawner.lua`, add physics, detect player collisions, apply impulses, and use the event system to notify clients.

**Key files:** `BallSpawner.lua`, `ServerEvents.lua`, `ClientEvents.lua`, `Constants.lua`

### Exercise 2 — Single Ball (Pickup & Throw)

Replace the spawner with a single `Ball.lua` that can be picked up and thrown. Create a `ThrowBall` RemoteEvent, wire up server listening and client sending, and bind mouse click to throw.

**Key files:** `Ball.lua`, `ServerEvents.lua`, `ClientEvents.lua`, `ClientActions.lua`

### Exercise 3 — Ball Manager (Multiple Balls)

Introduce `BallManager.lua` to manage multiple ball instances. Players should be able to pick up and throw any ball.

**Key files:** `BallManager.lua`, `Controller.lua`

### Exercise 4 — Tackle Mechanic (Player Collision)

Implement the tackle system: when two players from opposite teams collide and one is carrying a ball, the ball is forced out.

**Key files:** `PlayerCollision.lua`

### Exercise 5 — Goal Scoring

Create goal zones that detect when a player carrying a ball enters the rival's goal. Set up the `Goals` folder in Studio with team attributes.

**Key files:** `GoalDetector.lua`, `GoalManager.lua`

### Exercise 6 — Screen Refactoring

Refactor the monolithic screen management into individual screen modules for better scalability.

**Key files:** `ClientScreens.lua`, `ScreenMenu.lua`, `ScreenLoading.lua`, `ScreenGame.lua`, `ScreenGameOver.lua`

### Exercise 7 — Score Display

Add two text labels to the Game HUD to display the live score for each team.

**Key files:** `ScreenGame.lua` (Studio: `StarterGui/ScreenGame/GameHUD`)

### Exercise 8 — Goal Sound Effect

Add a new sound that plays when a player scores a goal. Understand how `ClientAudio.lua` works.

**Key files:** `ClientAudio.lua`, `Constants.lua` (Studio: `ReplicatedStorage/Audio/SoundFxGoal`)

### Exercise 9 — Goal Scored Screen

Create a celebratory screen that shows briefly when the player's team scores. Wire a server-to-client event and manage the screen display with a timed auto-hide.

**Key files:** `ClientScreens.lua`, `ClientEvents.lua`, `Constants.lua`

### Exercise 10 — Spawn Positions

Teleport players to predefined team-based spawn positions when a match starts. Create spawn folders in Studio with positioned parts.

**Key files:** `ClientActions.lua`, `ServerState.lua`, `ClientEvents.lua`

### Exercise 11 — Late Joiners & Field Boundaries

Handle players who join mid-match: teleport them outside the field. Create invisible collision boundaries and visible field borders. After the match ends, teleport everyone back inside.

**Key files:** `ClientEvents.lua`, `ClientActions.lua`, `Constants.lua`

---

## 🗂️ Key Concepts Reference

### Networking Model

The game uses a **server-authoritative** model. All game logic (ball physics, scoring, state transitions) runs on the server. Clients send requests via RemoteEvents and the server validates and broadcasts results.

```
Client → [RemoteEvent: ClientEvents] → Server (validates) → [RemoteEvent: ServerEvents] → All Clients
```

### Event System

Events are string-based and centralized in `Constants.Events`. The server and client each have a single RemoteEvent channel (`ServerEvents` / `ClientEvents`) that routes all custom game events through a unified handler.

### State Machine

Both server and client maintain a `currentPhase` that drives which logic runs in their respective update loops and which UI screens are visible.

---

## 📝 Localization

The project includes a lightweight i18n system (`LanguageManager.lua`) supporting English and Spanish. Add new languages by extending `LanguageData.lua` with a new language key.

```lua
-- Usage
local text = i18n:t("menu.rules.title")           -- "How to Play"
local text = i18n:t("score.label", {value = 10})   -- interpolation
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
