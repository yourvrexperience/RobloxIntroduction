local ScreenGameOver = {}
ScreenGameOver.__index = ScreenGameOver

function ScreenGameOver:init(screens, gameGui)
    self.screens = screens

    local gameOverHUD = gameGui:WaitForChild("GameOverHUD")
    self.reloadingGame = gameOverHUD:WaitForChild("ReloadingGame")
end

function ScreenGameOver:setUpTexts()
	-- self.textLoading.Text = self.i18n:t("loading.loading")
end

function ScreenGameOver:showCoundownReload(timeToReload: number) 
	if timeToReload >= 0 then
		self.reloadingGame.Text = self.screens.i18n:t("game_over.reloading") .. tostring(timeToReload) .. "s"
	end
end

return setmetatable({}, ScreenGameOver)