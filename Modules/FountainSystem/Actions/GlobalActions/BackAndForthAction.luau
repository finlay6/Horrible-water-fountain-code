-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- BackAndForthAction Module
local BackAndForthAction = {}
BackAndForthAction.__index = BackAndForthAction

-- Constructor
function BackAndForthAction:new(config)
	local instance = setmetatable({}, BackAndForthAction)
	
	instance = InstanceInitialiser.initializeInstance(instance, config)
	
	instance.currentStartTime = time()
	instance.totalEndTime = time() + instance.sequenceDuration
	instance.backAndForthEndTime = time() + instance.backAndForthDuration

	return instance
end

-- Helper function to handle the back and forth motion
local function swayPart(part, firstCFrame, secondCFrame, transitionDuration, water, reversed, backAndForthEndTime, totalEndTime, fountainSection, disabledWhenStop, resetPositionWhenFinished)
	task.spawn(function()
		local firstTween
		local secondTween
		
		while time() < backAndForthEndTime do
			if reversed then
				secondTween = UtilityModule.createTween(part, "CFrame", secondCFrame, transitionDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				secondTween:Play()
				secondTween.Completed:Wait()

				firstTween = UtilityModule.createTween(part, "CFrame", firstCFrame, transitionDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				firstTween:Play()
				firstTween.Completed:Wait()
			else
				firstTween = UtilityModule.createTween(part, "CFrame", firstCFrame, transitionDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				firstTween:Play()
				firstTween.Completed:Wait()

				secondTween = UtilityModule.createTween(part, "CFrame", secondCFrame, transitionDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				secondTween:Play()
				secondTween.Completed:Wait()
			end
		end
		
		if resetPositionWhenFinished then
			firstTween:Cancel()
			secondTween:Cancel()
			local finalTween = UtilityModule.createTween(part, "CFrame", part.OriginalCFrame.Value, transitionDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			finalTween:Play()
		end

		task.wait(totalEndTime - time())
		
		if disabledWhenStop then
			print("TRUE???")
			UtilityModule.disableParticle(fountainSection.Name, water)
		end
	end)
end

-- Execution function
function BackAndForthAction:execute()
	if self.GroupSize then
		local currentIndex = 1 -- Tracks the current part being processed

		if self.groupProcessingMode == "Staggered" then
			local groupSize = self.GroupSize
			local totalGroups = math.ceil(self.fountainPartsAmount / groupSize)

			for partIndex = 1, groupSize do
				task.spawn(function()
					for group = 0, totalGroups - 1 do
						local index = group * groupSize + partIndex
						if index <= self.fountainPartsAmount then
							local thisFountainPart = self.fountainParts[index]
							local water = thisFountainPart.Water

							-- Determine rotation axis based on forwardsAndBackwardsMotion
							local firstCFrame, secondCFrame
							if self.forwardsAndBackwardsMotion then
								firstCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(math.rad(self.angleOne), 0, 0)
								secondCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(math.rad(self.angleTwo), 0, 0)
							else
								firstCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(self.angleOne))
								secondCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(self.angleTwo))
							end

							task.spawn(function()
								water.Enabled = true
								UtilityModule.setParticleHeight(self.fountainSection.Name, water, self.particlePower)
								swayPart(
									thisFountainPart,
									firstCFrame,
									secondCFrame,
									self.transitionTime,
									water,
									false,
									self.backAndForthEndTime,
									self.totalEndTime,
									self.fountainSection,
									self.deactivateWhenComplete,
									self.resetPositionWhenFinished
								)
							end)
						end
						task.wait(self.transitionTime)
					end
				end)
			end
			return
		end

		while currentIndex <= self.fountainPartsAmount do
			-- Enable and sway a group of parts
			for column = 1, self.GroupSize do
				if currentIndex <= self.fountainPartsAmount then
					local thisFountainPart = self.fountainParts[currentIndex]
					local water = thisFountainPart.Water

					-- Determine rotation axis based on forwardsAndBackwardsMotion
					local firstCFrame, secondCFrame
					if self.forwardsAndBackwardsMotion then
						firstCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(math.rad(self.angleOne), 0, 0)
						secondCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(math.rad(self.angleTwo), 0, 0)
					else
						firstCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(self.angleOne))
						secondCFrame = thisFountainPart.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(self.angleTwo))
					end

					-- Enable and sway without cumulative delays
					task.spawn(function()
						water.Enabled = true
						swayPart(thisFountainPart, firstCFrame, secondCFrame, self.transitionTime, water, false, self.backAndForthEndTime, self.totalEndTime, self.fountainSection, self.deactivateWhenComplete, self.resetPositionWhenFinished)
					end)

					currentIndex += 1
				end
			end

			-- Disable the in-between parts
			for _ = 1, self.partsBetween do
				if currentIndex <= self.fountainPartsAmount then
					local thisFountainPart = self.fountainParts[currentIndex]
					thisFountainPart.Water.Enabled = false
					currentIndex += 1
				end
			end
		end
	else
		if self.groupProcessingMode == "Staggered" then
			local total = self.fountainPartsAmount

			-- CONFIG: tune these on your object (or set before calling)
			local groupSize    = self.desiredGroupSize    or 5   -- members per group
			local groupsCount  = self.desiredGroupsCount  or math.floor(total / groupSize) -- number of groups to activate
			local bias         = self.groupBias           or "balanced" -- "balanced" | "left" | "right"

			-- compute how many parts should be active (can't exceed total)
			local activeCount = math.min(groupSize * groupsCount, total)
			local disabledTotal = total - activeCount

			-- split disabled parts between left & right, with optional bias for odd remainder
			local leftDisabled = math.floor(disabledTotal / 2)
			local rightDisabled = disabledTotal - leftDisabled
			if bias == "left" then
				leftDisabled = math.ceil(disabledTotal / 2)
				rightDisabled = disabledTotal - leftDisabled
			elseif bias == "right" then
				leftDisabled = math.floor(disabledTotal / 2)
				rightDisabled = disabledTotal - leftDisabled
			end

			local startIndex = leftDisabled + 1
			local endIndex = math.min(startIndex + activeCount - 1, total)

			-- build list of indices that should be enabled (the contiguous middle block)
			local enabledIndices = {}
			for i = startIndex, endIndex do
				table.insert(enabledIndices, i)
			end

			-- ensure disabled parts are turned off
			--for i = 1, total do
			--	local part = self.fountainParts[i]
			--	if part and part.Water then
			--		part.Water.Enabled = false
			--	end
			--end

			-- stagger only over the enabled (middle) parts
			for idx, partIndex in ipairs(enabledIndices) do
				task.spawn(function()
					task.wait((idx - 1) * (self.backAndForthDuration / #enabledIndices))
					local thisFountainPart = self.fountainParts[partIndex]
					if not thisFountainPart then return end
					local water = thisFountainPart.Water
					if water then
						water.Enabled = true
						UtilityModule.setParticleHeight(self.fountainSection.Name, water, self.particlePower)
					end
					swayPart(
						thisFountainPart,
						thisFountainPart.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(self.angleOne)),
						thisFountainPart.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(self.angleTwo)),
						self.transitionTime, water, false, self.backAndForthEndTime, self.totalEndTime, self.fountainSection, self.deactivateWhenComplete, self.resetPositionWhenFinished
					)
				end)
			end

			return
		end

		-- …then in your loop:
		local beginning = self.beginning or (self.customPartSelectionEnabled and self.customPartSelectionInterval) or 1
		local step      = self.customPartSelectionEnabled and self.customPartSelectionInterval or 1
		-- defaults (e.g. in your init)
		self.swayVariance       = self.swayVariance       or 0.1    -- ±2%
		self.minSwayVariance    = self.minSwayVariance    or 0.05    -- at least ±1%
		self.swayVarianceChance = self.swayVarianceChance or 1     -- 90% chance to vary

		-- …inside your for-loop:
		for i = beginning, self.fountainPartsAmount, step do
			local part  = self.fountainParts[i]
			local water = part.Water

			-- decide whether to vary this one
			local swayFactor = 1
			if math.random() < self.swayVarianceChance then
				-- pick a magnitude between min and max
				local mag = self.minSwayVariance
					+ math.random() * (self.swayVariance - self.minSwayVariance)
				-- random sign
				local sign = (math.random() < 0.5) and -1 or 1
				swayFactor = 1 + sign * mag
			end

			-- apply to your two angles
			local a1 = self.angleOne * swayFactor
			local a2 = self.angleTwo * swayFactor

			local currentCFrame = (self.fromCurrentPosition and part.CFrame)
				or part.OriginalCFrame.Value

			local firstCFrame, secondCFrame
			if self.forwardsAndBackwardsMotion then
				firstCFrame  = currentCFrame * CFrame.Angles(math.rad(a1), 0, 0)
				secondCFrame = currentCFrame * CFrame.Angles(math.rad(a2), 0, 0)
			else
				firstCFrame  = currentCFrame * CFrame.Angles(0, 0, math.rad(a1))
				secondCFrame = currentCFrame * CFrame.Angles(0, 0, math.rad(a2))
			end

			water.Enabled = true
			UtilityModule.setParticleHeight(
				self.fountainSection.Name,
				water,
				self.particlePower,
				nil,
				self.heightFadeInTime
			)
			swayPart(
				part,
				firstCFrame,
				secondCFrame,
				self.transitionTime,
				water,
				false,
				self.backAndForthEndTime,
				self.totalEndTime,
				self.fountainSection,
				self.deactivateWhenComplete,
				self.resetPositionWhenFinished
			)
		end

	end
end




return BackAndForthAction

