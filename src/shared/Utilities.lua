local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Utilities = {}
Utilities.__index = Utilities

function Utilities:getFormattedTimeMinutes(time: number): string
	local totalSeconds = math.floor(time)

	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60

	return string.format("%02d:%02d", minutes, seconds)
end

function Utilities:getPlayerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then return nil end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	return Players:GetPlayerFromCharacter(character)
end

function Utilities:round(number)
  return number - (number % 1)
end

-- Stable unordered key for pair debounce
function Utilities:pairKey(a: Player, b: Player): string
	local ida, idb = a.UserId, b.UserId
	if ida < idb then
		return ("%d:%d"):format(ida, idb)
	else
		return ("%d:%d"):format(idb, ida)
	end
end

function Utilities:sameTeam(a: Player, b: Player): boolean
	return a.Team ~= nil and a.Team == b.Team
end

function Utilities:tweenProps(instances, tweenInfo, props)
	for _, inst in ipairs(instances) do
		TweenService:Create(inst, tweenInfo, props):Play()
	end
end

return Utilities
