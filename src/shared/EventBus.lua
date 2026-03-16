-- Firing an event (e.g. when a ball hits a balloon)
-- self.controller.eventBus:fire("BalloonPopped", balloonId, balloonType)

-- Firing with no arguments (e.g. round ends)
-- self.controller.eventBus:fire("RoundEnded")

-- Listening to an event
-- self.controller.eventBus:on("BalloonPopped", function(balloonId, balloonType)
-- 	print("Balloon popped:", balloonId, balloonType)
-- 	fxManager:SpawnEffect(confettiType, position)
-- end)

-- Listen only once
-- self.controller.eventBus:once("RoundEnded", function()
-- 	clientActions:cleanup()
-- end)

-- Store connection to disconnect later
-- local conn = self.controller.eventBus:on("BalloonPopped", function(balloonId)
	-- handle it
-- end)

-- Disconnect when no longer needed
-- conn:Disconnect()

-- EventBus.lua
local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
	local self = setmetatable({}, EventBus)
	self._listeners = {}
	return self
end

-- Subscribe to an event by name, returns a connection object to disconnect later
function EventBus:on(eventName: string, callback: (...any) -> ())
	if not self._listeners[eventName] then
		self._listeners[eventName] = {}
	end

	local connection = {
		eventName  = eventName,
		callback   = callback,
		connected  = true,
		_eventBus  = self,
	}

	-- Disconnect function on the connection object
	function connection:Disconnect()
		if not self.connected then return end
		self.connected = false
		local listeners = self._eventBus._listeners[self.eventName]
		if listeners then
			for i, listener in ipairs(listeners) do
				if listener == self then
					table.remove(listeners, i)
					return
				end
			end
		end
	end

	table.insert(self._listeners[eventName], connection)
	return connection
end

-- Subscribe to an event only once — auto disconnects after first fire
function EventBus:once(eventName: string, callback: (...any) -> ())
	local connection
	connection = self:on(eventName, function(...)
		connection:Disconnect()
		callback(...)
	end)
	return connection
end

-- Fire an event by name, passing any number of arguments to listeners
function EventBus:fire(eventName: string, ...: any)
	local listeners = self._listeners[eventName]
	if not listeners or #listeners == 0 then return end

	-- Iterate over a copy in case a listener disconnects during fire
	for _, connection in ipairs(table.clone(listeners)) do
		if connection.connected then
			connection.callback(...)
		end
	end
end

-- Remove all listeners for a specific event
function EventBus:clearEvent(eventName: string)
	if self._listeners[eventName] then
		self._listeners[eventName] = {}
	end
end

-- Remove all listeners for all events
function EventBus:clearAll()
	if self._listeners then
		self._listeners = {}
	end
end

return EventBus