local ServerEvents = {}
ServerEvents.__index = ServerEvents

function ServerEvents:init(controller)
	self.controller = controller
	self.enable_debug_messages = false

	local remotes = self.controller.ReplicatedStorage:WaitForChild("RemoteEvents")
	self.remotePhaseChanged = remotes:WaitForChild("GamePhaseChanged")
	self.clientEvents = remotes:WaitForChild("ClientEvents")
	self.serverEvents = remotes:WaitForChild("ServerEvents")

	-- Bind start request here (only once per server)
	local requestStart = remotes:WaitForChild("RequestStart") -- RemoteFunction
	requestStart.OnServerInvoke = function(player)
		local c = self.controller

		if c.currentPhase ~= c.constants.Phase.MENU then
			return false, "Not in MENU."
		end
		if c.isTransitioning then
			return false, "Already starting."
		end

		c.State:enterLoad()
		return true
	end	

	self.clientEvents.OnServerEvent:Connect(function(player, event, data)
		self:onClientEvent(player, event, data)
	end)
	
	if self.enable_debug_messages then
		print("[ServerEvents:init] Initialized")
	end
end

function ServerEvents:onClientEvent(player: Player, event: string, data: any)
	-- Always validate client input
	if typeof(event) ~= "string" then
		warn("[ServerEvents:onClientEvent] Invalid message type from", player.Name)
		return
	end

	-- Optional: trim / limit length
	if #event > 200 then
		warn("[ServerEvents:onClientEvent] Event too long from", player.Name)
		return
	end

	-- Centralized handling
	if self.enable_debug_messages then
		print(("[ServerEvents:onClientEvent] %s says: %s"):format(player.Name, event))
	end

	-- EVAL EVENT REQUEST_STATE 
	if event == self.controller.constants.Events.REQUEST_STATE then
		self:sendTo(player, self.controller.constants.Events.RESPONSE_STATE, { 
																				state = self.controller.currentPhase,
																				time = self.controller.ServerUpdate.remainingTime			
																				})
		return
	end
	-- EVAL EVENT REQUEST_FORCE_END
	if event == self.controller.constants.Events.REQUEST_FORCE_END then
		if self.enable_debug_messages then
			print(("[ServerEvents:onClientEvent] REQUEST_FORCE_END %s(%s)"):format(data.name, data.team))
		end
		self.controller.State:enterGameOver()
		return
	end
	
	-- Example: broadcast to everyone (including sender)
	local out = ("%s: %s"):format(player.Name, event)
	self:broadcast(out, data)
end

function ServerEvents:broadcast(event: string, data: any)
	self.serverEvents:FireAllClients(event, data)
end

function ServerEvents:sendTo(player: Player, event: string, data: any)
	self.serverEvents:FireClient(player, event, data)
end

function ServerEvents:phaseChange(newPhase: string, data: any)
	self.remotePhaseChanged:FireAllClients(newPhase, data)
end

return setmetatable({}, ServerEvents)
