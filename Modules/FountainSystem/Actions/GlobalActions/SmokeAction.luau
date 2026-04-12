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
local SmokeAction = {}
SmokeAction.__index = SmokeAction

-- Constructor
function SmokeAction:new(config)
	local instance = setmetatable({}, SmokeAction)
	
	print(config)

	instance.smokeParts = config.FountainSection:GetChildren()
	instance.sequenceDuration = config.SequenceDuration

	return instance
end

-- Function to burst the fountain section action
function SmokeAction:execute()
	for index, value in self.smokeParts do
		if value:FindFirstChild("Smoke") then
			value.Smoke.Enabled = true
		end
	end
	
	task.wait(self.sequenceDuration)
	
	for index, value in self.smokeParts do
		if value:FindFirstChild("Smoke") then
			value.Smoke.Enabled = false
		end
	end
end

return SmokeAction










