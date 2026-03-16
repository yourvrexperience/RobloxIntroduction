local RunService    = game:GetService("RunService")
local VRService     = game:GetService("VRService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local constants = require(ReplicatedStorage.Shared.Constants)


local RAY_LENGTH = 20
local CURSOR_SIZE       = Vector3.new(0.01, 0.01, 0.01)
local CURSOR_COLOR      = Color3.fromRGB(255, 255, 255)

-- ---------------------------------------------------------------------------
-- Public interface
-- ---------------------------------------------------------------------------
local VRController = {}
VRController.isVR = false        -- read from anywhere; true once VR confirmed

-- Internal state
local camera    = workspace.CurrentCamera
local _running  = false
local _conn     = nil            -- RunService connection handle

-- ---------------------------------------------------------------------------
-- Event names published on the EventBus
-- (keep in sync with VREvents.lua so strings are never magic literals)
-- ---------------------------------------------------------------------------
local E = {
    VR_ENABLED          = "VR_Enabled",          -- fired once on startup if VR detected
    VR_DISABLED         = "VR_Disabled",          -- fired if headset disconnects at runtime
    VR_TRACKING_UPDATE  = "VR_TrackingUpdate",    -- fired every frame with TrackingData
    VR_TRIGGER_LEFT     = "VR_TriggerLeft",       -- left trigger pressed / released
    VR_TRIGGER_RIGHT    = "VR_TriggerRight",      -- right trigger pressed / released
    VR_GRIP_LEFT        = "VR_GripLeft",
    VR_GRIP_RIGHT       = "VR_GripRight",
    VR_THUMBSTICK_LEFT  = "VR_ThumbstickLeft",
    VR_THUMBSTICK_RIGHT = "VR_ThumbstickRight"
}
VRController.Events = E  -- expose so other modules can subscribe without magic strings

-- ---------------------------------------------------------------------------
-- TrackingData type (what is published each frame on VR_TRACKING_UPDATE)
-- ---------------------------------------------------------------------------
-- {
--   headCFrame  : CFrame   -- world-space head pose
--   leftCFrame  : CFrame   -- world-space left hand pose
--   rightCFrame : CFrame   -- world-space right hand pose
--   headLocal   : CFrame   -- camera-relative head pose (raw from VRService)
--   leftLocal   : CFrame   -- camera-relative left hand pose
--   rightLocal  : CFrame   -- camera-relative right hand pose
-- }

-- ---------------------------------------------------------------------------
-- Private helpers
-- ---------------------------------------------------------------------------

local function _toWorld(localCFrame)
    -- All VRService CFrames are camera-relative → multiply by current camera CFrame
    return camera.CFrame * localCFrame
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Call once from the client initialisation script.
function VRController:Init(eventBus)
    if _running then return end
    _running = true

    self.eventBus = eventBus
    self._buttonState = {}
    self._isRightHanded = true
    self.ballTypeSelected = nil

    VRController.isVR = VRService.VREnabled
    -- print("VRController.isVR=",VRController.isVR)

    if VRController.isVR then
        self.eventBus:fire(E.VR_ENABLED, {})
        self:_startTrackingLoop()
    end

    -- React if the headset connects / disconnects at runtime
    VRService:GetPropertyChangedSignal("VREnabled"):Connect(function()
        VRController.isVR = VRService.VREnabled
        if VRController.isVR then
            self.eventBus:fire(E.VR_ENABLED, {})
            self:_startTrackingLoop()
        else
            self.eventBus:fire(E.VR_DISABLED, {})
            self:_stopTrackingLoop()
        end
    end)

    self.eventBus:on(VRController.Events.VR_TRIGGER_LEFT, function(pressed)
        if pressed then
            self._isRightHanded = false
        end
    end)

    self.eventBus:on(VRController.Events.VR_TRIGGER_RIGHT, function(pressed)
        if pressed then
            self._isRightHanded = true
        end
    end)    

    self.cursor = self:_buildCursor()
end

function VRController:_startTrackingLoop()    
    if _conn then return end  -- already running
    _conn = RunService.RenderStepped:Connect(function()
        local data = self:_readTracking()
        self.eventBus:fire(E.VR_TRACKING_UPDATE, data)
        self:_pollButtons()
        self:_pollThumbsticks()
    end)
end

function VRController:_stopTrackingLoop()
    if _conn then
        _conn:Disconnect()
        _conn = nil
    end
end

function VRController:GetTracking()
    if not VRController.isVR then return nil end
    return self:_readTracking()
end

function VRController:VRDirection()
    local tracking = self:GetTracking()
    if self._isRightHanded then
        return tracking and tracking.rightCFrame.LookVector or workspace.CurrentCamera.CFrame.LookVector
    else
        return tracking and tracking.leftCFrame.LookVector or workspace.CurrentCamera.CFrame.LookVector
    end
end

function VRController:_checkButton(gamepadKey, eventName)
    local pressed = UserInputService:IsGamepadButtonDown(
        Enum.UserInputType.Gamepad1, gamepadKey
    )
    local wasPressed = self._buttonState[gamepadKey]

    if pressed and not wasPressed then
        self.eventBus:fire(eventName, { pressed = true })
    elseif not pressed and wasPressed then
        self.eventBus:fire(eventName, { pressed = false })
    end

    self._buttonState[gamepadKey] = pressed
end

function VRController:_pollButtons()
    -- Trigger buttons
    self:_checkButton(Enum.KeyCode.ButtonL2, E.VR_TRIGGER_LEFT)
    self:_checkButton(Enum.KeyCode.ButtonR2, E.VR_TRIGGER_RIGHT)
    -- Grip buttons (side squeeze on most controllers)
    self:_checkButton(Enum.KeyCode.ButtonL1, E.VR_GRIP_LEFT)
    self:_checkButton(Enum.KeyCode.ButtonR1, E.VR_GRIP_RIGHT)
end

function VRController:_readTracking()
    local headLocal  = VRService:GetUserCFrame(Enum.UserCFrame.Head)
    local leftLocal  = VRService:GetUserCFrame(Enum.UserCFrame.LeftHand)
    local rightLocal = VRService:GetUserCFrame(Enum.UserCFrame.RightHand)

    return {
        isRighHand  = self._isRightHanded,
        headCFrame  = _toWorld(headLocal),
        leftCFrame  = _toWorld(leftLocal),
        rightCFrame = _toWorld(rightLocal),
        headLocal   = headLocal,
        leftLocal   = leftLocal,
        rightLocal  = rightLocal,
    }
end

function VRController:_buildCursor()
    local part = Instance.new("Part")
    part.Name        = "VRCursor"
    part.Size        = CURSOR_SIZE
    part.Anchored    = true
    part.CanCollide  = false
    part.CastShadow  = false
    part.Material    = Enum.Material.Neon
    part.Color       = CURSOR_COLOR
    part.Parent      = workspace
    return part
end

-- Add this method to VRController
function VRController:_pollThumbsticks()
    local gamepadState = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
    for _, input in ipairs(gamepadState) do
        if input.KeyCode == Enum.KeyCode.Thumbstick1 then
            self.eventBus:fire(E.VR_THUMBSTICK_LEFT, {
                x = input.Position.X,
                y = input.Position.Y,
            })
        elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
            self.eventBus:fire(E.VR_THUMBSTICK_RIGHT, {
                x = input.Position.X,
                y = input.Position.Y,
            })
        end
    end
end

return VRController
