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

	-- Cache MENU slideshow panel
	do
		local menuGui = self.screens[self.controller.constants.Screen.MENU]
		self.startButton = menuGui:WaitForChild("StartButton")
		self.textPlay = self.startButton:WaitForChild("TextLabel")
		local remotes = self.controller.ReplicatedStorage:WaitForChild("RemoteEvents")
		local requestStart = remotes:WaitForChild("RequestStart")
		
		self.startButton.MouseButton1Click:Connect(function()
			self.startButton.Active = false
			self.startButton.AutoButtonColor = false

			local ok, reason = requestStart:InvokeServer()
			if not ok then
				warn("[Client] Start denied:", reason)

				-- Replace this with your UI message label if you have one
				self.startButton.Text = reason or self.i18n:t("menu.cannot")
				task.wait(1.5)
				self.startButton.Text = self.i18n:t("menu.play")
			end

			self.startButton.Active = true
			self.startButton.AutoButtonColor = true
		end)
	end

	-- Cache LOAD
	do
		local loadGui = self.screens[self.controller.constants.Screen.LOAD]
		self.textLoading = loadGui:WaitForChild("TextLabel")
	end
	
	-- Cache GAME HUD
	do
		local gameGui = self.screens[self.controller.constants.Screen.GAME]
		local gameHUD = gameGui:WaitForChild("GameHUD")
		self.gameTime = gameHUD:WaitForChild("Time")
		self.buttonAskForBall = gameGui:WaitForChild("ButtonAskForBall") 

		self.buttonAskForBall.MouseButton1Click:Connect(function() 
			if self.buttonAskForBall.Active then 
				self.buttonAskForBall.Active = false 
				self.buttonAskForBall.AutoButtonColor = false 
				self.controller.Events:sendEvent(self.controller.constants.Events.REQUEST_NEW_BALL, "")
				task.wait(0.5) 
				self.buttonAskForBall.Active = true 
				self.buttonAskForBall.AutoButtonColor = true
			end 
		end)

		gameHUD.MouseButton1Click:Connect(function()
			if gameHUD.Active then
				gameHUD.Active = false
				gameHUD.AutoButtonColor = false

				self.controller.Events:sendEvent(self.controller.constants.Events.REQUEST_FORCE_END, {
					name = self.controller.localPlayer.Name,
					team = self.controller.localPlayer.Team.Name
				})
				task.wait(0.5)

				gameHUD.Active = true
				gameHUD.AutoButtonColor = true
			end	
		end)

	end

	-- Cache GAME_OVER HUD
	do
		local gameGui = self.screens[self.controller.constants.Screen.GAME_OVER]
		local gameOverHUD = gameGui:WaitForChild("GameOverHUD")
		self.reloadingGame = gameOverHUD:WaitForChild("ReloadingGame")
	end

	-- Start with everything hidden, then show MENU by default
	self:hideAll()
	self:show(self.controller.constants.Screen.MENU)
	self:setUpTexts()
end

function ClientScreens:setUpTexts()
	self.textPlay.Text = self.i18n:t("menu.play")
	self.textLoading.Text = self.i18n:t("loading.loading")
end

function ClientScreens:hideAll()
	for _, gui in pairs(self.screens) do
		gui.Enabled = false
	end
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
	self.gameTime.Text = self.controller.utilities:getFormattedTimeMinutes(time)
end

function ClientScreens:showCoundownReload(timeToReload: number) 
	if timeToReload >= 0 then
		self.reloadingGame.Text = self.i18n:t("game_over.reloading") .. tostring(timeToReload) .. "s"
	end
end

return setmetatable({}, ClientScreens)
