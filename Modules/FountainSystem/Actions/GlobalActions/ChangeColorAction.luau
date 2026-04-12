-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- CircleArpeggioAction Module
local ChangeColorAction = {}
ChangeColorAction.__index = ChangeColorAction

-- Constructor
function ChangeColorAction:new(config)
	local instance = setmetatable({}, ChangeColorAction)
	
	InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

-- Main execution function
function ChangeColorAction:execute()
	local ParticleColor = self.particleColor
	
	for _, fountainPart in self.fountainParts do
		fountainPart.Water.Color = ColorSequence.new(ParticleColor)
	end
end

return ChangeColorAction





