-- GoalManager.lua
local Workspace = game:GetService("Workspace")

local GoalDetector = require(script.Parent.GoalDetector)

local GoalManager = {}
GoalManager.__index = GoalManager

function GoalManager:init(controller)
	local self = setmetatable({}, GoalManager)

	self.controller = controller	
	self.detectorsByPart = {} -- [BasePart] = GoalDetector

	-- simple callback list
	self._listeners = {}

	self.goalsFolder = Workspace:WaitForChild("Goals")

	self._addedConn = nil
	self._removedConn = nil

	self:_initExisting()
	self:_watchFolder()

	self:onGoalScored(function(player, detector)
		-- detector.team, detector.goalId, detector.part available
		print(("GOAL: %s touched goal %s (team=%s)")
			:format(player.Name, detector.goalId, tostring(detector.team)))

			local bm = self.controller.BallManager
			local events = self.controller.Events
			if not bm then return end

			local carryingBall = bm:isCarrying(player)
		
			if carryingBall then
				if player.Team.Name ~= tostring(detector.team) then
					local carriedBall = bm:getCarriedBall(player)
					if carriedBall then
						carriedBall:drop(player)						
						bm:destroyBall(carriedBall.ballId)
						bm:createRandomBall()
						self:increaseGoalScore(player.Team.Name == self.controller.constants.Team.RED)
						events:broadcast(self.controller.constants.Events.GOAL_SCORED, self:packGoalScored(player.Team.Name))
					end
				end
			end		
	end)
	
	return self
end

function GoalManager:increaseGoalScore(isRedTeam: boolean)
	if isRedTeam then
		self.controller.scoreTeamRed += 1
		print(("[GoalManager:increaseGoalScore]: RED TEAM = %d"):format(self.controller.scoreTeamRed))
	else
		self.controller.scoreTeamBlue += 1
		print(("[GoalManager:increaseGoalScore]: BLUE TEAM = %d"):format(self.controller.scoreTeamBlue))
	end
end

function GoalManager:packGoalScored(teamScored: string)
	return {
			team = teamScored,
			red = self.controller.scoreTeamRed,
			blue = self.controller.scoreTeamBlue,
		}
end

function GoalManager:getCurrentScore()
	return {
			red = self.controller.scoreTeamRed,
			blue = self.controller.scoreTeamBlue,
		}
end

function GoalManager:_initExisting()
	for _, inst in ipairs(self.goalsFolder:GetChildren()) do
		if inst:IsA("BasePart") then
			self:_addGoalPart(inst)
		end
	end
end

function GoalManager:_watchFolder()
	self._addedConn = self.goalsFolder.ChildAdded:Connect(function(inst)
		if inst:IsA("BasePart") then
			self:_addGoalPart(inst)
		end
	end)

	self._removedConn = self.goalsFolder.ChildRemoved:Connect(function(inst)
		if inst:IsA("BasePart") then
			self:_removeGoalPart(inst)
		end
	end)
end

function GoalManager:_addGoalPart(part: BasePart)
	if self.detectorsByPart[part] then return end

	-- create detector, route scored event back to manager
	local detector = GoalDetector:init(self.controller, part, function(player, det)
		self:_emitScored(player, det)
	end)

	self.detectorsByPart[part] = detector
end

function GoalManager:_removeGoalPart(part: BasePart)
	local detector = self.detectorsByPart[part]
	if detector then
		detector:destroy()
		self.detectorsByPart[part] = nil
	end
end

function GoalManager:onGoalScored(callback: (player: Player, detector: any) -> ())
	table.insert(self._listeners, callback)	
end

function GoalManager:_emitScored(player, detector)
	for _, cb in ipairs(self._listeners) do
		-- protect against callback errors breaking manager
		local ok, err = pcall(cb, player, detector)
		if not ok then
			warn("[GoalManager] listener error:", err)
		end
	end
end

function GoalManager:destroyAll()
	for part, detector in pairs(self.detectorsByPart) do
		detector:destroy()
		self.detectorsByPart[part] = nil
	end
end

function GoalManager:destroy()
	self:destroyAll()
	if self._addedConn then self._addedConn:Disconnect() end
	if self._removedConn then self._removedConn:Disconnect() end
	self._addedConn = nil
	self._removedConn = nil
	self._listeners = {}
end

return GoalManager