-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- BurstFountainSectionAction Module
local BurstFountainSectionAction = {}
BurstFountainSectionAction.__index = BurstFountainSectionAction

-- Constructor
function BurstFountainSectionAction:new(config)
	local instance = setmetatable({}, BurstFountainSectionAction)

	InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

-- Function to burst the fountain section action
function BurstFountainSectionAction:execute()
	for _, fountainPart in ipairs(self.fountainParts) do
		if fountainPart:FindFirstChild("Water") then
			local CloneTest = fountainPart.Water:Clone()
			CloneTest.Parent = fountainPart
			UtilityModule.setParticleHeight(self.fountainSection.Name, CloneTest, self.particlePower, self.lifetime)
			if UtilityModule.getParticleHeight(self.fountainSection.Name, CloneTest, self.particlePower).Max > 150 then
				task.spawn(function()
					task.wait(0.5)
					
					for _, value: ParticleEmitter in workspace.MistParts:GetDescendants() do
						if value:IsA("ParticleEmitter") then
							value.Enabled = true
						end
					end
					
					task.wait(2)
					
					for _, value: ParticleEmitter in workspace.MistParts:GetDescendants() do
						if value:IsA("ParticleEmitter") then
							value.Enabled = false
						end
					end
				end)
			end
			
			task.spawn(function()
				print(CloneTest)
				CloneTest.Enabled = true
				task.wait(self.addedWait)
				UtilityModule.disableParticle(self.fountainSection.Name, CloneTest)
			end)
		end
	end
end

return BurstFountainSectionAction










