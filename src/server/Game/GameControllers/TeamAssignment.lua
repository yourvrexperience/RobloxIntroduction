-- TeamAssignment.lua
-- Handles team assignment and related logic for the Capture the Flag game.
local Players = game:GetService("Players")

local TeamAssignment = {}
TeamAssignment.__index = TeamAssignment

function TeamAssignment:init(controller)
	self.controller = controller
	self.teamRed = controller.Teams:WaitForChild(self.controller.constants.Team.RED)
	self.teamBlue = controller.Teams:WaitForChild(self.controller.constants.Team.BLUE)
	self._charAddedConn = {}
	self.enable_debug_messages = false
end

function TeamAssignment:assignTeams(playersList: { Player })
	-- Deterministic split; replace with shuffle later if desired
	for i, p in ipairs(playersList) do
		p.Team = (i % 2 == 1) and self.teamRed or self.teamBlue
	end
end

local function removeMarker(character: Model)
	local existing = character:FindFirstChild("TeamMarker")
	if existing then existing:Destroy() end
	local head = character:FindFirstChild("Head")
	if head then
		local motor = head:FindFirstChild("TeamMarkerMotor")
		if motor then motor:Destroy() end
	end
end

function TeamAssignment:createMarker(character: Model, team: Team)
	local head = character:WaitForChild("Head", 5)
	if not head or not head:IsA("BasePart") then return end

	removeMarker(character)	
	local marker = Instance.new("Part")
	marker.Name = "TeamMarker"
	marker.Shape = Enum.PartType.Ball
	marker.Size = self.controller.constants.PlayerMarker.SIZE_MARKER
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.Massless = true
	marker.CastShadow = false
	marker.Material = Enum.Material.Neon
	marker.Color = team.TeamColor.Color
	marker.Parent = character

	local motor = Instance.new("Motor6D")
	motor.Name = "TeamMarkerMotor"
	motor.Part0 = head
	motor.Part1 = marker
	motor.C0 = self.controller.constants.PlayerMarker.HEIGHT_MARKER
	motor.Parent = head

	marker:SetNetworkOwner(nil)
end

function TeamAssignment:setupAllMarkers()
	for _, player in ipairs(Players:GetPlayers()) do
		self:setupPlayerMarker(player)
	end
end

function TeamAssignment:setupPlayerMarker(player: Player)
	if not player.Character then
		player:LoadCharacter()
	end

	local character = player.Character
	if not character then return end
	if not player.Team then return end

	self:createMarker(character, player.Team)
end

function TeamAssignment:clearMarkers()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			removeMarker(character)
		end
	end
end

return setmetatable({}, TeamAssignment)
