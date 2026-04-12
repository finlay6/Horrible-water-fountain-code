-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local SuperTween = require(ReplicatedStorage.Classes.SuperTween)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- AnglePartsAction Module
local UpAndDownAction = {}
UpAndDownAction.__index = UpAndDownAction

-- Constructor
function UpAndDownAction:new(config)
	local instance = setmetatable({}, UpAndDownAction)

	instance = InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

-- Execution function
function UpAndDownAction:execute()
	local sequenceDuration = self.sequenceDuration
	local durationBetween = self.durationBetween
	local parts = self.fountainParts
	local totalParts = #parts
	local speedMinus = 50

	-- Store original speeds
	local originalSpeeds = {}
	for _, part in parts do
		local water = part.Water
		water.Enabled = true
		originalSpeeds[water] = {
			Min = UtilityModule.getParticleHeight(self.fountainSection.Name, water).Min,
			Max = UtilityModule.getParticleHeight(self.fountainSection.Name, water).Max
		}
	end
	
	print(sequenceDuration)
	local elapsedTime = 0
	local endTime = time() + sequenceDuration
	while time() < endTime do
		print("BOUNCING")
		-- Lower speed
		for _, part in parts do
			local water = part.Water
			local original = originalSpeeds[water]
			water.Speed = NumberRange.new(original.Min - speedMinus, original.Max - speedMinus)
		end

		task.wait(durationBetween)

		-- Raise speed back
		for _, part in parts do
			local water = part.Water
			local original = originalSpeeds[water]
			water.Speed = NumberRange.new(original.Min, original.Max)
		end

		task.wait(durationBetween)
	end
end

return UpAndDownAction


