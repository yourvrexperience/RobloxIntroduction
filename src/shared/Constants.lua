local Constants = {}

-- =========================
-- GAME
-- =========================
Constants.Game = {
	GAME_TIME = 310,	
	RELOAD_TIME = 5,
	COOLDOWN_GOAL_DETECTION = 1.0,
}

-- =========================
-- GAME
-- =========================
Constants.Sounds = {
	SOUND_GAME_STARTS = "SoundGameStarts",	
	SOUND_GAME_OVER = "SoundGameEnds",
	SOUND_FX_KICK = "SoundFxKick",
	SOUND_FX_OUCH = "SoundFxOuch",
}

-- =========================
-- EVENTS
-- =========================
Constants.Events = {
	REQUEST_STATE = "REQUEST_STATE",
	RESPONSE_STATE = "RESPONSE_STATE",
	COLLISION_PLAYERS = "COLLISION_PLAYERS",
	REQUEST_FORCE_END = "REQUEST_FORCE_END",
	BALL_TAKEN = "BALL_TAKEN",
	GOAL_SCORED = "GOAL_SCORED",
}

-- =========================
-- GAME PHASES
-- =========================
Constants.Phase = {
	INIT = "INIT",
	MENU = "MENU",
	LOAD = "LOAD",
	GAME = "GAME",
	GAME_OVER = "GAME_OVER",
}

-- =========================
-- TEAMS
-- =========================
Constants.Team = {
	RED = "RED",
	BLUE = "BLUE",
}

-- =========================
-- SCREEN KEYS
-- =========================
Constants.Screen = {
	INIT = "INIT",
	MENU = "MENU",
	LOAD = "LOAD",
	GAME = "GAME",
	GAME_OVER = "GAME_OVER",
}

-- =========================
-- PLAYER TEAM MARKER
-- =========================
Constants.PlayerMarker = {	
	SIZE_MARKER = Vector3.new(0.6, 0.6, 0.6),
	HEIGHT_MARKER = CFrame.new(0, 1.2, 0),
}

-- =========================
-- BALL
-- =========================
Constants.Ball = {
	BALL_SIZE =  Vector3.new(2, 2, 2),
	CARRY_OFFSET = CFrame.new(0, 0.5, -2),
	DROP_CLEAR_DELAY = 0.3,
	FORWARD_SPEED = 90,
	UPWARD_SPEED = 25,
	PHYSICAL_PROPERTIES = PhysicalProperties.new(
		0.7,  -- density
		0.3,  -- friction
		0.6,  -- elasticity
		1.0,  -- frictionWeight
		1.0   -- elasticityWeight
	),
}

return Constants
