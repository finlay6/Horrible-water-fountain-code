-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- SweepingAction Module
local SweepingAction = {}
SweepingAction.__index = SweepingAction

-- Constructor
function SweepingAction:new(config)
	local instance = setmetatable({}, SweepingAction)

	InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

-- Helper function to handle sweeping for individual parts
local function sweepPart(fountainSection, part, totalDuration, fountainPartsAmount)
	if part then
		local CloneTest = part.Water:Clone()
		CloneTest.Parent = part
		task.spawn(function()
			task.wait(1)
			UtilityModule.disableParticle(fountainSection.Name, CloneTest)
		end)
		UtilityModule.setParticleHeight(fountainSection.Name, CloneTest)
		CloneTest.Enabled = true

		-- Wait for the next part activation (for sequential sweeping)
		task.wait(math.abs(totalDuration / fountainPartsAmount))
	end
end

function SweepingAction:sweepGroupedPartsSimultaneously()
	local groupSize = math.ceil(self.fountainPartsAmount / self.groupCount)

	for i = 1, groupSize do
		for groupIndex = 1, self.groupCount do
			local partIndex
			if self.isLeftToRightMotion then
				partIndex = (groupIndex - 1) * groupSize + i
			else
				partIndex = (groupIndex - 1) * groupSize + (groupSize - i + 1)
			end

			if partIndex <= self.fountainPartsAmount then
				task.spawn(function()
					sweepPart(self.fountainSection, self.fountainParts[partIndex], self.sequenceDuration, self.fountainPartsAmount)
				end)
			end
		end
		task.wait(self.partDelayTime)
	end
end

function SweepingAction:execute()
	for repeatIndex = 1, self.repeatTime or 1 do
		if self.groupCount then
			print("A")
			self:sweepGroupedPartsSimultaneously()
		else
			local step = self.isLeftToRightMotion and 1 or -1
			local start = self.isLeftToRightMotion and 1 or self.fountainPartsAmount
			local stop = self.isLeftToRightMotion and self.fountainPartsAmount or 1

			print("BRUH")

			for i = start, stop, step do
				sweepPart(self.fountainSection, self.fountainParts[i], self.sequenceDuration, self.fountainPartsAmount)
				task.wait(math.abs(self.sequenceDuration / self.fountainPartsAmount))
			end
		end

		-- Wait between repetitions, unless it's the last one
		if repeatIndex < (self.repeatTime or 1) then
			task.wait(self.waitBetweenRepeat or 0)
		end
	end
end

return SweepingAction






