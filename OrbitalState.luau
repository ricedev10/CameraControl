--!strict
local BaseState = require(script.Parent.BaseState)
local OribtalState: Orbital = BaseState.new() :: Orbital

export type Orbital = BaseState.BaseState<{
	RotationSensitivity: number,
	RotationReleaseSpeed: number,
	RotationSpeed: number,

	ZoomSpeed: number,
	Zoom: number,

	updateZoom: (self: Orbital, newCF: CFrame, cam: Camera, dt: number) -> boolean,

	_targetDelta: Vector2,
	_currentDelta: Vector2,
	_currentZoom: number,
}>
--[[ export type OribtalState = {
	Init: (self: OribtalState, target: PVInstance) -> (),
	Enter: (self: OribtalState) -> (),
	Exit: (self: OribtalState) -> (),
	Update: (self: OribtalState, cam: Camera, dt: number, mouseDelta: Vector2) -> (),

	Target: PVInstance,

	RotationSensitivity: number,
	RotationReleaseSpeed: number,
	RotationSpeed: number,
	Zoom: number,

	_targetDelta: Vector2,
	_currentDelta: Vector2,
} ]]

function OribtalState.Init(self: Orbital)
	self.RotationSensitivity = 0.99
	self.RotationReleaseSpeed = 0.99
	self.RotationSpeed = 0.99
	self.ZoomSpeed = 0.99
	self.FOV = 70
	self.Zoom = 15

	self._targetDelta = Vector2.zero
	self._currentDelta = Vector2.zero
	self._currentZoom = self.Zoom
end

function OribtalState.Update(self: Orbital, cam: Camera, dt: number, mouseDelta: Vector2)
	local Target = self.Target
	if not Target then
		warn("No camera update; Target not found")
		return
	end

	-- calculate new CFrame
	local Focus = Target:GetPivot()
	local newCF = CFrame.identity

	local delta = mouseDelta * self.RotationSensitivity
	self._targetDelta = Vector2.new(self._targetDelta.X - delta.X, math.clamp(self._targetDelta.Y + delta.Y, -80, 80))

	local newRotation = self._currentDelta:Lerp(
		self._targetDelta,
		1 - (1 - (if delta.Magnitude == 0 then self.RotationSpeed else self.RotationReleaseSpeed)) ^ dt
	)
	self._currentDelta = newRotation

	-- set CFrame
	local mult = 180 / math.pi
	newCF = CFrame.new(Focus.Position) * CFrame.fromOrientation(newRotation.Y / mult, newRotation.X / mult, 0)
	newCF = CFrame.lookAt((newCF + newCF.LookVector * self._currentZoom).Position, Focus.Position)

	-- update zoom
	local didUpdateZoom = self:updateZoom(newCF, cam, dt)

	-- update FOV
	self:updateFOV(cam, dt)

	if didUpdateZoom then
		newCF = CFrame.new(Focus.Position) * CFrame.fromOrientation(newRotation.Y / mult, newRotation.X / mult, 0)
		newCF = CFrame.lookAt((newCF + newCF.LookVector * self._currentZoom).Position, Focus.Position)
	end
	cam.CFrame = newCF
	cam.Focus = newCF
end

function OribtalState.updateZoom(self: Orbital, newCF: CFrame, cam: Camera, dt: number)
	local Focus = self.Target:GetPivot()

	-- transition to newZoom
	self._currentZoom = self:lerpDeltaTime(self._currentZoom, self.Zoom, self.ZoomSpeed, dt)

	-- But... check - is the camera in the way of an instance?
	local params = RaycastParams.new()
	params.BruteForceAllSlow = false
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.RespectCanCollide = true
	params.FilterDescendantsInstances = self.FilterDescendantsInstances

	local result: RaycastResult? = workspace:Raycast(Focus.Position, -newCF.LookVector * self._currentZoom, params)
	if not result then
		return false
	end

	if result.Instance and result.Instance:IsA("BasePart") and result.Instance.Transparency < 1 then
		self._currentZoom = result.Distance + cam.NearPlaneZ
		return true
	end

	return false
end

return OribtalState
