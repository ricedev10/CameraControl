# How to use CameraControl

This package offers mainly flexibility but also ease of use. As an example, see below:

```luau
-- Local PlayerScript
local CameraControl = require(path.to.CameraControl)
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Client = game:GetService("Players").LocalPlayer

RunService.PreRender:Connect(function(dt)
	CameraControl:Update(dt, UserInputService:GetMouseDelta())
end)

local function onCharacterAdded(character: Model)
	CameraControl.Mode = CameraControl.CameraMode.Orbital

	CameraControl.FilterDescendantsInstances = { character }
	CameraControl.Target = character
end


if Client.Character then
    onCharacterAdded(Client.Character)
end
Client.CharacterAdded:Connect(onCharacterAdded)

```
