-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local SuperTween = require(ReplicatedStorage.Classes.SuperTween)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

local ChangeLightingColor = {}
ChangeLightingColor.__index = ChangeLightingColor

function ChangeLightingColor:new(config)
	local instance = setmetatable({}, ChangeLightingColor)

	instance.transitionDuration = config.transitionDuration
	instance.color = config.Color
	
	print(instance, config)

	return instance
end

function ChangeLightingColor:execute()
	for _, part in workspace.Fountain:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Material == Enum.Material.Neon then
				print(self)
				part.Color  = self.color
			end
		end
		
		if part:IsA("Light") then
			local tween = TweenService:Create(part, TweenInfo.new(self.transitionDuration or 0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = self.color}):Play()
			part.Enabled = true
		end
	end
end

return ChangeLightingColor
