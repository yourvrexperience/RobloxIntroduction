-- BallSpawner.lua
-- Server-side subsystem that spawns SoccerBall instances at random positions.

local BallSpawner = {}
BallSpawner.__index = BallSpawner

function BallSpawner.new()
	local self = setmetatable({}, BallSpawner)

	self.controller = nil
	self.Rng = Random.new()

	self.asset = nil
	self.folder = nil

	-- Optional: a Part in Workspace used as the random spawn region
	self.spawnRegionPartName = "BallSpawnRegion"

	return self
end

function BallSpawner:init(controller)
	self.controller = controller

	-- Grab asset
	local assetsFolder = controller.ReplicatedStorage:WaitForChild("Assets")
	self.asset = assetsFolder:WaitForChild("SoccerBall")

	-- Create / reuse a folder in Workspace to keep things tidy
	self.folder = workspace:FindFirstChild("SpawnedBalls")
	if not self.folder then
		self.folder = Instance.new("Folder")
		self.folder.Name = "SpawnedBalls"
		self.folder.Parent = workspace
	end
end

-- Utility: returns a random point inside a Part's bounding box (ignores rotation for simplicity)
local function randomPointInPartBounds(rng: Random, part: BasePart): Vector3
	local size = part.Size
	local half = size * 0.5

	local x = rng:NextNumber(-half.X, half.X)
	local y = rng:NextNumber(-half.Y, half.Y)
	local z = rng:NextNumber(-half.Z, half.Z)

	-- Note: if the part is rotated, this is still "box around center" not oriented box.
	-- Usually fine if you keep the region unrotated.
	return part.Position + Vector3.new(x, y, z)
end

-- Spawns `count` balls. If Workspace has a Part named "BallSpawnRegion", uses it.
-- Otherwise uses fallbackCenter/fallbackSize if provided.
function BallSpawner:spawn(count: number, fallbackCenter: Vector3?, fallbackSize: Vector3?)
	assert(self.asset, "BallSpawner not initialized (missing asset)")
	assert(self.folder, "BallSpawner not initialized (missing folder)")

	local regionPart = workspace:FindFirstChild(self.spawnRegionPartName)
	local usePart = regionPart and regionPart:IsA("BasePart")

	local center = fallbackCenter or Vector3.new(0, 10, 0)
	local size = fallbackSize or Vector3.new(80, 1, 80)

	for i = 1, count do
		local ball = self.asset:Clone()
		self.controller.utilities:setPhysicsRecursive(ball)
		ball.Name = ("SoccerBall_%02d"):format(i)

		-- pick random position
		local pos: Vector3
		if usePart then
			pos = randomPointInPartBounds(self.Rng, regionPart :: BasePart)
		else
			local half = size * 0.5
			local x = self.Rng:NextNumber(-half.X, half.X)
			local y = self.Rng:NextNumber(-half.Y, half.Y)
			local z = self.Rng:NextNumber(-half.Z, half.Z)
			pos = center + Vector3.new(x, y, z)
		end

		-- place ball slightly above ground to avoid clipping
		local bumpY = 2
		if ball:IsA("BasePart") then
			ball.CFrame = CFrame.new(pos + Vector3.new(0, bumpY, 0))
		else
			-- If SoccerBall is a Model
			local primary = ball.PrimaryPart or ball:FindFirstChildWhichIsA("BasePart")
			if primary then
				ball:PivotTo(CFrame.new(pos + Vector3.new(0, bumpY, 0)))
			end
		end

		ball.Parent = self.folder
		self:_attachKickBehavior(ball)
	end
end

function BallSpawner:clear()
	if not self.folder then return end
	for _, child in ipairs(self.folder:GetChildren()) do
		child:Destroy()
	end
end

-- Convenience: clear then respawn
function BallSpawner:respawn(count: number, fallbackCenter: Vector3?, fallbackSize: Vector3?)
	self:clear()
	self:spawn(count, fallbackCenter, fallbackSize)
end


function BallSpawner:_attachKickBehavior(ballInstance: Instance)
	local ballPart = self.controller.utilities:getBasePart(ballInstance)
	if not ballPart then
		warn("[BallSpawner] SoccerBall has no BasePart to apply impulses to.")
		return
	end

	local cooldown = {} -- Per-ball per-player cooldown (prevents impulse spam)
	local COOLDOWN_SEC = 0.15

	-- Optional: make sure server owns physics for consistency
	ballPart:SetNetworkOwner(nil)

	ballPart.Touched:Connect(function(hitPart)
		if not hitPart or not hitPart:IsA("BasePart") then return end

		local player = self.controller.utilities:getPlayerFromHit(hitPart)
		if not player then return end

		-- Cooldown per player
		local now = os.clock()
		local last = cooldown[player.UserId]
		if last and (now - last) < COOLDOWN_SEC then
			return
		end
		cooldown[player.UserId] = now

		-- Get a direction to push:
		-- Prefer HRP velocity direction, else from player->ball vector.
		local hrp = player.character:FindFirstChild("HumanoidRootPart")
		local dir: Vector3
		if hrp and hrp.AssemblyLinearVelocity.Magnitude > 0.5 then
			dir = hrp.AssemblyLinearVelocity.Unit
		else
			dir = (ballPart.Position - hitPart.Position)
			if dir.Magnitude < 0.01 then
				dir = ballPart.CFrame.LookVector
			else
				dir = dir.Unit
			end
		end

		-- Strength tuning:
		-- ApplyImpulse expects Newton-seconds; scale by mass for consistent feel.
		local mass = ballPart.AssemblyMass
		local kickStrength = 45 -- tweak this
		local upLift = 0.15     -- 0..1 small lift

		local impulse = (dir + Vector3.new(0, upLift, 0)).Unit * (kickStrength * mass)
		ballPart:ApplyImpulse(impulse)

		-- Optional: add spin
		local spinStrength = 6
		local spinAxis = Vector3.new(0, 1, 0)
		ballPart:ApplyAngularImpulse(spinAxis * (spinStrength * mass))

		self.controller.Events:broadcast(self.controller.constants.Events.PLAYER_HITS_BALL, 
		{ 
			playerName = player.Name,
			ballName = ballInstance.Name, 
		})		
	end)
end

return BallSpawner.new()