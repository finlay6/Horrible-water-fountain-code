-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local InstanceInitialiser = require(utilityModules.InstanceInitializer)
local UtilityModule = require(utilityModules.UtilityModule)

-- FireGroupAction Module
local FireGroupAction = {}
FireGroupAction.__index = FireGroupAction

-- Constructor
function FireGroupAction:new(config)
	local instance = setmetatable({}, FireGroupAction)

	-- Assign config properties
	instance.fountainSection = config.FountainSection
	instance.delayBetweenGroups = config.DelayBetweenGroups
	instance.fireGroupAmount = config.FireGroupCount
	instance.sequenceDuration = config.SequenceDuration
	instance.leftToRight = config.LeftToRight
	instance.repeatTime = config.RepeatTime

	instance.lastFireFolder = nil

	return instance
end

-- Function to activate or deactivate a fire group
local currentActiveChild = nil

-- Function to trigger fire groups sequentially
function FireGroupAction:fireGroups()
	-- Deactivate all children in each folder except folder 6
	for _, fireFolder in self.fountainSection:GetChildren() do
		-- Skip folder 6 during deactivation
		if fireFolder.Name ~= "6" then
			for _, child in ipairs(fireFolder:GetChildren()) do
				local emitter = child:FindFirstChildWhichIsA("ParticleEmitter")
				if emitter then
					emitter.Enabled = false
				end
			end
		end
	end

	-- Collect all children from all fire folders in the fountain section (excluding folder 6)
	local allChildren = {}
	for _, fireFolder in self.fountainSection:GetChildren() do
		-- Skip folder 6 during collection
		if fireFolder.Name ~= "6" then
			for _, child in ipairs(fireFolder:GetChildren()) do
				table.insert(allChildren, child)
			end
		end
	end

	-- Select one random child from all the children
	currentActiveChild = allChildren[math.random(1, #allChildren)]

	-- Activate the random selected child
	local emitter = currentActiveChild:FindFirstChildWhichIsA("ParticleEmitter")
	if emitter then
		emitter.Enabled = true
	end
end

-- Main execution function
function FireGroupAction:execute()
	local endTime = time() + self.sequenceDuration

	-- Run the fire groups until the time runs out
	while time() < endTime do
		self:fireGroups()
		task.wait(self.delayBetweenGroups)
	end

	-- Deactivate the current active child at the end of execution
	if currentActiveChild then
		local emitter = currentActiveChild:FindFirstChildWhichIsA("ParticleEmitter")
		if emitter then
			emitter.Enabled = false
		end
	end
end

return FireGroupAction





