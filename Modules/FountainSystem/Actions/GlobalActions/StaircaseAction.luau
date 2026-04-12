-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

-- StaircaseAction Module
local StaircaseAction = {}
StaircaseAction.__index = StaircaseAction

local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- Constructor
function StaircaseAction:new(config)
	local instance = setmetatable({}, StaircaseAction)
	
	instance = InstanceInitialiser.initializeInstance(instance, config)
	
	-- Assign config properties

	instance.loopStart = instance.isLeftToRightMotion and 1 or instance.fountainPartsAmount
	instance.loopEnd = instance.isLeftToRightMotion and instance.fountainPartsAmount or 1
	instance.loopStep = instance.isLeftToRightMotion and 1 or -1
	instance.tweenDuration = instance.sequenceDuration / instance.totalStaircases

	instance.tweens = {}
	instance.endTime = time() + instance.sequenceDuration

	return instance
end

-- Execution function
function StaircaseAction:execute()
	for i = self.loopStart, self.loopEnd, self.loopStep do
		local thisFountainPart = self.fountainParts[i]
		local water = thisFountainPart.Water

		if self.groupSize then
			-- Group-based motion
			for groupStart = self.loopStart, self.loopEnd, self.groupSize do
				-- Loop through each part in the group
				for j = groupStart, math.min(groupStart + self.groupSize - 1, self.loopEnd) do
					local thisFountainPart = self.fountainParts[j]
					local water = thisFountainPart.Water

					-- Create CFrames for grouped motion
					local firstCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(math.rad(self.isLeftToRightMotion and -self.angleForPart or self.angleForPart), 0, 0)
					local secondCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(math.rad(self.isLeftToRightMotion and self.angleForPart or -self.angleForPart), 0, 0)

					-- Create the tweens for this part
					local firstTween = UtilityModule.createTween(thisFountainPart, "CFrame", firstCFrame, self.tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
					local secondTween = UtilityModule.createTween(thisFountainPart, "CFrame", secondCFrame, self.tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

					-- Enable water particles
					water.Enabled = true
					UtilityModule.setParticleHeight(self.fountainSection.Name, thisFountainPart.Water, self.particlePower)

					-- Start motion for the part
					task.spawn(function()
						while time() < self.endTime do
							secondTween:Play()
							secondTween.Completed:Wait()

							firstTween:Play()
							firstTween.Completed:Wait()
						end

						firstTween:Cancel()
						secondTween:Cancel()
						if self.deactivateWhenComplete then
							water.Enabled = false
						end

						if self.resetPositionWhenFinished then
							thisFountainPart.CFrame = thisFountainPart.OriginalCFrame.Value
						end
					end)
				end

				-- Wait for the group duration before processing the next group
				task.wait(self.tweenDuration)
			end
		else
			-- Original non-group logic (per-part motion)
			-- Create CFrames for the staircase motion
			local firstCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(math.rad(self.isLeftToRightMotion and -self.angleForPart or self.angleForPart), 0, 0)
			local secondCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(math.rad(self.isLeftToRightMotion and self.angleForPart or -self.angleForPart), 0, 0)

			-- Apply the first CFrame
			thisFountainPart.CFrame = firstCFrame

			-- Create the tweens for the CFrame transitions
			local firstTween = UtilityModule.createTween(thisFountainPart, "CFrame", firstCFrame, self.tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			local secondTween = UtilityModule.createTween(thisFountainPart, "CFrame", secondCFrame, self.tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

			-- Store the tweens
			table.insert(self.tweens, firstTween)
			table.insert(self.tweens, secondTween)

			-- Enable the water particles and set their height
			water.Enabled = true
			UtilityModule.setParticleHeight(self.fountainSection.Name, thisFountainPart.Water, self.particlePower)

			-- Play the tweens sequentially with a loop until the end time
			task.spawn(function()
				while time() < self.endTime do
					secondTween:Play()
					secondTween.Completed:Wait()

					firstTween:Play()
					firstTween.Completed:Wait()
				end

				-- Stop and reset the particles when the loop is finished
				firstTween:Cancel()
				secondTween:Cancel()
				if self.deactivateWhenComplete then
					water.Enabled = false
				end
				
				if self.resetPositionWhenFinished then
					thisFountainPart.CFrame = thisFountainPart.OriginalCFrame.Value
				end
			end)

			-- Delay for the next part
			task.wait(self.partDelayTime)
		end
	end

end

return StaircaseAction



