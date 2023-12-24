local VPFViewer = {}
VPFViewer.__index = VPFViewer

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
		
		_spring = nil,
		
		_x_locked = true,
		_y_locked = false
	}
	
	return setmetatable(self, VPFViewer)
end

--[[
	"Outside" functions, adjust settings or add models to cache for eg
]]--

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
		cache.PrimaryPart.CFrame = CFrame.new(0,-100,0)
	end
end

-- Clean current cache, use when models no longer needed
function VPFViewer:CleanCache()
	for i, model in pairs(self._modelsCache) do 
		model:Destroy()
	end
end

-- Make a model appear on the VPF
function VPFViewer:AsignNewModel(model)
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


-- How far the model will be from the camera.
function VPFViewer:SetMultiplier(value)
	self._cameraOffset = value or 1
end

-- Destroy the viewer, use when vpf and models no longer needed
function VPFViewer:Destroy()
	self:Clean()
	self:CleanCache()
	
	self = nil -- destroy object
end

--[[
	"Internal" functions, used inside the module, use at your own risk.
]]--
function VPFViewer:SetupModel()
	self._currentModelCache.PrimaryPart.CFrame = CFrame.new(0, 0, 0)
	self._spring = spring.create(self._currentModel.PrimaryPart.Mass or 50)
	
	self:FitCameraToVPF()
	
	self._connections [#self._connections + 1] = self._vpf.InputBegan:Connect(function(inputobj)
		if inputobj.UserInputType == Enum.UserInputType.MouseButton1 then
			self._holdingLMB = true
			
			self:MoveCamera()
		end
	end)

	self._connections [#self._connections + 1] = self._vpf.InputEnded:Connect(function(inputobj)
		if inputobj.UserInputType == Enum.UserInputType.MouseButton1 then
			self._holdingLMB = false
		end
	end)
end

function VPFViewer:FitCameraToVPF()
	self._vpf.CurrentCamera.CFrame = CFrame.new()
	
	local Model = self._currentModel
	local cf, size = Model:GetBoundingBox()
	
	local fov = self._vpf.CurrentCamera.FieldOfView
	local d = ((size.Magnitude / 2) / (math.tan( math.rad(fov / 2) )))
	
	self._currentModelCache.PrimaryPart.CFrame = self._vpf.CurrentCamera.CFrame * self._vpf.CurrentCamera.CFrame:ToObjectSpace(
			CFrame.new(Vector3.new(0,0, -d * self._cameraOffset)) * CFrame.Angles(0, math.pi, 0) 
	)
	
	self._distanceFromModel = d
end

function VPFViewer:Init()
	self._camera = Instance.new("Camera")
	self._camera.CFrame = CFrame.new()
	
	self._vpf.CurrentCamera = self._camera
end

function VPFViewer:Clean()
	for i, con in pairs(self._connections) do 
		con:Disconnect()
	end
	
	self._connections["run"] = nil
	self._vpf.CurrentCamera.CFrame = CFrame.new()
	
	if self._currentModelCache then
		self._currentModelCache.PrimaryPart.CFrame = CFrame.new(0,-100,0)
	end
end

function VPFViewer:MoveCamera()
	if self._currentModelCache then
		self._mouseClickPos0 = Vector2.new(self._mouse.X, self._mouse.Y)
		
		if not self._connections["run"] then
			self._connections["run"] = runService.RenderStepped:Connect(function(dt)
				if self._holdingLMB then
					self._mouseClickPos1 = Vector2.new(self._mouse.X, self._mouse.Y)
					self._mouseDelta = (self._mouseClickPos1 - self._mouseClickPos0) / 50

					local x_delta, y_delta = self._mouseDelta.X, self._mouseDelta.Y

					local thetaX = (math.atan(y_delta / math.max(1, self._distanceFromModel))) * (self._x_locked and 0 or 1)
					local thetaY = (math.atan(x_delta / math.max(1, self._distanceFromModel))) * (self._y_locked and 0 or 1)

					self._spring:shove(Vector3.new(
						math.sign(self._currentModelCache.PrimaryPart.CFrame.RightVector.X) * thetaX, 
						math.sign(self._currentModelCache.PrimaryPart.CFrame.UpVector.Y) * thetaY, 
						0)
					)
				end

				local spring_update = self._spring:update(dt)

				local spring_rotation = CFrame.Angles(
					spring_update.X, 
					spring_update.Y, 
					0
				)

				self._currentModelCache.PrimaryPart.CFrame = self._currentModelCache.PrimaryPart.CFrame:Lerp(
					self._currentModelCache.PrimaryPart.CFrame * spring_rotation, 0.3 * dt * 60)

				self._mouseClickPos0 = self._mouseClickPos1
			end)
		end
	end	
end

return VPFViewer
