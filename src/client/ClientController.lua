-- ClientController.lua
-- Manages client-side state, events, and UI for the Capture the Flag game.
local ClientController = {}
ClientController.__index = ClientController

local _instance = nil

function ClientController.get()
	if _instance then return _instance end

	local self = setmetatable({}, ClientController)

	-- Services / dependencies (cached)
	self.ReplicatedStorage = game:GetService("ReplicatedStorage")
	self.ContextActionService = game:GetService("ContextActionService")
	self.Players = game:GetService("Players")
	self.ReplicatedStorage = game:GetService("ReplicatedStorage")
	self.UserInputService = game:GetService("UserInputService")

	self.constants = require(self.ReplicatedStorage.Shared.Constants)
	self.utilities = require(self.ReplicatedStorage.Shared.Utilities)

	self.localHumanoid = nil
	self.humanoidRootPart = nil
	self.localPlayer = self.Players.LocalPlayer
	self.localPlayer.CharacterAdded:Connect(function(character)
		self.localHumanoid = character:WaitForChild("Humanoid")
		self.humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		-- self.humanoidRootPart.CFrame = self.constants.Field.OUTSIDE_FIELD -- SET THE INITIAL POSITION OF THE PLAYER
	end)
	
	-- Local state
	self.currentPhase = self.constants.Phase.INIT	
	self.team = nil -- later: string/TeamColor/etc...

	-- Modules (filled in init)
	self.StateChanged = nil
	self.Actions = nil
	self.Events = nil
	self.Update = nil
	self.Screens = nil
	self.Audio = nil

	self.scoreRed = 0
	self.scoreBlue = 0

	_instance = self
	return self
end

function ClientController:init()
	self.StateChanged = require(script.Parent.Controller.ClientStateChanged)
	self.Actions = require(script.Parent.Controller.ClientActions)
	self.Events = require(script.Parent.Controller.ClientEvents)
	self.Update = require(script.Parent.Controller.ClientUpdate)
	self.Screens = require(script.Parent.Controller.ClientScreens)
	self.Audio = require(script.Parent.Controller.ClientAudio)

	self.Screens:init(self)
	self.StateChanged:init(self)
	self.Events:init(self)
	self.Actions:init(self)
	self.Update:init(self)	
	self.Audio:init(self)
	print("[ClientController] Initialized. Phase =", self.currentPhase)
end

return ClientController
