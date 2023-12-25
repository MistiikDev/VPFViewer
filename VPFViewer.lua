local VPFViewer = {}
VPFViewer.__index = VPFViewer

local cas = game:GetService("ContextActionService")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local spring = require(script.spring)

function VPFViewer.new(player, vpf)
	local self = {
		_player = player,
		_camera = nil,
		_mouse = player:GetMouse(),

		_currentModel = nil,
		_currentModelCache = nil,

		_modelsCache = vpf:FindFirstChild("Cache"),

		_vpf = vpf,
		_holdingLMB = false,
		_connections = {},

		_mouseClickPos0 = nil,
		_mouseClickPos1 = nil,
		_mouseDelta = nil,

		_distanceFromModel = 0,
		_cameraOffset = 1,
		_sensitivity = 10,

		_spring = nil,

		_x_locked = true,
		_y_locked = false,

		_touchX = 0,
		_touchY = 0
	}

	return setmetatable(self, VPFViewer)
end

function VPFViewer:Init()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 70
	cam.Name = "VPFRender"

	self._camera = cam
	self._vpf.CurrentCamera = self._camera
end

function VPFViewer:SetupModel()
	self._currentModelCache:SetPrimaryPartCFrame(CFrame.new())
	
	self._spring = spring.create()
	self:FitCameraToVPF()

	cas:BindAction("moveObjectVPF", function (...) self:CAS_MoveCamera(...) end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)

	self._connections["touchBegin"] = uis.TouchMoved:Connect(function(touch, gameProcessedEvent)
		self._touchX = touch.Position.X
		self._touchY = touch.Position.Y
	end)

	self._connections["touchEnd"] = uis.TouchMoved:Connect(function(touch, gameProcessedEvent)
		self._touchX = 0
		self._touchY = 0
	end)	
end

function VPFViewer:FitCameraToVPF()
	local cf, size = self._currentModelCache:GetBoundingBox()
	local distance =  ((size.Magnitude / 2) / (math.tan(math.rad(self._camera.FieldOfView / 2))))
		
	self._camera.CFrame = CFrame.lookAt(self._currentModelCache.PrimaryPart.CFrame.Position + self._currentModelCache.PrimaryPart.CFrame.LookVector * distance * self._cameraOffset, self._currentModelCache.PrimaryPart.CFrame.Position)
	self._distanceFromModel = distance
end

function VPFViewer:CAS_MoveCamera(actionName, inputState, _inputObject)
	if inputState == Enum.UserInputState.Begin then
		self._holdingLMB = true

		self:MoveCamera() 
	elseif inputState == Enum.UserInputState.Cancel or inputState == Enum.UserInputState.End then
		self._holdingLMB = false
	end
end

function VPFViewer:MoveCamera()
	if self._currentModelCache then
		if uis.TouchEnabled then
			self._mouseClickPos0 = Vector2.new(self._touchX, self._touchY)
		else
			self._mouseClickPos0 = Vector2.new(self._mouse.X, self._mouse.Y)
		end

		if not self._connections["run"] then
			self._connections["run"] = runService.RenderStepped:Connect(function(dt)
				if self._holdingLMB then
					if uis.TouchEnabled then
						self._mouseClickPos1 = Vector2.new(self._touchX, self._touchY)
					end

					self._mouseClickPos1 = Vector2.new(self._mouse.X, self._mouse.Y)
					self._mouseDelta = (self._mouseClickPos1 - self._mouseClickPos0) / 50

					local x_delta, y_delta = self._mouseDelta.X, self._mouseDelta.Y

					local thetaY = (math.atan(y_delta / self._sensitivity)) * (self._y_locked and 0 or 1)
					local thetaX = (math.atan(x_delta / self._sensitivity)) * (self._x_locked and 0 or 1)

					self._spring:shove(Vector3.new(
						-thetaY, 
						thetaX,
						0)
					)
				end

				local spring_update = self._spring:update(dt)

				local spring_rotation = CFrame.Angles(
					spring_update.X, 
					spring_update.Y, 
					0
				)

				self._currentModelCache:SetPrimaryPartCFrame(self._currentModelCache.PrimaryPart.CFrame:Lerp(
					self._currentModelCache.PrimaryPart.CFrame * spring_rotation, 0.3 * dt * 60))

				self._mouseClickPos0 = self._mouseClickPos1
			end)
		end

	end	
end

-- Make a model appear on the VPF
function VPFViewer:ShowModel(model)
	if typeof(model) == "string" then
		if model == self._currentModel.Name then return end
	else
		if model == self._currentModel then return end
	end

	self:Clean()

	self._currentModel = model
	self._currentModelCache = self._modelsCache:FindFirstChild((typeof(model) == "string" and model or model.Name).."_cache")

	self:SetupModel()
end

-- 
function VPFViewer:LockAxis(x_locked, y_locked)
	self._x_locked = x_locked or false
	self._y_locked = y_locked or false
end

-- Add the models that will be displayed on the VPF to the cache to avoid loading times / issues and improve performances or large models.
function VPFViewer:CacheModels(Models)
	for i, model in pairs(Models) do 
		local cache = model:Clone()
		
		cache.Parent = self._modelsCache
		cache.Name = model.Name.."_cache"
		cache:SetPrimaryPartCFrame(CFrame.new(0,-1000,0))
	end
end

-- Clean current cache, use when models no longer needed
function VPFViewer:CleanCache()
	for i, model in pairs(self._modelsCache) do 
		model:Destroy()
	end
end

-- How far the model will be from the camera.
function VPFViewer:SetMultiplier(value)
	self._cameraOffset = value or 1
end

-- How sensitive the 3D model will move relative to the mouse movement. The lower the faster it will move
function VPFViewer:SetSensitivity(_sensitivity)
	self._sensitivity = _sensitivity or 10
end

--
function VPFViewer:Clean()
	for i, con in pairs(self._connections) do 
		con:Disconnect()
	end

	self._connections["run"] = nil
	self._camera.CFrame = CFrame.new()
	
	if (self._currentModelCache) then
		self._currentModelCache:SetPrimaryPartCFrame(CFrame.new(0,-1000,0))
	end
end

-- Destroy the viewer, use when vpf and models no longer needed
function VPFViewer:Destroy()
	self:Clean()
	self:CleanCache()

	self = nil -- destroy object
end

return VPFViewer
