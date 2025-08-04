--!strict
local BaseState = {}
BaseState.__index = BaseState

export type BaseState<t = {}> = {
	Target: PVInstance,
	FilterDescendantsInstances: { Instance }, -- for spacial queries of the camera in world space
	FOV: number,

	Init: (self: BaseState<t>) -> (),
	Enter: (self: BaseState<t>, target: PVInstance, filterDescendantsInstances: { Instance }) -> (),
	Exit: (self: BaseState<t>) -> (),
	Update: (self: BaseState<t>, camera: Camera, dt: number, mouseDelta: Vector2) -> (),
	updateFOV: (self: BaseState<t>, camera: Camera, dt: number) -> (),

	lerpVector: (self: BaseState<t>, a: Vector3, b: Vector3, t: number, dt: number) -> Vector3,
	lerpDeltaTime: (self: BaseState<t>, a: number, b: number, t: number, dt: number) -> number,

	_lastFOV: number,
} & t
--[[ export type BaseState = {
	Init: (self: BaseState, target: PVInstance) -> (),
	Enter: (self: BaseState) -> (),
	Exit: (self: BaseState) -> (),
	Update: (self: BaseState, cam: Camera, dt: number, mouseDelta: Vector2) -> (),
	lerpVector: (self: BaseState, a: Vector3, b: Vector3, t: number, dt: number) -> Vector3,
	lerpDeltaTime: (self: BaseState, a: number, b: number, t: number, dt: number) -> number,

	TopDownAngleSpeed: number,
	TopDownOrigin: CFrame,
	Distance: number, -- distance from ground to camera height

	Target: PVInstance,
	TopDownAngle: Vector3,

	_currentTopDownAngle: Vector3,
	_lastTopDownPosition: Vector3,
} ]]

function BaseState.new(): BaseState
	local self = {}

	return setmetatable(self, BaseState) :: any
end

function BaseState:Init() end

function BaseState:Enter(target: PVInstance, filterDescendantsInstances)
	self.Target = target
	self.FilterDescendantsInstances = filterDescendantsInstances
end
function BaseState:Exit() end
function BaseState:Update(cam: Camera, dt: number, mouseDelta: Vector2)
	self:updateFOV(cam, dt)
end
function BaseState:updateFOV(cam: Camera, dt: number)
	if not self._lastFOV then
		self._lastFOV = cam.FieldOfView
	end

	local newFOV = self:lerpDeltaTime(self._lastFOV, self.FOV, 0.9, dt)
	cam.FieldOfView = newFOV
	self._lastFOV = newFOV
end

function BaseState:lerpVector(a: Vector3, b: Vector3, t: number, dt: number)
	return a + (b - a) * (1 - (1 - t) ^ dt)
end
function BaseState:lerpDeltaTime(a: number, b: number, t: number, dt: number)
	return a + (b - a) * (1 - (1 - t) ^ dt)
end

return BaseState
