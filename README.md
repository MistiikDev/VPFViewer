# VPFViewer
A module that simplifes the way VPF are handled in Roblox, allows to show models, and manipulate them inside the VPF

## Deps
 - You will need to get the "spring" module from BlackShibe and place it as a child of the ModuleScript.

## Methods
#### .new(player, vpf) returns the viewer object.
```lua
local viewer = VPFViewer.new(player, vpf)
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `player` | `Player` | **Required**. The Local Player |
| `vpf` | `ViewportFrame` | **Required**. The Viewport Frame object where all the items will be displayed |

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
