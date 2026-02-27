local ScreenLoading = {}
ScreenLoading.__index = ScreenLoading

function ScreenLoading:init(screens, loadGui)
    self.screens = screens

    self.textLoading = loadGui:WaitForChild("TextLabel")
end

function ScreenLoading:setUpTexts()
	self.textLoading.Text = self.screens.i18n:t("loading.loading")
end

return setmetatable({}, ScreenLoading)