local ClientStateChanged = {}
ClientStateChanged.__index = ClientStateChanged

function ClientStateChanged:init(controller)
	self.controller = controller
	self.previousState = nil
	
	self.enable_debug_messages = false
	
	if self.enable_debug_messages then 
		print("[ClientStateChanged:init] Initialized.")
	end	
end

function ClientStateChanged:ChangePhase(newPhase: string, data: any)
	local old = self.controller.currentPhase
	self.controller.currentPhase = newPhase
	
	if self.enable_debug_messages then 
		print("[ClientStateChanged:ChangePhase] Phase ->", newPhase, "Additional Data:", data)
	end

	self:onPhaseChanged(old, newPhase, data)
end

function ClientStateChanged:onPhaseChanged(oldPhase: string, newPhase: string, data: any)
	
	if newPhase ~= oldPhase then
		self.controller.Update:stateChanged()
		
		if newPhase == self.controller.constants.Phase.MENU then
			if self.enable_debug_messages then 
				print("[ClientStateChanged:onPhaseChanged] STATE MENU: show menu, enable start input")
			end
			self.controller.Screens:showForPhase(self.controller.constants.Screen.MENU)			
		elseif newPhase == self.controller.constants.Phase.LOAD then
			if self.enable_debug_messages then 
				print("[ClientStateChanged:onPhaseChanged] STATE LOAD: show loading, disable movement if desired")				
			end			
			self.controller.Screens:showForPhase(self.controller.constants.Screen.LOAD)
			self.controller.Actions:freezeHumanoid()
			self.controller.Audio:play2D(self.controller.constants.Sounds.SOUND_GAME_STARTS)
		elseif newPhase == self.controller.constants.Phase.GAME then
			if self.enable_debug_messages then 
				print("[ClientStateChanged:onPhaseChanged] STATE GAME: show HUD, enable gameplay input")
			end
			if data.time then
				self.controller.Update.remainingTime = data.time
			end
			self.controller.Screens:showForPhase(self.controller.constants.Screen.GAME)
			self.controller.Actions:unfreezeHumanoid()
			self.controller.Screens:updateGameTime(self.controller.constants.Game.GAME_TIME)
		elseif newPhase == self.controller.constants.Phase.GAME_OVER then
			if self.enable_debug_messages then 
				print("[ClientStateChanged:onPhaseChanged] STATE GAME_OVER: show results")
			end
			self.controller.Screens:showForPhase(self.controller.constants.Screen.GAME_OVER)
			self.controller.Audio:play2D(self.controller.constants.Sounds.SOUND_GAME_OVER)
		end	
	end	
end

return setmetatable({}, ClientStateChanged)
