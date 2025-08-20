--!strict
local BaseState = require(script.Parent.BaseState)
local FirstPersonState: FirstPersonState = BaseState.new() :: FirstPersonState
local UserInputService = game:GetService("UserInputService")

export type FirstPersonState = BaseState.BaseState<{
	RotationSensitivity: number,
	RotationReleaseSpeed: number,
	RotationSpeed: number,
	RotationLimit: number,

	ZoomSpeed: number,
	Zoom: number,

	updateZoom: (self: FirstPersonState, newCF: CFrame, cam: Camera, dt: number) -> boolean,

	_targetDelta: Vector2,
	_currentDelta: Vector2,
	_currentZoom: number,
}>

function FirstPersonState.Init(self: FirstPersonState)
	self.RotationSensitivity = 0.99
	self.RotationReleaseSpeed = 0.99
	self.RotationSpeed = 0.99
	self.ZoomSpeed = 0.99
	self.RotationLimit = 89 -- angle rotation limit (in degrees) along the x-axis (turning head up/down)
	self.FOV = 80
	self.Zoom = 10

	self._targetDelta = Vector2.zero
	self._currentDelta = Vector2.zero
	self._currentZoom = self.Zoom
end

function FirstPersonState.Update(self: FirstPersonState, cam: Camera, dt: number, mouseDelta: Vector2)
	local Target = self.Target
	if not Target then
		warn("No camera update; Target not found")
		return
	end
	if not Target:IsA("Model") or not Target.PrimaryPart then
		warn("Target must be a model for FirstPerson and must have a PrimaryPart")
		return
	end

	local head = Target:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		warn('No camera update; "Head" not found!')
		return
	end

	-- calculate new CFrame
	local Focus = Target.PrimaryPart.CFrame
	local newCF = CFrame.identity
	local newFocus = CFrame.identity

	local delta = mouseDelta * self.RotationSensitivity
	self._targetDelta = Vector2.new(
		self._targetDelta.X - delta.X,
		math.clamp(self._targetDelta.Y + delta.Y, -self.RotationLimit, self.RotationLimit)
	)

	local newRotation = self._currentDelta:Lerp(
		self._targetDelta,
		1 - (1 - (if delta.Magnitude == 0 then self.RotationSpeed else self.RotationReleaseSpeed)) ^ dt
	)
	self._currentDelta = newRotation

	-- set CFrame
	local focusOrientation = Focus - Focus.Position
	local mult = 180 / math.pi
	newCF = CFrame.new(Focus.Position) * CFrame.fromOrientation(newRotation.Y / mult, newRotation.X / mult, 0)
	newCF = CFrame.lookAt((newCF + newCF.LookVector * self._currentZoom).Position, Focus.Position)

	local headFront = head.CFrame * CFrame.new(0, 0.2, -head.Size.Z / 2)
	local offset = (headFront.Position - newCF.Position)
	newCF += offset
	newFocus = cam.Focus + offset

	-- update zoom
	local _didUpdateZoom = self:updateZoom(newCF, cam, dt)

	-- update FOV
	self:updateFOV(cam, dt)

	cam.CFrame = newCF
	cam.Focus = newFocus

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

function FirstPersonState.updateZoom(self: FirstPersonState, newCF: CFrame, cam: Camera, dt: number)
	-- transition to newZoom
	local newZoom = self:lerpDeltaTime(self._currentZoom, self.Zoom, self.ZoomSpeed, dt)
	local changed = math.abs(newZoom - self._currentZoom) >= 0.05
	self._currentZoom = newZoom

	return changed
end

return FirstPersonState
