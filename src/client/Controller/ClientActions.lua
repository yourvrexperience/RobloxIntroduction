local Workspace = game:GetService("Workspace")

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
				self.controller.Events:throwBall()
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
	
	local finalPosition = spawnPositionsFinal[position]
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

	local finalPosition = finalList[finalIndex]
	self.controller.humanoidRootPart.CFrame = CFrame.new(finalPosition)
end

function ClientActions:teleportCenterField()	
	self.controller.humanoidRootPart.CFrame = self.controller.constants.Field.CENTER_FIELD
end

return setmetatable({}, ClientActions)