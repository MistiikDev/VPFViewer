local VPFViewer = {}
VPFViewer.__index = VPFViewer

local cas = game:GetService("ContextActionService")
local uis = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local spring = require(script.spring)

function VPFViewer.new(player, vpf)
	local self = {
		player = player,
		camera = nil,
		mouse = player:GetMouse(),

		currentModel = nil,
		currentModelCache = nil,

		modelsCache = vpf:FindFirstChild("Cache"),

		vpf = vpf,
		holdingLMB = false,
		connections = {},

		mouseClickPos0 = nil,
		mouseClickPos1 = nil,
		mouseDelta = nil,

		distanceFromModel = 0,
		cameraOffset = 1,
		sensitivity = 10,

		spring = nil,

		xlocked = true,
		ylocked = false,

		touchX = 0,
		touchY = 0
	}

	return setmetatable(self, VPFViewer)
end

function VPFViewer:Init()
	local cam = Instance.new("Camera")
	cam.FieldOfView = 70
	cam.Name = "VPFRender"

	self.camera = cam
	self.vpf.CurrentCamera = self.camera

	cas:BindAction("moveObjectVPF", function (...) self:CASMoveCamera(...) end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)

	self.connections["touchBegin"] = uis.TouchMoved:Connect(function(touch, gameProcessedEvent)
		self.touchX = touch.Position.X
		self.touchY = touch.Position.Y
	end)

	self.connections["touchEnd"] = uis.TouchMoved:Connect(function(touch, gameProcessedEvent)
		self.touchX = 0
		self.touchY = 0
	end)	
end

function VPFViewer:SetupModel()
	self.currentModelCache:SetPrimaryPartCFrame(CFrame.new())

	self.spring = spring.create()
	self:FitCameraToVPF()
end

function VPFViewer:FitCameraToVPF()
	local cf, size = self.currentModelCache:GetBoundingBox()
	local distance =  ((size.Magnitude / 2) / (math.tan(math.rad(self.camera.FieldOfView / 2))))

	self.camera.CFrame = CFrame.lookAt(self.currentModelCache.PrimaryPart.CFrame.Position + self.currentModelCache.PrimaryPart.CFrame.LookVector * distance * self.cameraOffset, self.currentModelCache.PrimaryPart.CFrame.Position)
	self.distanceFromModel = distance
end

function VPFViewer:CASMoveCamera(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.Begin then
		self.holdingLMB = true

		self:MoveCamera() 
	elseif inputState == Enum.UserInputState.Cancel or inputState == Enum.UserInputState.End then
		self.holdingLMB = false
	end
end

function VPFViewer:MoveCamera()
	if self.currentModelCache then
		if uis.TouchEnabled then
			self.mouseClickPos0 = Vector2.new(self.touchX, self.touchY)
		else
			self.mouseClickPos0 = Vector2.new(self.mouse.X, self.mouse.Y)
		end

		if not self.connections["run"] then
			self.connections["run"] = runService.RenderStepped:Connect(function(dt)
				if self.holdingLMB then
					if uis.TouchEnabled then
						self.mouseClickPos1 = Vector2.new(self.touchX, self.touchY)
					end

					self.mouseClickPos1 = Vector2.new(self.mouse.X, self.mouse.Y)
					self.mouseDelta = (self.mouseClickPos1 - self.mouseClickPos0) / 50

					local xdelta, ydelta = self.mouseDelta.X, self.mouseDelta.Y

					local thetaY = (math.atan(ydelta / self.sensitivity)) * (self.ylocked and 0 or 1)
					local thetaX = (math.atan(xdelta / self.sensitivity)) * (self.xlocked and 0 or 1)

					self.spring:shove(Vector3.new(
						-thetaY, 
						thetaX,
						0)
					)
				end

				local springupdate = self.spring:update(dt)

				local springrotation = CFrame.Angles(
					springupdate.X, 
					springupdate.Y, 
					0
				)

				self.currentModelCache:SetPrimaryPartCFrame(self.currentModelCache.PrimaryPart.CFrame:Lerp(
					self.currentModelCache.PrimaryPart.CFrame * springrotation, 0.3 * dt * 60))

				self.mouseClickPos0 = self.mouseClickPos1
			end)
		end

	end	
end

-- Make a model appear on the VPF
function VPFViewer:ShowModel(model)
	if typeof(model) == "string" then
		if model == self.currentModel.Name then return end
	else
		if model == self.currentModel then return end
	end

	self:Clean()

	self.currentModel = model
	self.currentModelCache = self.modelsCache:FindFirstChild((typeof(model) == "string" and model or model.Name).."cache")

	self:SetupModel()
end

-- 
function VPFViewer:LockAxis(xlocked, ylocked)
	self.xlocked = xlocked or false
	self.ylocked = ylocked or false
end

-- Add the models that will be displayed on the VPF to the cache to avoid loading times / issues and improve performances or large models.
function VPFViewer:CacheModels(Models)
	for i, model in pairs(Models) do 
		local cache = model:Clone()

		cache.Parent = self.modelsCache
		cache.Name = model.Name.."cache"
		cache:SetPrimaryPartCFrame(CFrame.new(0,-1000,0))
	end
end

-- Clean current cache, use when models no longer needed
function VPFViewer:CleanCache()
	for i, model in pairs(self.modelsCache) do 
		model:Destroy()
	end
end

-- How far the model will be from the camera.
function VPFViewer:SetMultiplier(value)
	self.cameraOffset = value or 1
end

-- How sensitive the 3D model will move relative to the mouse movement. The lower the faster it will move
function VPFViewer:SetSensitivity(sensitivity)
	self.sensitivity = sensitivity or 10
end


--
function VPFViewer:Clean()
	if self.connections["run"] then 
		self.connections["run"]:Disconnect()
	end
	
	self.connections["run"] = nil
	self.camera.CFrame = CFrame.new()

	if (self.currentModelCache) then
		self.currentModelCache:SetPrimaryPartCFrame(CFrame.new(0,-1000,0))
	end
end

-- Destroy the viewer, use when vpf and models no longer needed
function VPFViewer:Destroy()
	for i, con in pairs(self.connections) do 
		con:Disconnect()
	end

	self:Clean()
	self:CleanCache()

	self = nil -- destroy object
end

return VPFViewer
