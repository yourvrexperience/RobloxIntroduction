local RunService = game:GetService("RunService")

local ServerUpdate = {}
ServerUpdate.__index = ServerUpdate

function ServerUpdate:init(controller)
	self.controller = controller	
	self._accumulator = 0
	self._iterator = 0
	self._connection = nil
	self.remainingTime = 0
	self.enable_debug_messages = false

	self:start()
	if self.enable_debug_messages then
		print("[ServerUpdate] Initialized")
	end
end

function ServerUpdate:start()
	if self._connection then return end

	self._connection = RunService.Heartbeat:Connect(function(dt)
		self:update(dt)
	end)
end

function ServerUpdate:stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

function ServerUpdate:stateChanged()
	if self._connection then
		self._accumulator = 0
		self._iterator = 0
	end
end

function ServerUpdate:update(dt)
	self._accumulator += dt
	
	-- EVAL STATE
	if self.controller.currentPhase == self.controller.constants.Phase.MENU then
		if self.enable_debug_messages then
			print("[ServerUpdate] STATE MENU")
		end
	elseif self.controller.currentPhase == self.controller.constants.Phase.LOAD then
		if self.enable_debug_messages then
			print("[ServerUpdate] STATE LOAD")
		end
		self.remainingTime = self.controller.constants.Game.GAME_TIME
	elseif self.controller.currentPhase == self.controller.constants.Phase.GAME then
		if self.enable_debug_messages then
			print("[ServerUpdate] STATE GAME")
		end
		self.remainingTime -= dt 
		if self.remainingTime <= 0 then
			self.remainingTime = self.controller.constants.Game.RELOAD_TIME
			self.controller.State:enterGameOver()
		end
	elseif self.controller.currentPhase == self.controller.constants.Phase.GAME_OVER then
		if self.enable_debug_messages then
			print("[ServerUpdate] STATE GAME_OVER")
		end
		if self._iterator == 0 then
			self.remainingTime = self.controller.constants.Game.RELOAD_TIME	
		end	
		self.remainingTime -= dt 
		if self.remainingTime <= 0 then
			self.controller.State:reloadMenu()
		end		
	end	
	
	-- COUNTERS
	if self._iterator < 1000 then
		self._iterator += 1
	end	
end

return setmetatable({}, ServerUpdate)
