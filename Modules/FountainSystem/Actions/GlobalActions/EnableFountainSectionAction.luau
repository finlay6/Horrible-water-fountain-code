-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- EnableFountainSectionAction Module
local EnableFountainSectionAction = {}
EnableFountainSectionAction.__index = EnableFountainSectionAction

-- Constructor
function EnableFountainSectionAction:new(config)
	local instance = setmetatable({}, EnableFountainSectionAction)

	InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

-- Function to enable the fountain section action
function EnableFountainSectionAction:execute()
	print(self.fountainParts)
	for _, fountainPart in ipairs(self.fountainParts) do
		if fountainPart:FindFirstChild("Water") then
			UtilityModule.fadeInParticle(self.fountainSection.Name, fountainPart.Water, self.transitionTime, self.particlePower)
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

return EnableFountainSectionAction

--if self.customPartSelectionEnabled then
--	local start = self.customPartSelectionEnabled and self.customPartSelectionInterval or self.firstNumParts
--	local mid = self.customPartSelectionEnabled and #self.fountainSection:GetChildren() or self.secondNumParts
--	local increment = self.customPartSelectionEnabled and self.customPartSelectionInterval or 1

--	for currentFountainNumber = start, mid, increment do
--		local fountainPart = self.fountainParts[currentFountainNumber]
--		if fountainPart and fountainPart:FindFirstChild("Water") then
--			UtilityModule.fadeInParticle(self.fountainSection.Name, fountainPart.Water, self.transitionDuration, self.particlePower)
--		end
--	end
--else









