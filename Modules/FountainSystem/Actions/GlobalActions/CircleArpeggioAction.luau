-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

-- CircleArpeggioAction Module
local CircleArpeggioAction = {}
CircleArpeggioAction.__index = CircleArpeggioAction

-- Constructor
function CircleArpeggioAction:new(config)
	local instance = setmetatable({}, CircleArpeggioAction)

	-- Assign config properties
	instance.fountainSection = config.fountainSection
	instance.delayBetween = config.DelayBetween

	return instance
end

-- Function to process each fountain section in order
function CircleArpeggioAction:processFountains()
	local fountainsInOrder = {}

	-- Sort the fountains based on their order value
	for _, fountainSection in self.fountainSection:GetChildren() do
		fountainsInOrder[fountainSection.Order.Value] = fountainSection
	end

	-- Iterate over the ordered fountains and process each one
	for _, thisFountainSection in ipairs(fountainsInOrder) do
		local partNamePrefix = thisFountainSection.PartNamePrefix.Value
		local clockwise = thisFountainSection.Clockwise.Value
		local delayBetweenEachPulse = thisFountainSection.DelayBetweenPulse.Value
		local fountainPartsAmount = #thisFountainSection.Value:GetChildren()

		task.wait(self.delayBetween)

		local loopStart = clockwise and 1 or fountainPartsAmount
		local loopEnd = clockwise and fountainPartsAmount or 1
		local step = clockwise and 1 or -1

		-- Loop through each part of the fountain
		for loop = loopStart, loopEnd, step do
			local fountainPart = thisFountainSection.Value:FindFirstChild(string.format("%s%d", partNamePrefix, loop))
			if fountainPart then
				fountainPart.Water.Enabled = true

				UtilityModule.disableParticle(thisFountainSection.Name, fountainPart.Water)
			end

			task.wait(delayBetweenEachPulse)
		end
	end
end

-- Main execution function
function CircleArpeggioAction:execute()
	self:processFountains()
end

return CircleArpeggioAction





