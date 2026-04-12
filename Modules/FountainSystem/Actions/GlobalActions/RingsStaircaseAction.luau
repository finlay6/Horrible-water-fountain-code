-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

-- RingsStaircaseAction Module
local RingsStaircaseAction = {}
RingsStaircaseAction.__index = RingsStaircaseAction

-- Constructor
function RingsStaircaseAction:new(config)
	local instance = setmetatable({}, RingsStaircaseAction)

	-- Assign config properties
	instance.fountainSection = config.FountainSection
	instance.partAngle = config.PartAngle
	instance.totalDuration = config.TotalDuration
	instance.partNamePrefix = config.PartNamePrefix
	instance.particlePower = config.ParticlePower
	instance.delayTimeBetweenParts = config.DelayTimeBetweenParts
	instance.leftToRight = config.LeftToRight
	instance.totalStaircases = config.TotalStaircases
	instance.centerPosition = config.CenterPosition

	-- Get fountain parts
	instance.fountainParts = UtilityModule.getParts(instance.fountainSection, false, 0, instance.partNamePrefix)
	instance.fountainPartsAmount = UtilityModule.getLengthOfDictionary(instance.fountainParts)

	instance.loopStart = instance.leftToRight and 1 or instance.fountainPartsAmount
	instance.loopEnd = instance.leftToRight and instance.fountainPartsAmount or 1
	instance.loopStep = instance.leftToRight and 1 or -1
	instance.tweenDuration = instance.totalDuration

	instance.tweens = {}
	instance.endTime = time() + instance.totalDuration

	return instance
end

-- Execution function
function RingsStaircaseAction:execute()
	local waveFrequency = math.pi / self.tweenDuration  -- Frequency to complete motion in half-cycle
	local timeElapsed = 0 -- Renamed to avoid conflicts with elapsedTime function
	local startTime = time()

	-- Main loop for smooth circular motion
	task.spawn(function()
		while time() < self.endTime do
			timeElapsed = time() - startTime

			-- Calculate XRotation and ZRotation within specified ranges
			local xRotation = 25 * math.cos(timeElapsed * waveFrequency) -- Oscillates from 45 to -45
			local zRotation = 7.5 * math.sin(timeElapsed * waveFrequency) - 5 -- Oscillates from 10 to -5 to 10

			-- Update each part's CFrame for smooth rotation
			for i = self.loopStart, self.loopEnd, self.loopStep do
				local thisFountainPart = self.fountainParts[i]
				local water = thisFountainPart.Water

				-- Calculate the rotation relative to centerPosition
				local targetCFrame = UtilityModule.calculateRotationCFrame(thisFountainPart, self.centerPosition, zRotation, xRotation)

				-- Apply the calculated CFrame
				thisFountainPart.CFrame = targetCFrame

				-- Enable particles during motion
				water.Enabled = true
				UtilityModule.setParticleHeight(self.fountainSection.Name, water, self.particlePower)
			end

			-- Control update frequency for smoothness
			task.wait(0.03) -- Smooth update interval
		end

		-- Reset parts and disable particles at end
		for i = self.loopStart, self.loopEnd, self.loopStep do
			local thisFountainPart = self.fountainParts[i]
			thisFountainPart.Water.Enabled = false
			thisFountainPart.CFrame = thisFountainPart.OriginalCFrame.Value
		end
	end)

end

return RingsStaircaseAction


