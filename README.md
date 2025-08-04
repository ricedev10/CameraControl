# How to use CameraControl

This package offers mainly flexibility but also ease of use. As an example, see below:

```luau
-- Local PlayerScript
local CameraControl = require(path.to.CameraControl)
local RunService = game:GetService("RunService")
local Client = game:GetService("Players").Player

RunService.PreRender:Connect(function(dt)
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	CameraControl:Update(dt, UserInputService:GetMouseDelta())
end)

local function onCharacterAdded()
	CameraControl.Mode = CameraControl.CameraMode.Orbital

	CameraControl.FilterDescendantsInstances = { character }
	CameraControl.Target = character
	warn(character, CameraControl.Target)
end


if Client.Character then
    onCharacterAdded(Client.Character)
end
Client.CharacterAdded:Connect(onCharacterAdded)

```
