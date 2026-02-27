-- ScreenMenu.lua
local ScreenMenu = {}
ScreenMenu.__index = ScreenMenu

function ScreenMenu:init(screens, menuGui)
    self.screens = screens

    self.startButton = menuGui:WaitForChild("StartButton")
    self.textPlay = self.startButton:WaitForChild("TextLabel")
    local remotes = self.screens.controller.ReplicatedStorage:WaitForChild("RemoteEvents")
    local requestStart = remotes:WaitForChild("RequestStart")
    
    self.startButton.MouseButton1Click:Connect(function()
        self.startButton.Active = false
        self.startButton.AutoButtonColor = false

        local ok, reason = requestStart:InvokeServer()
        if not ok then
            warn("[Client] Start denied:", reason)

            -- Replace this with your UI message label if you have one
            self.startButton.Text = reason or self.screens.i18n:t("menu.cannot")
            task.wait(1.5)
            self.startButton.Text = self.screens.i18n:t("menu.play")
        end

        self.startButton.Active = true
        self.startButton.AutoButtonColor = true
    end)
end

function ScreenMenu:setUpTexts()
	self.textPlay.Text = self.screens.i18n:t("menu.play")
end

return setmetatable({}, ScreenMenu)