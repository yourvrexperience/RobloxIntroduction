local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local ClientAudio = {}
ClientAudio.__index = ClientAudio

function ClientAudio:init(controller)
	self.controller = controller
	self.audioFolder = ReplicatedStorage:WaitForChild("Audio")

	-- A place to play 2D UI sounds
	self.channel = SoundService:FindFirstChild("ClientAudio")
	if not self.channel then
		self.channel = Instance.new("Folder")
		self.channel.Name = "ClientAudio"
		self.channel.Parent = SoundService
	end
end

function ClientAudio:play2D(name: string)
	local template = self.audioFolder:FindFirstChild(name)
	if not template or not template:IsA("Sound") then
		warn("[ClientAudio] Missing sound:", name)
		return
	end

	local sound = template:Clone()
	sound.Parent = self.channel
	sound:Play()

	-- cleanup when finished
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

return setmetatable({}, ClientAudio)
