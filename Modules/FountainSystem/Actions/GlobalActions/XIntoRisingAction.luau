-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- MidpointParticlesAction Module
local XIntoRisingAction = {}
XIntoRisingAction.__index = XIntoRisingAction

-- Constructor
function XIntoRisingAction:new(config)
	local instance = setmetatable({}, XIntoRisingAction)
	
	InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

-- Function to execute midpoint particle actions
function XIntoRisingAction:execute()
	local fountainParts = self.fountainParts

	local fountainPartsLength = self.fountainPartsAmount

	-- Enable and animate particles in pairs
	for i = 1, fountainPartsLength, 2 do
		local fountainPart1 = fountainParts[i]
		local water1 = fountainPart1.Water

		if i + 1 <= fountainPartsLength then
			local fountainPart2 = fountainParts[i + 1]
			local water2 = fountainPart2.Water

			local endSpeed = UtilityModule.getParticleHeight(self.fountainSection.Name, water1, 100)

			water1.Enabled = true
			water2.Enabled = true

			water1.Speed = NumberRange.new(0)
			water2.Speed = NumberRange.new(0)

			UtilityModule.SuperTween.new(water1, TweenInfo.new(self.fadeInTime - 1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), { Speed = endSpeed }):Play()
			UtilityModule.SuperTween.new(water2, TweenInfo.new(self.fadeInTime - 1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), { Speed = endSpeed }):Play()

			task.spawn(function()
				-- Initial positions and the midpoint
				local pos1 = fountainPart1.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(-45))
				local pos2 = fountainPart2.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(45))

				-- Apply initial orientation
				fountainPart1.CFrame = pos1
				fountainPart2.CFrame = pos2

				-- Define the target upright positions with a vertical rise
				local targetCFrame1 = fountainPart1.OriginalCFrame.Value
				local targetCFrame2 = fountainPart2.OriginalCFrame.Value

				-- Tween the parts to rise up straight
				
				local bruh = UtilityModule.createTween(fountainPart1, "CFrame", targetCFrame1, self.fadeInTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				bruh:Play()
				UtilityModule.createTween(fountainPart2, "CFrame", targetCFrame2, self.fadeInTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out):Play()
				
				if self.deactivateWhenComplete then
					bruh.Completed:Once(function()
						water1.Enabled = false
						water2.Enabled = false
					end)
				end
			end)
		end
	end
end

return XIntoRisingAction







