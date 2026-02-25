-- ClientUpdate.lua
-- Handles the main update loop for the client, managing state transitions and timers for the Capture the
local RunService = game:GetService("RunService")

local ClientUpdate = {}
ClientUpdate.__index = ClientUpdate

function ClientUpdate:init(controller)
	self.controller = controller
	self._accumulator = 0
	self._iterator = 0
	self._connection = nil
	self.remainingTime = 0
	
	self.enable_debug_messages = false
	
	self:start()
end

function ClientUpdate:start()
	if self._connection then return end

	self._connection = RunService.Heartbeat:Connect(function(dt)
		self:update(dt)
	end)
end

function ClientUpdate:stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

function ClientUpdate:stateChanged()
	if self._connection then
		self._accumulator = 0
		self._iterator = 0
	end
end

function ClientUpdate:update(dt)
	self._accumulator += dt

	-- SWITCH STATE
	if self.controller.currentPhase == self.controller.constants.Phase.INIT then
		if self._iterator == 0 then
			if self.enable_debug_messages then
				print("[ClientUpdate] STATE INIT+++++++++++++++++++++++++")
			end
			self.controller.Screens:show(self.controller.constants.Screen.INIT)
			self.controller.Events:sendEvent(self.controller.constants.Events.REQUEST_STATE, nil)
		end
	elseif self.controller.currentPhase == self.controller.constants.Phase.MENU then
		if self._iterator == 0 then
			if self.enable_debug_messages then
				print("[ClientUpdate] STATE MENU+++++++++++++++++++++++++")
			end
		end
	elseif self.controller.currentPhase == self.controller.constants.Phase.LOAD then
		if self._iterator == 0 then
			if self.enable_debug_messages then
				print("[ClientUpdate] STATE LOAD+++++++++++++++++++++++++")
			end
			self.remainingTime = self.controller.constants.Game.GAME_TIME
		end
	elseif self.controller.currentPhase == self.controller.constants.Phase.GAME then
		if self._iterator == 0 then
			if self.enable_debug_messages then
				print("[ClientUpdate] STATE GAME+++++++++++++++++++++++++")
			end
		end
	elseif self.controller.currentPhase == self.controller.constants.Phase.GAME_OVER then
		if self._iterator == 0 then
			if self.enable_debug_messages then
				print("[ClientUpdate] STATE GAME_OVER+++++++++++++++++++++++++")
			end
			self.remainingTime = self.controller.constants.Game.RELOAD_TIME
		end
		self.remainingTime -= dt		
		self.controller.Screens:showCoundownReload(self.controller.utilities:round(self.remainingTime))
	end	

	-- COUNTERS
	if self._accumulator >= 1 then
		self._accumulator -= 1
		-- print("[ClientUpdate] 1 second tick | phase =", self.controller.currentPhase)
		if self.controller.currentPhase == self.controller.constants.Phase.GAME then
			self.remainingTime -= 1
			self.controller.Screens:updateGameTime(self.remainingTime)
		end		
	end
	if self._iterator < 1000 then
		self._iterator += 1
		-- print("[ClientUpdate] iterator =", self._iterator)
	end	
end

return setmetatable({}, ClientUpdate)
