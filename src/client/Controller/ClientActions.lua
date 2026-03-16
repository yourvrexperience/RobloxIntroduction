local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VRController = require(ReplicatedStorage.Shared.VRController)

local ClientActions = {}
ClientActions.__index = ClientActions

local UserInputService = game:GetService("UserInputService")

function ClientActions:init(controller)
	self.controller = controller	
	
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if controller.currentPhase == controller.constants.Phase.GAME then
				self.controller.Audio:play2D(self.controller.constants.Sounds.SOUND_FX_KICK)
				if VRController.isVR then
					self.controller.Events:throwBall({ 
						origin = self.controller.Update.positionOrigin,
						direction = self.controller.VRController:VRDirection()
					})
				else
					self.controller.Events:throwBall(nil)
				end
			end
		end
	end)	
end

function ClientActions:freezeHumanoid()
	self.controller.humanoidRootPart.Anchored = true
end

function ClientActions:unfreezeHumanoid()
	self.controller.humanoidRootPart.Anchored = false
end

function ClientActions:fillSpawnPositionsInFieldData()
	local spawnPlayersBlue = Workspace:WaitForChild("SpawnPlayersBlue")
	local spawnPlayersRed = Workspace:WaitForChild("SpawnPlayersRed")

	self.spawnPositionsBlue = {}
	self.spawnPositionsRed = {}

	self:fillSpawnPosition(self.spawnPositionsBlue, spawnPlayersBlue)
	self:fillSpawnPosition(self.spawnPositionsRed, spawnPlayersRed)
	
	-- print("[fillSpawnPositionsInFieldData] ITEM BLUE =", #self.spawnPositionsBlue)
	-- print("[fillSpawnPositionsInFieldData] ITEM RED =", #self.spawnPositionsRed)	
end

function ClientActions:fillSpawnPosition(spawnsTable, spawnsFolder)
	for _, part in ipairs(spawnsFolder:GetChildren()) do
		if part:IsA("BasePart") then
			table.insert(spawnsTable, part.Position)
		end
	end
end

function ClientActions:teleportIntoFieldSpawn(position: number)	
	self.controller.Screens:showForPhase(self.controller.constants.Screen.LOAD)
	
	ClientActions:fillSpawnPositionsInFieldData()
	
	local spawnPositionsFinal = self.spawnPositionsBlue
	if self.controller.localPlayer.Team.Name == self.controller.constants.Team.RED then
		spawnPositionsFinal = self.spawnPositionsRed
	end
	
	local finalPosition = Vector3.new(spawnPositionsFinal[position].x,spawnPositionsFinal[position].y + 10,spawnPositionsFinal[position].z)
	self.controller.humanoidRootPart.CFrame = CFrame.new(finalPosition)
end

function ClientActions:teleportIntoFieldRandom()	
	ClientActions:fillSpawnPositionsInFieldData()
	
	local randomNumber = math.random(0, 100)
	local finalIndex = 1
	local finalList = self.spawnPositionsBlue
	if randomNumber < 50 then 
		finalIndex = math.random(1, #self.spawnPositionsBlue)
	else 
		finalIndex = math.random(1, #self.spawnPositionsRed)
		finalList = self.spawnPositionsRed
	end	 

	local finalPosition = Vector3.new(finalList[finalIndex].x,finalList[finalIndex].y + 10,finalList[finalIndex].z)
	self.controller.humanoidRootPart.CFrame = CFrame.new(finalPosition)
end

function ClientActions:teleportCenterField()	
	self.controller.humanoidRootPart.CFrame = self.controller.constants.Field.CENTER_FIELD
end

function ClientActions:toggleFirstPerson()
	self.isFirstPerson = not self.isFirstPerson
	if self.isFirstPerson then
		self.controller.localPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
	else
		self.controller.localPlayer.CameraMode = Enum.CameraMode.Classic
		self.controller.localPlayer.CameraMaxZoomDistance = 128

		-- Force minimum zoom to push camera back, then release it
        self.controller.localPlayer.CameraMinZoomDistance = 12
        task.wait(0.1) -- let Roblox apply the zoom
        self.controller.localPlayer.CameraMinZoomDistance = 0
	end
end

function ClientActions:restoreThirdPerson()
	if self.isFirstPerson then
		self:toggleFirstPerson()
	end
end

return setmetatable({}, ClientActions)