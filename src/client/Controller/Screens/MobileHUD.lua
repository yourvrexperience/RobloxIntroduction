-- ScreenMenu.lua
local MobileHUD = {}
MobileHUD.__index = MobileHUD

function MobileHUD:init(screens, mobileGui)
    self.screens = screens

    self.throwButton = mobileGui:WaitForChild("ButtonThrow")
    self.textThrow = self.throwButton:WaitForChild("Title")
    self:hideButtonThrow()
    
    self.throwButton.MouseButton1Click:Connect(function()
        self.screens.controller.Events:throwBall()
        self:hideButtonThrow()
    end)

    self:setUpTexts()
end

function MobileHUD:showButtonThrow()
	self.throwButton.Visible = true
end

function MobileHUD:hideButtonThrow()
	self.throwButton.Visible = false
end

function MobileHUD:setUpTexts()
	self.textThrow.Text = self.screens.i18n:t("game.throw")
end

return setmetatable({}, MobileHUD)