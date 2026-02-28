local ClientEvents = {}
ClientEvents.__index = ClientEvents

function ClientEvents:init(controller)
	self.controller = controller
	self.enable_debug_messages = false
	
	self.remotes = self.controller.ReplicatedStorage:WaitForChild("RemoteEvents")
	self.phaseChanged = self.remotes:WaitForChild("GamePhaseChanged")
	self.serverEvents = self.remotes:WaitForChild("ServerEvents")
	self.clientEvents = self.remotes:WaitForChild("ClientEvents")
	self.throwBallRemote = self.remotes:WaitForChild("ThrowBall") 

	self.serverEvents.OnClientEvent:Connect(function(text, data)
		self:onListenEvent(text, data)
	end)

	self.phaseChanged.OnClientEvent:Connect(function(newPhase, data)
		self:onPhaseChanged(newPhase, data)
	end)
end

function ClientEvents:onListenEvent(event: string, data: any)
	if self.enable_debug_messages then 
		print("[ListenMessage] EVENT=", event, " DATA=", data)
	end

	-- EVAL RESPONSE_STATE
	if event == self.controller.constants.Events.RESPONSE_STATE then
		if self.enable_debug_messages then 
			print(("[ClientEvents:onListenEvent] state %s, time (%s)"):format(data.state, tostring(data.time)))		
		end
		self:onPhaseChanged(data.state, data)
	end
	-- EVAL PLAYER_HITS_BALL 
	if event == self.controller.constants.Events.PLAYER_HITS_BALL then
		print(("[ClientEvents:onListenEvent] PLAYER_HITS_BALL %s hit %s"):format(data.playerName, data.ballName)) 
		if data.playerName == self.controller.localPlayer.Name then
			self.controller.Audio:play2D(self.controller.constants.Sounds.SOUND_FX_KICK) 
		end 
	end	
	-- EVAL BALL_TAKEN 
	if event == self.controller.constants.Events.BALL_TAKEN then
		self.controller.Audio:play2D(self.controller.constants.Sounds.SOUND_FX_OUCH) 
	end	
	-- EVAL GOAL_SCORED
	if event == self.controller.constants.Events.GOAL_SCORED then
		-- print("GOAL SCORED FOR TEAM = ", tostring(data.team)) 
		self.controller.scoreRed = data.red 
		self.controller.scoreBlue = data.blue
		self.controller.Audio:play2D(self.controller.constants.Sounds.SOUND_PLAYER_SCORE)
		self.controller.Screens.ScreenGame:updateScore(self.controller.scoreRed, self.controller.scoreBlue) 
		if self.controller.localPlayer.Team.Name == data.team then
			self.controller.Screens:showGoalScored()
		end
	end	
	-- EVAL SPAWN_POSITION 
	if event == self.controller.constants.Events.SPAWN_POSITION then 
		self.controller.Actions:teleportIntoFieldSpawn(tonumber(data))
	end	
end

function ClientEvents:onPhaseChanged(newPhase: string, data: any)
	self.controller.StateChanged:ChangePhase(newPhase, data)
end

function ClientEvents:sendEvent(text: string, data: any)
	self.clientEvents:FireServer(text, data)
end

function ClientEvents:throwBall() 
	self.throwBallRemote:FireServer() 
end

return setmetatable({}, ClientEvents)
