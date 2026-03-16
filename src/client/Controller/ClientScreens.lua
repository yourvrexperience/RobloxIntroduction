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

	-- Cache MOBILE HUD
	self.guiMobileHUD = self.playerGui:WaitForChild("MobileGui") 
	self.MobileHud = require(script.Parent.Screens.MobileHUD)	
	self.MobileHud:init(self, self.guiMobileHUD)		

	self.Screens = {
		self.ScreenMenu,
		self.ScreenLoading,
		self.ScreenGame,
		self.ScreenGameOver,
		self.MobileHud
	}
	
	self.ScalesUIs = {
		[1] = self:RegisterScaleUI(self.screens[self.controller.constants.Screen.MENU]),
		[2] = self:RegisterScaleUI(self.screens[self.controller.constants.Screen.LOAD]),
		[3] = self:RegisterScaleUI(self.screens[self.controller.constants.Screen.GAME]),
		[4] = self:RegisterScaleUI(self.screens[self.controller.constants.Screen.GAME_OVER]),
		[5] = self:RegisterScaleUI(self.goalScoredScreen),
		[6] = self:RegisterScaleUI(self.guiMobileHUD)		
	}

	-- Start with everything hidden, then show MENU by default
	self:hideAll()
	self:show(self.controller.constants.Screen.MENU)
	self:setUpTexts()

	-- Update on resize	
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		self:updateScale()
	end)
	self:updateScale()	
end

function ClientScreens:RegisterScaleUI(screenGUI)
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1.0  -- adjust as needed
	uiScale.Parent = screenGUI
	return uiScale
end

function ClientScreens:updateScale()
    local screenSize = workspace.CurrentCamera.ViewportSize
    local baseResolution = 720
    for _, uiScale in pairs(self.ScalesUIs) do
        if uiScale then
            uiScale.Scale = screenSize.Y / baseResolution
        end
    end
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
	self.guiMobileHUD.Enabled = false
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

function ClientScreens:showMobileGUI()
	if self.controller.isMobile then
		self.guiMobileHUD.Enabled = true
	end
end

function ClientScreens:showMobileButton()
	if self.controller.isMobile then
		self.MobileHud:showButtonThrow()
	end
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