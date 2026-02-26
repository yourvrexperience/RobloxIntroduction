local Workspace = game:GetService("Workspace")

local ClientActions = {}
ClientActions.__index = ClientActions

local UserInputService = game:GetService("UserInputService")

function ClientActions:init(controller)
	self.controller = controller	
	
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if controller.currentPhase == controller.constants.Phase.GAME then
				self.controller.Audio:play2D(self.controller.constants.Sounds.SOUND_FX_KICK)
				self.controller.Events:throwBall()
			end
		end
	end)	
end

function ClientActions:freezeHumanoid()
	self.controller.humanoidRootPart.Anchored = true
end

function ClientActions:unfreezeHumanoid()
	self.controller.humanoidRootPart.Anchored = false
end

return setmetatable({}, ClientActions)
