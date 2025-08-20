--!strict
--[[ HOW TO USE
Use CameraService:SetFocusPart(part: BasePart, smoothTransition: boolean?) to set the camera's part for using side/top
view and it will calculate the constraints of camera movement. For default mode (which is just freely rotating), you
can set it CameraService.Mode

FocusPart Attributes:
	CameraMode: string [the name of the CameraMode to set when focused at part]
]]
local OrbitalState = require(script.OrbitalState)
local TopDownState = require(script.TopDown)
local BaseState = require(script.BaseState)
local FirstPersonState = require(script.FirstPersonState)

local CameraService: CameraService = {} :: CameraService
CameraService.Mode = TopDownState

CameraService.RotationSensitivity = 1
CameraService.RotationReleaseSpeed = 0.99
CameraService.RotationSpeed = 0.99

-- CameraService.ZoomSpeed = 0.99
-- CameraService.Zoom = 100 -- starting/default zoom (in studs away from target)

CameraService.TopDownOrigin = CFrame.new(0, 5, 0)
CameraService.TopDownAngle = Vector3.new(math.rad(10), 0, 0)
CameraService.TopDownAngleSpeed = 0.98

-- Types
type CameraMode = BaseState.BaseState<any>
export type CameraService = {
	-- Properties
	Mode: CameraMode,
	Target: PVInstance,

	RotationSensitivity: number, -- amount that camera rotates due to mouse delta movement
	RotationReleaseSpeed: number, -- how fast camera rotates to goal when mouse does NOT move (between 0-1; lerp function)
	RotationSpeed: number, -- how fast camera rotates to goal (between 0-1; lerp function) [NOTE: setting RotationReleaseSpeed and RotationSpeed as a number that differs greatly can cause weird effects]

	ZoomSpeed: number, -- how fast camera zooms to goal (between 0-1; lerp function)
	FilterDescendantsInstances: { Instance }, -- for zooming

	TopDownOrigin: CFrame, -- CFrame in world-space of TopDown (x/z position does not really matter; y is height; and rotation of CFrame is applied)
	TopDownAngle: Vector3, -- applied x then y then z; in radians
	TopDownAngleSpeed: number, -- how fast camera rotates to angle goal (between 0-1; lerp)

	-- Enums / Read-only
	CameraMode: {
		Orbital: OrbitalState.Orbital,
		TopDown: TopDownState.TopDown,
		FirstPersonState: FirstPersonState.FirstPersonState,
	},

	-- Methods
	GetCamera: (self: CameraService) -> Camera,
	Update: (self: CameraService, deltaTime: number, mouseDelta: Vector2) -> (),
	ZoomIn: (self: CameraService, amountInStuds: number) -> (),
	ZoomOut: (self: CameraService, amountInStuds: number) -> (),
	SetZoom: (self: CameraService, newZoom: number) -> (),
	GetZoom: (self: CameraService) -> number,

	-- private
	_lastMode: CameraMode,

	-- _currentZoom: number,
	_seeThroughParts: { BasePart },

	_targetDelta: Vector2,
	_currentDelta: Vector2,

	_currentTopDownAngle: Vector3,
	_lastTopDownPosition: Vector3,

	_run: RBXScriptConnection?,
}
-- type CameraMode = OrbitalState.Orbital & TopDownState.TopDown

-- Properties
CameraService._run = nil :: RBXScriptConnection?
CameraService._targetDelta = Vector2.zero
CameraService._currentDelta = Vector2.zero
CameraService._seeThroughParts = {}
CameraService._currentTopDownAngle = Vector3.zero
CameraService.CameraMode = {
	Orbital = OrbitalState,
	TopDown = TopDownState,
	FirstPersonState = FirstPersonState,
}

do -- initialize CameraModes
	for _, mode: BaseState.BaseState in CameraService.CameraMode :: any do
		mode:Init()
	end
end

-- Methods
function CameraService:GetCamera()
	return workspace.CurrentCamera
end

function CameraService:Update(dt: number, mouseDelta: Vector2)
	if not self.Target then
		return
	end

	local camera = self:GetCamera()
	camera.CameraType = Enum.CameraType.Scriptable

	-- update camera CFrame
	if self.Mode ~= self._lastMode then
		if self._lastMode then
			self._lastMode:Exit()
		end

		self.Mode:Enter(self.Target, self.FilterDescendantsInstances)
	end

	self.Mode:Update(camera, dt, mouseDelta)
	self._lastMode = self.Mode
end

function CameraService:ZoomIn(amount: number)
	self.CameraMode.Orbital.Zoom -= amount
end
function CameraService:ZoomOut(amount: number)
	self.CameraMode.Orbital.Zoom += amount
end
function CameraService:SetZoom(newZoom: number)
	self.CameraMode.Orbital.Zoom = newZoom
end
function CameraService:GetZoom()
	return self.CameraMode.Orbital.Zoom
end

return CameraService
