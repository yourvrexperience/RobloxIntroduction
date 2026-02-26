local Ball = require(script.Parent.Ball)

local BallManager = {}
BallManager.__index = BallManager

function BallManager:init(controller)
	self.controller = controller
	self.balls = {} :: { [number]: any } -- id -> Ball
	self.carrierToBallId = {} -- [number] = number
	self._nextId = 0
	-- print("[BallManager] Initialized")
end

-- =========================
-- Creation / Destruction
-- =========================

function BallManager:createBall(spawnCFrame: CFrame)
	self._nextId += 1
	local id = self._nextId

	local ball = setmetatable({}, Ball)
	ball:init(self.controller)
	ball:spawnBall(spawnCFrame)
	ball.ballId = id
	ball.manager = self

	self.balls[id] = ball

	-- print("[BallManager] Ball created:", id)
	return id, ball
end

function BallManager:createRandomBall()
	self._nextId += 1
	local id = self._nextId

	local ball = setmetatable({}, Ball)
	local spawnCFrame = CFrame.new(0, 10, math.random(0, 70) - 35)
	ball:init(self.controller)
	ball:spawnBall(spawnCFrame)
	ball.ballId = id
	ball.manager = self

	self.balls[id] = ball

	-- print("[BallManager] Ball created:", id)
	return id, ball
end

function BallManager:destroyBall(id: number)
	local ball = self.balls[id]
	if not ball then return end

	ball:destroy()
	self.balls[id] = nil

	-- print("[BallManager] Ball destroyed:", id)
end

function BallManager:destroyAll()
	for id in pairs(self.balls) do
		self:destroyBall(id)
	end
	self.balls = {}
	self._nextId = 0
	self.carrierToBallId = {}
end

function BallManager:onThrowRequest(player: Player)
	local ball = self:getCarriedBall(player)
	if not ball then return end
	
	ball:ThrowRequest(player)
end

-- =========================
-- Round helpers
-- =========================

function BallManager:resetAll(spawnCFrame: CFrame)
	for _, ball in pairs(self.balls) do
		ball:reset(spawnCFrame)
	end
end

function BallManager:getCarriedBall(player: Player)
	local id = self.carrierToBallId[player.UserId]
	if not id then return nil end
	return self.balls[id]
end

function BallManager:getCarriedBallId(player: Player): number?
	return self.carrierToBallId[player.UserId]
end

function BallManager:isCarrying(player: Player): boolean
	return self.carrierToBallId[player.UserId] ~= nil
end

function BallManager:_setCarrier(player: Player, ballId: number?)
	if ballId == nil then
		self.carrierToBallId[player.UserId] = nil
	else
		self.carrierToBallId[player.UserId] = ballId
	end
end

-- =========================
-- Update loop
-- =========================

function BallManager:update(dt: number)
	for _, ball in pairs(self.balls) do
		if ball.update then
			ball:update(dt)
		end
	end
end

return setmetatable({}, BallManager)