local GoalDetector = {}
GoalDetector.__index = GoalDetector

export type GoalDetector = typeof(setmetatable({}, GoalDetector))

function GoalDetector:init(controller:any, goalPart: BasePart, onScored: (player: Player, detector: any) -> ())
	local self = setmetatable({}, GoalDetector)
	
	self.controller = controller
	self.part = goalPart
	self.onScored = onScored

	self.team = goalPart:GetAttribute("Team") -- "Red"/"Blue"/etc.
	self.goalId = goalPart:GetAttribute("GoalId") or goalPart.Name
	self.cooldown = goalPart:GetAttribute("Cooldown") or self.controller.constants.Game.COOLDOWN_GOAL_DETECTION

	-- per-player debounce
	self._lastTouchByUserId = {}
	self._conn = nil
	self._destroyed = false

	self:_connect()
	return self
end

function GoalDetector:_connect()
	self._conn = self.part.Touched:Connect(function(hit)
		local player = self.controller.utilities:getPlayerFromHit(hit)
		if not player then return end
		if self._destroyed then return end

		local now = os.clock()
		local last = self._lastTouchByUserId[player.UserId]
		if last and (now - last) < self.cooldown then
			return
		end
		self._lastTouchByUserId[player.UserId] = now

		-- Fire callback
		if self.onScored then
			self.onScored(player, self)
		end
	end)
end

function GoalDetector:destroy()
	self._destroyed = true
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
	self._lastTouchByUserId = {}
end

return GoalDetector