local Ball = {}
Ball.__index = Ball

function Ball:init(controller)
	self.controller = controller

	-- Where the live match objects go
	self.matchFolder = workspace:FindFirstChild("Match") or Instance.new("Folder")
	self.matchFolder.Name = "Match"
	self.matchFolder.Parent = workspace

	self.ball = nil
	self._dropToken = 0
end

function Ball:destroy()
	if self.ball then
		self.ball:Destroy()
		self.ball = nil
	end
end

-- Create from template in ServerStorage if you want (recommended)
function Ball:spawnBall(spawnCFrame: CFrame)
	-- Destroy old ball
	if self.ball then
		self.ball:Destroy()
		self.ball = nil
	end

	local ballTemplate = self.controller.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("SoccerBall")
	local ballModel = ballTemplate:Clone()
	ballModel.Name = "Ball"

	if not ballModel.PrimaryPart then
		error("SoccerBall model has no PrimaryPart set. Set PrimaryPart in Studio.")
	end
	
	-- Parent first, then move (either order works; this is safe)
	ballModel.Parent = self.matchFolder
	ballModel:PivotTo(spawnCFrame)
	
	-- Use the PrimaryPart for physics + touch detection
	local primary = ballModel.PrimaryPart
	primary.Anchored = false
	primary.CanCollide = true
	primary.Massless = false
	primary.AssemblyAngularVelocity = Vector3.zero
	primary.AssemblyLinearVelocity = Vector3.zero

	-- Optional: tune physics feel (apply to primary; optionally to all parts)
	primary.CustomPhysicalProperties = self.controller.constants.Ball.PHYSICAL_PROPERTIES

	-- IMPORTANT: choose ownership model (server-owned)
	primary:SetNetworkOwner(nil)

	-- Attachment on the primary part
	local ballAttachment = primary:FindFirstChild("BallAttachment")
	if not ballAttachment then
		ballAttachment = Instance.new("Attachment")
		ballAttachment.Name = "BallAttachment"
		ballAttachment.Parent = primary
	end

	primary:SetAttribute("CarrierUserId", 0) -- 0 = none
	primary:SetAttribute("HasBeenReleased", 0) -- 0 = none

	-- LISTEN TOUCH EVENT TO CARRY BALL
	primary.Touched:Connect(function(hit)
		if self:isCarried() then return end

		local player = self.controller.utilities:getPlayerFromHit(hit)
		if not player then return end

		-- prevent picking up a second ball
		if self.manager and self.manager:isCarrying(player) then
			return
		end

		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- distance check against the primary part
		if (hrp.Position - primary.Position).Magnitude > 5 then return end

		self:pickup(player)
	end)
	
	-- Store both for later: model + primary
	self.ball = primary
	
	return primary
end


function Ball:isCarried()
	return self.ball and (self.ball:GetAttribute("CarrierUserId") or 0) ~= 0
end

function Ball:getCarrier(): Player?
	if not self.ball then return nil end
	local id = self.ball:GetAttribute("CarrierUserId") or 0
	if id == 0 then return nil end
	for _, p in ipairs(self.controller.Players:GetPlayers()) do
		if p.UserId == id then return p end
	end
	return nil
end

function Ball:checkHasBeenReleased()
	if not self.ball then return false end
	local released = self.ball:GetAttribute("HasBeenReleased") or 0
	return released == 1
end

function Ball:pickup(player: Player)
	local ball = self.ball
	if not ball then return end
	if self:isCarried() then return end
	if not player.Character then return end

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if self.manager then
		self.manager:_setCarrier(player, self.ballId)
	end
	
	-- Invalidate pending drops
	self._dropToken += 1
	
	-- Mark carrier
	ball:SetAttribute("CarrierUserId", player.UserId)
	ball:SetAttribute("HasBeenReleased", 0)
	
	-- print("[Ball:pickup-0] the ball picked up by", player.UserId)

	-- Disable physics while carried
	ball.Anchored = true
	ball.CanCollide = false
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero

	-- Position in front of player (relative to HRP)
	-- Tune offset to your liking:
	local offset = self.controller.constants.Ball.CARRY_OFFSET
	ball.CFrame = hrp.CFrame * offset
end

function Ball:drop(player: Player, delaySeconds: number?)
	local ball = self.ball
	if not ball then return end
	if not self:isCarried() then return end

	delaySeconds = delaySeconds or 2
	
	ball:SetAttribute("HasBeenReleased", 1)

	if self.manager then
		self.manager:_setCarrier(player, nil)
	end

	-- Increment drop token
	self._dropToken += 1
	local token = self._dropToken

	-- Immediately release physics
	ball.Anchored = false
	ball.CanCollide = true
	ball:SetNetworkOwner(nil)

	-- Delay clearing carrier safely
	task.delay(delaySeconds, function()
		-- Only clear if no newer pickup/drop happened
		if self._dropToken == token then
			ball:SetAttribute("CarrierUserId", 0)
		end
	end)
end

function Ball:throw(player: Player, forwardSpeed: number, sideSpeed: number, upwardSpeed: number)
	local ball = self.ball
	if not ball then return end

	local carrier = self:getCarrier()
	if not carrier or not carrier.Character then
		return
	end

	local hrp = carrier.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Release first
	self:drop(player)
	
	-- Give it a launch velocity
	local forward = hrp.CFrame.LookVector
	local right = hrp.CFrame.RightVector
	local up = Vector3.new(0, 1, 0)

	local v = forward * forwardSpeed + right * sideSpeed + up * upwardSpeed

	ball.AssemblyLinearVelocity = v
end

function Ball:ThrowRequest(player: Player)
	-- Is there a ball?
	if not self.ball then return end

	-- Is the player the carrier?
	local carrier = self:getCarrier()
	if carrier ~= player then
		return -- ignore invalid request
	end
	
	-- Throw parameters (tune for gameplay)
	local forwardSpeed = self.controller.constants.Ball.FORWARD_SPEED
	local upwardSpeed = self.controller.constants.Ball.UPWARD_SPEED

	self:throw(player, forwardSpeed, 0, upwardSpeed)
end

function Ball:forceThrowFromPlayer(player: Player)
	local carrier = self:getCarrier()
	if carrier ~= player then return end

	local forwardSpeed = self.controller.constants.Ball.FORWARD_SPEED
	local upwardSpeed = self.controller.constants.Ball.UPWARD_SPEED

	local randomNumber = math.random(0, 100)
	if randomNumber < 50 then
		forwardSpeed = -self.controller.constants.Ball.FORWARD_SPEED
	end
	
	-- Use your existing throw()
	self:throw(player, 0, forwardSpeed, upwardSpeed)
end

function Ball:reset(spawnCFrame: CFrame)
	if not self.ball then
		return self:spawnBall(spawnCFrame)
	end

	local ball = self.ball
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero
	ball.CFrame = spawnCFrame

	-- Reset ownership to server at kickoff, then you can hand off dynamically later
	ball:SetNetworkOwner(nil)
end

function Ball:update(dt: number)
	if self:isCarried() then
		local carrier = self:getCarrier()
		if self.ball and carrier and carrier.Character then
			local hasBeenReleased = self:checkHasBeenReleased()
			if hasBeenReleased == false then
				local hrp = carrier.Character:FindFirstChild("HumanoidRootPart")
				if hrp then					
					local offset = self.controller.constants.Ball.CARRY_OFFSET
					self.ball.CFrame = hrp.CFrame * offset
				end
			end
		end
	end
end

return Ball