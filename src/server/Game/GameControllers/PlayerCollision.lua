local Players = game:GetService("Players")

local PlayerCollision = {}
PlayerCollision.__index = PlayerCollision

function PlayerCollision:init(controller)
	self.controller = controller
	self.enable_debug_messages = false
	
	-- Debounce collisions per player-pair
	self._lastPairHit = {} :: { [string]: number }
	self._pairCooldown = 0.25 -- seconds; tune

	-- Hook players
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			self:_hookCharacter(player, char)
		end)
	end)

	-- Hook already-connected players (when play solo / hot reload)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			self:_hookCharacter(p, p.Character)
		end
	end

	if self.enable_debug_messages then
		print("[PlayerCollision] Initialized")
	end
end

function PlayerCollision:resetRound()
	self._lastPairHit = {}
end

function PlayerCollision:_hookCharacter(player: Player, character: Model)
	-- Only listen on one part to avoid spam; HRP is best.
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp or not hrp:IsA("BasePart") then return end

	-- Avoid multiple connections if character reload / re-hook happens
	if hrp:GetAttribute("CollisionHooked") then return end
	hrp:SetAttribute("CollisionHooked", true)

	hrp.Touched:Connect(function(hit)
		self:_onTouched(player, hit)
	end)
end

function PlayerCollision:_onTouched(playerA: Player, hit: BasePart)
	if not hit or not hit:IsA("BasePart") then return end

	local playerB = self.controller.utilities:getPlayerFromHit(hit)
	if not playerB then return end
	if playerB == playerA then return end

	-- Debounce per pair (so we don't trigger 60 times/second while overlapping)
	local key = self.controller.utilities:pairKey(playerA, playerB)
	local now = os.clock()
	local last = self._lastPairHit[key]
	if last and (now - last) < self._pairCooldown then
		return
	end
	self._lastPairHit[key] = now

	-- Gather required info
	local info = self:getCollisionInfo(playerA, playerB)

	if self.enable_debug_messages then
		print(("[PlayerCollision] %s(%s) hit %s(%s)"):format(playerA.Name, info.teamA or "NO_TEAM", playerB.Name, info.teamB or "NO_TEAM"))
	end

	-- Must have teams and be opposite teams 
	if not playerA.Team or not playerB.Team then return end 
	if self.controller.utilities:sameTeam(playerA, playerB) then return end 

	local bm = self.controller.BallManager
	if not bm then return end 

	local carryingA = bm:isCarrying(playerA) 
	local carryingB = bm:isCarrying(playerB)

	-- We only care when exactly one is carrying 
	if carryingA == carryingB then return end 

	local carrier = carryingA and playerA or playerB 
	local tackler = carryingA and playerB or playerA 

	local ball = bm:getCarriedBall(carrier) 
	if not ball then return end 

	-- Force the carrier to throw 
	ball:forceThrowFromPlayer(carrier)
	self.controller.Events:sendTo(carrier, self.controller.constants.Events.BALL_TAKEN) 
	print(("[TACKLE] %s tackled %s -> forced throw"):format(tackler.Name, carrier.Name))
end

function PlayerCollision:getCollisionInfo(playerA: Player, playerB: Player) 
	local bm = self.controller.BallManager 
	local teamA = playerA.Team and playerA.Team.Name or nil 
	local teamB = playerB.Team and playerB.Team.Name or nil 

	local carryingA = bm and bm.isCarrying and bm:isCarrying(playerA) or false 
	local carryingB = bm and bm.isCarrying and bm:isCarrying(playerB) or false 

	return { playerA = playerA, 
			playerB = playerB, 
			teamA = teamA, 
			teamB = teamB, 
			carryingA = carryingA, 
			carryingB = carryingB, 
		} 
end

return setmetatable({}, PlayerCollision)
