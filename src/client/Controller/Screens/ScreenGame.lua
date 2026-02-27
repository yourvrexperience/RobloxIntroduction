local ScreenGame = {}
ScreenGame.__index = ScreenGame

function ScreenGame:init(screens, gameGui)
    self.screens = screens
    local gameHUD = gameGui:WaitForChild("GameHUD")
    self.gameTime = gameHUD:WaitForChild("Time")
    
    gameHUD.MouseButton1Click:Connect(function()
        if gameHUD.Active then
            gameHUD.Active = false
            gameHUD.AutoButtonColor = false

            self.screens.controller.Events:sendEvent(self.screens.controller.constants.Events.REQUEST_FORCE_END, {
                name = self.screens.controller.localPlayer.Name,
                team = self.screens.controller.localPlayer.Team.Name
            })
            task.wait(0.5)

            gameHUD.Active = true
            gameHUD.AutoButtonColor = true
        end	
    end)

    self.buttonAskForBall = gameGui:WaitForChild("ButtonAskForBall")
    self.buttonAskForBall.MouseButton1Click:Connect(function()
        if self.buttonAskForBall.Active then
            self.buttonAskForBall.Active = false
            self.buttonAskForBall.AutoButtonColor = false
            
            self.screens.controller.Events:sendEvent(self.screens.controller.constants.Events.REQUEST_NEW_BALL, "")
            task.wait(0.5)

            self.buttonAskForBall.Active = true
            self.buttonAskForBall.AutoButtonColor = true
        end
    end)

end

function ScreenGame:updateGameTime(time: number)
	self.gameTime.Text = self.screens.controller.utilities:getFormattedTimeMinutes(time)
end

function ScreenGame:setUpTexts()
	-- self.textGame.Text = self.i18n:t("game.game")
end

return setmetatable({}, ScreenGame)