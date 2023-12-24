# VPFViewer
A module that simplifes the way VPF are handled in Roblox, allows to show models, and manipulate them inside the VPF

Uses a spring module to smoothen the rotation movement of the player.

![](https://github.com/MistiikDev/VPFViewer/blob/main/2023-12-04-22-14-09_1.gif)

An example on how to use it can be found at the very bottom.
## Deps
 - You will need to get the "spring" module from BlackShibe and place it as a child of the ModuleScript.

## Methods
#### .new(player, vpf) returns the viewer object.
```lua
local viewer = VPFViewer.new(player, vpf)
```

#### Init starts the module initializes variables and functions. ALWAYS CALL IT FIRST

```lua
viewer:Init()
```

#### :LockAxis allows to lock the x and y axis controlling the object's rotation in the VPF
```lua
viewer:LockAxis(x_locked, y_locked)
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `x_locked` | `Boolean` | **Optional**. Whether the x-axis is locked during object's rotation |
| `y_locked` | `Boolean` | **Optional**. Whether the y-axis is locked during object's rotation |

#### :CacheModels allows to cache given models before being shown on the VPF, to avoid loading times / issues and improve performances or large models.
```lua
VPFViewer:CacheModels(RS.Models:GetChildren())
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `Models` | `Array : {[any] : Model}` | **Required**. The array of models to cache before display on VPF |

#### :CleanCache allows to clean current models' cache
```lua
VPFViewer:CleanCache()
```

#### :ShowModel displays given model on the VPF
```lua
VPFViewer:ShowModel("Model1")
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `Model` | `string / Instance` | **Required**. Model or Model's name (if in cache) to show on the VPF |

#### :SetMultiplier sets how far the model will be from the camera.
```lua
VPFViewer:SetMultiplier(2) -- Twice as far as the maximum
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `Value` | `number` | **Optional**. Multiplier of the distance between the model and the camera, defaults to 1 |

#### :Destroy destroys the viewer object (becomes nil), use when vpf and models no longer needed
```lua
VPFViewer:Destroy()
```

## Example usage : 
```lua
local RS = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local p = players.LocalPlayer
local vpf = p.PlayerGui:WaitForChild("ViewportUI").ViewportFrame
local parts = RS.Parts

local Module = require(script.VPFViewer)

local Viewer = Module.new(p, p.PlayerGui:WaitForChild("ViewportUI").ViewportFrame)

Viewer:Init() -- ALWAYS INIT BEFORE ANY USE
Viewer:CacheModels(parts:GetChildren())
Viewer:LockAxis(false, false) -- Free Rotation on X and Y axis

game.UserInputService.InputBegan:Connect(function(inputObject)
	if inputObject.KeyCode == Enum.KeyCode.X then
		Viewer:ShowModel(parts.Part2)
	end
	
	if inputObject.KeyCode == Enum.KeyCode.V then
		Viewer:ShowModel(parts.Part)
	end
end)
```
