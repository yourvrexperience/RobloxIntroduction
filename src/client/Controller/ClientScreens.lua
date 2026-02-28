local ClientScreens = {}
ClientScreens.__index = ClientScreens

function ClientScreens:init(controller)
	self.controller = controller
	self.playerGui = self.controller.Players.LocalPlayer:WaitForChild("PlayerGui")	
	self.enable_debug_messages = false
	
	local LanguageManager = require(self.controller.ReplicatedStorage.Shared.LanguageManager)
	local LanguageData = require(self.controller.ReplicatedStorage.Shared.LanguageData)

	self.i18n = LanguageManager.new()
		:loadFromJsonString(LanguageData)
		:setFallbackLanguage("en")
		:setLanguage("en")

	-- Cache screens (these must exist under PlayerGui at runtime)
	self.screens = {
		[self.controller.constants.Screen.INIT] = self.playerGui:WaitForChild("ScreenInit"),
		[self.controller.constants.Screen.MENU] = self.playerGui:WaitForChild("ScreenMenu"),
		[self.controller.constants.Screen.LOAD] = self.playerGui:WaitForChild("ScreenLoad"),
		[self.controller.constants.Screen.GAME] = self.playerGui:WaitForChild("ScreenGame"),
		[self.controller.constants.Screen.GAME_OVER] = self.playerGui:WaitForChild("ScreenGameOver"),
	}

	self.goalScoredScreen = self.playerGui:WaitForChild("ScreenGoalScored") 

	-- Cache MENU
	self.ScreenMenu = require(script.Parent.Screens.ScreenMenu)
	self.ScreenMenu:init(self, self.screens[self.controller.constants.Screen.MENU])		

	-- Cache LOAD
	self.ScreenLoading = require(script.Parent.Screens.ScreenLoading)
	self.ScreenLoading:init(self, self.screens[self.controller.constants.Screen.LOAD])		

	-- Cache GAME HUD
	self.ScreenGame = require(script.Parent.Screens.ScreenGame)
	self.ScreenGame:init(self, self.screens[self.controller.constants.Screen.GAME])		

	-- Cache GAME_OVER HUD
	self.ScreenGameOver = require(script.Parent.Screens.ScreenGameOver)
	self.ScreenGameOver:init(self, self.screens[self.controller.constants.Screen.GAME_OVER])		

	self.Screens = {
		self.ScreenMenu,
		self.ScreenLoading,
		self.ScreenGame,
		self.ScreenGameOver
	}
	
	-- Start with everything hidden, then show MENU by default
	self:hideAll()
	self:show(self.controller.constants.Screen.MENU)
	self:setUpTexts()
end

function ClientScreens:setUpTexts()
	for _, screen in ipairs(self.Screens) do
		if screen.setUpTexts then
			screen:setUpTexts()
		end
	end
end

function ClientScreens:hideAll()
	for _, gui in pairs(self.screens) do
		gui.Enabled = false
	end

	self.goalScoredScreen.Enabled = false 
end

-- key can be "MENU"/"LOAD"/"GAME"/"GAME_OVER"
function ClientScreens:show(key: string)
	local gui = self.screens[key]
	if not gui then
		warn("[ClientScreens] Unknown screen key:", key)
		return
	end

	self:hideAll()
	gui.Enabled = true
end

function ClientScreens:showForPhase(phase: string)
	self:show(phase)
end

function ClientScreens:updateGameTime(time: number)
	self.ScreenGame:updateGameTime(time)
end

function ClientScreens:showCoundownReload(timeToReload: number) 
	self.ScreenGameOver:showCoundownReload(timeToReload)
end

function ClientScreens:showGoalScored() 
	self:hideAll() 
	self.goalScoredScreen.Enabled = true 

	-- Hide after a short delay 
	task.delay(3, function() 
		self.goalScoredScreen.Enabled = false 
		self:show(self.controller.currentPhase) 
	end) 
end

return setmetatable({}, ClientScreens)