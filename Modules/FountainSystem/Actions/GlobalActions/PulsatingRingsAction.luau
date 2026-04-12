-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

-- PulsatingRingsAction Module
local PulsatingRingsAction = {}
PulsatingRingsAction.__index = PulsatingRingsAction

-- Constructor
function PulsatingRingsAction:new(config)
	local instance = setmetatable({}, PulsatingRingsAction)

	-- Assign config properties
	instance.fountainSection = config.FountainSection
	instance.centerPosition = config.CenterPosition
	instance.degrees = config.Degrees
	instance.totalDuration = config.TotalDuration
	instance.durationBetween = config.DurationBetween
	instance.durationBetweenPulse = config.DurationBetweenPulse

	instance.endTime = time() + instance.totalDuration
	instance.fountainParts = UtilityModule.getParts(instance.fountainSection)

	-- Rotate the fountain parts to their initial positions
	for _, fountainPart in ipairs(instance.fountainParts) do
		fountainPart.CFrame = UtilityModule.calculateRotationCFrame(fountainPart, instance.centerPosition, instance.degrees)
	end

	return instance
end

-- Execution function
function PulsatingRingsAction:execute()
	while time() < self.endTime do
		for _, fountainPart in ipairs(self.fountainParts) do
			fountainPart.Water.Enabled = true
		end

		task.wait(self.durationBetween)

		for _, fountainPart in ipairs(self.fountainParts) do
			fountainPart.Water.Enabled = false
			fountainPart.CFrame = fountainPart.OriginalCFrame.Value
		end

		task.wait(self.durationBetweenPulse)
	end

	-- Reset the fountain parts to their original state
	for _, fountainPart in ipairs(self.fountainParts) do
		fountainPart.CFrame = fountainPart.OriginalCFrame.Value
		fountainPart.Water.Enabled = false
	end
end

return PulsatingRingsAction



