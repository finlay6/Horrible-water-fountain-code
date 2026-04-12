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
local DisableFountainSectionAction = {}
DisableFountainSectionAction.__index = DisableFountainSectionAction

-- Constructor
function DisableFountainSectionAction:new(config)
	local instance = setmetatable({}, DisableFountainSectionAction)

	InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

-- Function to enable the fountain section action
function DisableFountainSectionAction:execute()
	if self.groupProcessingMode == "OutwardsIn" then
		local i = 1
		local j = #self.fountainParts
		local staggerDelay = 0.5

		while i <= j do
			-- Disable the first part in the pair
			if self.fountainParts[i]:FindFirstChild("Water") then
				task.spawn(function()
					UtilityModule.disableParticle(self.fountainSection.Name, self.fountainParts[i].Water)
				end)
			end

			-- Disable the last part in the pair if it's not the same as the first
			if i ~= j and self.fountainParts[j]:FindFirstChild("Water") then
				task.spawn(function()
					UtilityModule.disableParticle(self.fountainSection.Name, self.fountainParts[j].Water)
				end)
			end

			i = i + 1
			j = j - 1
			task.wait(staggerDelay)
		end
	else
		for _, fountainPart in ipairs(self.fountainParts) do
			if fountainPart:FindFirstChild("Water") then
				UtilityModule.disableParticle(self.fountainSection.Name, fountainPart.Water)
			end
		end
	end
end

return DisableFountainSectionAction


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









