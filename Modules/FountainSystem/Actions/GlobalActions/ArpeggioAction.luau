-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

-- ArpeggioAction Module
local ArpeggioAction = {}
ArpeggioAction.__index = ArpeggioAction

-- Helper function to enable and disable parts
local function activateParts(fountainSection, partNamePrefix, partsToActivate)
	for _, part in ipairs(partsToActivate) do
		local partInstance = fountainSection:FindFirstChild(partNamePrefix .. part)
		if partInstance and partInstance:FindFirstChild("Water") then
			partInstance.Water.Enabled = true
			UtilityModule.disableParticle(fountainSection.Name, partInstance.Water)
		end
	end
end

-- Constructor
function ArpeggioAction:new(config)
	local instance = setmetatable({}, ArpeggioAction)

	-- Assign config properties
	instance.fountainSection = config.FountainSection
	instance.delayBetween = config.DelayBetween
	instance.partNamePrefix = config.PartNamePrefix
	instance.customPartSelectionEnabled = config.CustomPartSelectionEnabled
	instance.customPartSelectionInterval = config.CustomPartSelectionInterval
	instance.partGroupingEnabled = config.PartGroupingEnabled
	instance.partGroupingSize = config.PartGroupingSize
	instance.partGroupProcessingMode = config.PartGroupProcessingMode
	instance.partGroupStep = config.PartGroupStep or 1
	instance.loopCode = config.LoopCode
	instance.loopCodeDuration = config.LoopCodeDuration

	-- Retrieve fountain parts
	instance.fountainParts = UtilityModule.getParts(
		instance.fountainSection,
		instance.customPartSelectionEnabled,
		instance.customPartSelectionInterval,
		instance.partNamePrefix
	)

	instance.fountainPartsAmount = UtilityModule.getLengthOfDictionary(instance.fountainParts)
	instance.endTime = instance.loopCode and time() + instance.loopCodeDuration or nil

	return instance
end

-- Main loop function
function ArpeggioAction:execute()
	if self.partGroupingEnabled then
		local groups = math.ceil(self.fountainPartsAmount / self.partGroupingSize)
		
		print(groups)

		if self.partGroupProcessingMode == "Sequential" then
			-- Process groups sequentially, each group fires one after the other
			for group = 1, groups do
				local startIndex = (group - 1) * self.partGroupingSize + 1
				local endIndex = math.min(group * self.partGroupingSize, self.fountainPartsAmount)

				local partsToActivate = {}
				for i = startIndex, endIndex do
					table.insert(partsToActivate, i)
				end

				activateParts(self.fountainSection, self.partNamePrefix, partsToActivate)
				task.wait(self.delayBetween)
			end

		elseif self.partGroupProcessingMode == "Interleaved" then
			-- Interleaved mode: activate parts based on partGroupStep
			for i = 1, self.partGroupingSize, self.partGroupStep do
				local partsToActivate = {}

				-- Iterate over each group
				for group = 1, groups do
					-- For each group, add the parts based on partGroupStep
					for step = 0, self.partGroupStep - 1 do
						local partIndex = group * self.partGroupingSize - i - step + 1
						if partIndex > 0 and partIndex <= self.fountainPartsAmount then
							table.insert(partsToActivate, partIndex)
						end
					end
				end

				activateParts(self.fountainSection, self.partNamePrefix, partsToActivate)
				task.wait(self.delayBetween)
			end
		end
	else
		-- If no part grouping is enabled, use the custom part selection or default behavior
		local groups = math.ceil(self.fountainPartsAmount / self.customPartSelectionInterval)

		for group = 1, groups do
			local startIndex = (group - 1) * self.customPartSelectionInterval + 1
			local endIndex = math.min(group * self.customPartSelectionInterval, self.fountainPartsAmount)

			local partsToActivate = {}
			for i = startIndex, endIndex do
				table.insert(partsToActivate, i)
			end

			activateParts(self.fountainSection, self.partNamePrefix, partsToActivate)

			if group < groups then
				task.wait(self.delayBetween)
			end
		end
	end
end

-- Execution function
function ArpeggioAction:execute()
	if self.endTime then
		while time() < self.endTime do
			self:mainLoop()
		end
	else
		self:mainLoop()
	end
end

return ArpeggioAction

