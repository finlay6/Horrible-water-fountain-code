-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

local BurstAction = {}
BurstAction.__index = BurstAction

-- // Type Declarations \\ --

type Config = {
	FountainSection: Instance,
	CustomPartSelectionEnabled: boolean,
	CustomPartSelectionInterval: number,
	PartNamePrefix: string,
	ParticlePower: number,
	SelectParts: boolean,
	FirstNumParts: number,
	SecondNumParts: number
}

-- // Helper Functions \\ --

-- Helper function to handle particle logic
local function handleFountainPart(fountainPart: Part, sectionName: string, particlePower: number)
	local water = fountainPart:FindFirstChild("Water")
	
	if fountainPart and water then
		UtilityModule.setParticleHeight(sectionName, water, particlePower)
		water.Enabled = true
		UtilityModule.disableParticle(sectionName, water)
	end
end

-- Constructor
function BurstAction:new(variables: Config)
	local burstActionInstance = setmetatable({}, BurstAction)

	-- Properties from the variables
	burstActionInstance.fountainSection = variables.FountainSection
	burstActionInstance.customPartSelectionEnabled = variables.CustomPartSelectionEnabled
	burstActionInstance.customPartSelectionInterval = variables.CustomPartSelectionInterval
	burstActionInstance.partNamePrefix = variables.PartNamePrefix
	burstActionInstance.particlePower = variables.ParticlePower
	burstActionInstance.selectParts = variables.SelectParts
	burstActionInstance.firstNumParts = variables.FirstNumParts
	burstActionInstance.secondNumParts = variables.SecondNumParts

	-- Get the fountain parts using UtilityModule
	burstActionInstance.fountainParts = UtilityModule.getParts(
		burstActionInstance.fountainSection,
		burstActionInstance.customPartSelectionEnabled,
		burstActionInstance.customPartSelectionInterval,
		burstActionInstance.partNamePrefix
	)

	return burstActionInstance
end

-- Execution logic
function BurstAction:execute()
	local startIndex = self.customPartSelectionEnabled and self.customPartSelectionInterval or self.firstNumParts
	local midIndex = self.customPartSelectionEnabled and #self.fountainSection:GetChildren() or self.secondNumParts
	local incrementValue = self.customPartSelectionEnabled and self.customPartSelectionInterval or 1

	-- Select parts based on variablesuration or iterate over all parts
	if self.customPartSelectionEnabled or self.selectParts then
		for currentFountainNumber = startIndex, midIndex, incrementValue do
			local fountainPart = self.fountainParts[currentFountainNumber]
			handleFountainPart(fountainPart, self.fountainSection.Name, self.particlePower)
		end
	else
		for _, fountainPart in ipairs(self.fountainSection:GetChildren()) do
			handleFountainPart(fountainPart, self.fountainSection.Name, self.particlePower)
		end
	end
end

return BurstAction
