-- Controller.lua
-- Main server-side controller for the Capture the Flag game, managing game state, events, and subsystems.
local Controller = {}
Controller.__index = Controller

-- Singleton instance stored in module scope:
local _instance: any = nil

function Controller.get()
	if _instance then
		return _instance
	end

	local self = setmetatable({}, Controller)

	-- Services / dependencies (cached)
	self.Players = game:GetService("Players")
	self.Teams = game:GetService("Teams")
	self.ReplicatedStorage = game:GetService("ReplicatedStorage")

	self.constants = require(self.ReplicatedStorage.Shared.Constants)
	self.utilities = require(self.ReplicatedStorage.Shared.Utilities)

	self.currentPhase = self.constants.Phase.MENU
	self.isTransitioning = false
	self.roundPlayers = {} :: { Player }

	-- Subsystems
	self.State = nil
	self.TeamAssignment = nil
	self.Events = nil
	self.ServerUpdate = nil
	self.PlayerCollision = nil
	
	_instance = self
	return self
end

function Controller:init()
	self.State = require(script.Parent.ServerController.ServerState)	
	self.Events = require(script.Parent.ServerController.ServerEvents)
	self.ServerUpdate = require(script.Parent.ServerController.ServerUpdate)
	self.TeamAssignment = require(script.Parent.GameControllers.TeamAssignment)
	self.PlayerCollision = require(script.Parent.GameControllers.PlayerCollision)
	
	self.State:init(self)
	self.Events:init(self)
	self.ServerUpdate:init(self)
	self.TeamAssignment:init(self)
	self.PlayerCollision:init(self)

	-- Initial broadcast	
	self.Events:phaseChange(self.currentPhase, "")
	print("[ServerController] Initialized. Phase =", self.currentPhase)
end

return Controller
