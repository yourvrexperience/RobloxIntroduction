-- ServerState.lua
local ServerState = {}
ServerState.__index = ServerState

function ServerState:init(controller)
	self.controller = controller
	self.enable_debug_messages = false
end

function ServerState:setPhase(newPhase: string, data: any)
	local c = self.controller
	c.currentPhase = newPhase
	c.Events:phaseChange(newPhase, data)
	c.ServerUpdate:stateChanged()
	if self.enable_debug_messages then
		print("[ServerState] Phase ->", newPhase)
	end
end

function ServerState:enterLoad()
	if self.enable_debug_messages then
		print("[ServerState:enterLoad]")
	end
	local c = self.controller
	if c.isTransitioning then return end
	c.isTransitioning = true
	local playerList = c.Players:GetPlayers()

	-- Send spawn positions to players 
	local counterPlayerRed = 0 
	local counterPlayerBlue = 0 
	for _, p in ipairs(playerList) do 
		if p.Character then 
			if p.Team == self.controller.constants.Team.RED then
				counterPlayerRed += 1 
				c.Events:sendTo(p, c.constants.Events.SPAWN_POSITION, tostring(counterPlayerRed))
			else
				counterPlayerBlue += 1 
				c.Events:sendTo(p, c.constants.Events.SPAWN_POSITION, tostring(counterPlayerBlue))
			end
		end 
	end

	task.wait(0.2)
	self:setPhase(c.constants.Phase.LOAD, "")

	-- Loading/Initializing resources
	c.TeamAssignment:assignTeams(playerList)
	c.TeamAssignment:setupAllMarkers()
	-- self.controller.BallSpawner:respawn(6)
	-- self.controller.Ball:spawnBall(CFrame.new(10, 10, 0)) 
	
	-- Spawn balls local 
	local totalBalls = math.floor(#playerList) 
	if totalBalls == 0 then 
		totalBalls = 1 
	end 

	for i = 1, totalBalls do 
		self.controller.BallManager:createRandomBall() 
	end 

	-- Change to GAME
	task.wait(1)
	self:setPhase(c.constants.Phase.GAME, "")

	c.isTransitioning = false
end

function ServerState:enterGameOver()
	if self.enable_debug_messages then
		print("[ServerState:enterGameOver]")
	end
	local c = self.controller
	if c.isTransitioning then return end
	c.isTransitioning = true

	self:setPhase(c.constants.Phase.GAME_OVER, "")

	-- self.controller.BallSpawner:clear()
	-- self.controller.Ball:destroy()

	if c.BallManager then 
		c.BallManager:destroyAll() 
	end	

	c.isTransitioning = false
end


function ServerState:reloadMenu()
	if self.enable_debug_messages then
		print("[ServerState:reloadMenu]")
	end
	local c = self.controller
	if c.isTransitioning then return end
	c.isTransitioning = true
	
	self:setPhase(c.constants.Phase.MENU, "")
	
	if c.TeamAssignment then
		c.TeamAssignment:clearMarkers()
	end
	
	if c.PlayerCollision then
		c.PlayerCollision:resetRound()
	end

	c.Events:broadcast(c.constants.Events.TELEPORT_INSIDE_FIELD)
	
	c.isTransitioning = false
end

return setmetatable({}, ServerState)
