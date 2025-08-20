--!strict
local BaseState = require(script.Parent.BaseState)
local TopDown: TopDown = BaseState.new() :: TopDown

export type TopDown = BaseState.BaseState<{
	TopDownAngleSpeed: number,
	TopDownOrigin: CFrame,
	TopDownAngle: Vector3,
	Distance: number,
	FOV: number,

	_lastFocusPosition: Vector3, -- so we know the direction the Focus is going
	_currentTopDownAngle: Vector3,
	_lastTopDownPosition: Vector3,
	_seeThroughParts: { BasePart },
	_speed: number, -- how fast the camera is moving; in studs per second
}>

function TopDown:Init()
	self.TopDownAngleSpeed = 0.4
	self.TopDownOrigin = CFrame.new(0, 10, 0)
	self.TopDownAngle = Vector3.new(math.rad(30), 0, 0)
	self.Distance = 30
	self.FOV = 60
	self._speed = 0

	self._lastFocusPosition = Vector3.zero
	self._currentTopDownAngle = Vector3.zero
	self._lastTopDownPosition = Vector3.zero
	self._seeThroughParts = {}
end

function TopDown:Exit() end

function TopDown:Update(cam: Camera, dt: number, _mouseDelta: Vector2)
	local Target = self.Target
	if not Target then
		warn("No camera update; Target not found")
		return
	end

	-- update angle
	self._currentTopDownAngle =
		self:lerpVector(self._currentTopDownAngle, self.TopDownAngle, self.TopDownAngleSpeed, dt)

	local Focus = Target:GetPivot()

	local Origin = self.TopDownOrigin
	local angle = self._currentTopDownAngle
	local direction = (Focus.Position - self._lastFocusPosition) / dt
	local distance = if direction.Magnitude == 0
		then Vector3.zero
		else (
			direction.Unit
			* (if direction.Magnitude < 1 then 0 else 1)
			* direction.Magnitude
			/ self.TopDownAngleSpeed
		)
	local position = self:lerpVector(
		self._lastTopDownPosition or cam.CFrame.Position,
		Vector3.new(Focus.X, Origin.Y, Focus.Z) + distance,
		self.TopDownAngleSpeed,
		dt
	)

	-- floor
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { Target }
	local result = workspace:Raycast(Focus.Position, -Vector3.yAxis * 10, params)
	if result then
		self.TopDownOrigin = CFrame.new(result.Position)
	end

	-- calculate speed
	self._speed = 20 --(self._lastTopDownPosition - position).Magnitude / dt

	local newCF = CFrame.new(position)
		* CFrame.Angles(-math.pi / 2.4, 0, 0)
		* Origin.Rotation
		* CFrame.Angles(angle.X, angle.Y, angle.Z)
	newCF -= newCF.LookVector * self.Distance

	cam.CFrame = newCF
	self._lastTopDownPosition = position
	self._lastFocusPosition = Focus.Position

	-- update FOV
	self:updateFOV(cam, dt)

	-- allow player to see through parts
	local obscuringParts = cam:GetPartsObscuringTarget({ Focus.Position }, self.FilterDescendantsInstances)
	for _, v in obscuringParts do
		v.LocalTransparencyModifier = self:lerpDeltaTime(v.LocalTransparencyModifier, 0.8, 0.999, dt)
	end
	local newSeeThrough = obscuringParts
	for _, v in self._seeThroughParts do
		if not table.find(obscuringParts, v) then
			v.LocalTransparencyModifier = self:lerpDeltaTime(v.LocalTransparencyModifier, 0, 0.999, dt)
			if v.LocalTransparencyModifier >= 0.01 then
				table.insert(newSeeThrough, v)
			else
				v.LocalTransparencyModifier = 0
			end
		end
	end
	self._seeThroughParts = newSeeThrough
end

return TopDown
