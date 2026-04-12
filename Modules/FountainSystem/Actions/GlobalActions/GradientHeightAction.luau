-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- GradientHeightAction Module
local GradientHeightAction = {}
GradientHeightAction.__index = GradientHeightAction

-- Constructor
function GradientHeightAction:new(config)
	local instance = setmetatable({}, GradientHeightAction)

	InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

function GradientHeightAction:execute()
	local groupSize = self.groupSize or #self.fountainParts
	local totalParts = #self.fountainParts
	local increaseDirection = self.increasingGradient

	for i = 1, totalParts, groupSize do
		local lastIndex = math.min(i + groupSize - 1, totalParts)

		for j = i, lastIndex do
			local part = self.fountainParts[j]
			local groupIndex = j - i + 1
			local adjustedIndex = increaseDirection and groupIndex or (groupSize - groupIndex + 1)
			local heightFactor = (0.7 + (0.3 * (adjustedIndex - 1) / (groupSize - 1))) * 100 -- 70% to 100%

			if part:FindFirstChild("Water") then
				UtilityModule.setParticleHeight(self.fountainSection.Name, part.Water, heightFactor)
			end
		end
	end

	if self.sequenceDuration ~= -1 then
		task.wait(self.sequenceDuration)

		for _, fountainPart in ipairs(self.fountainParts) do
			if fountainPart:FindFirstChild("Water") then
				UtilityModule.disableParticle(self.fountainSection.Name, fountainPart.Water)
			end
		end
	end
end

return GradientHeightAction









