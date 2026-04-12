-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- MidpointParticlesAction Module
local MidpointParticlesAction = {}
MidpointParticlesAction.__index = MidpointParticlesAction

-- Constructor
function MidpointParticlesAction:new(config)
	local instance = setmetatable({}, MidpointParticlesAction)
	
	print(config)
	instance = InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

-- Function to execute midpoint particle actions
function MidpointParticlesAction:execute()
	if self.weirdPoint then
		local fountainParts = UtilityModule.getParts(self.fountainSection, false, nil, self.partNamePrefix, nil)
		local fountainPartsLength = UtilityModule.getLengthOfDictionary(fountainParts) 

		-- Dictionary to store part data with Right value
		local partData = {}
		local midPointGroups = {}

		-- Populate the dictionary with Right values for each part
		for i = 1, fountainPartsLength do
			local partIndex = (i - 1) % self.everyCertainGroupNumber + 1
			local right = partIndex <= self.everyCertainGroupNumber / 2
			partData[i] = { Part = fountainParts[i], Right = right }
		end

		for i = 1, fountainPartsLength, self.everyCertainGroupNumber do
			if i + self.everyCertainGroupNumber - 1 <= fountainPartsLength then
				local midPoint = nil

				-- Calculate midpoint for the current group
				if not self.reversed then
					-- Normal mode: calculate the midpoint of the first and last parts in the group
					local firstPart = fountainParts[i]
					local lastPart = fountainParts[i + self.everyCertainGroupNumber - 1]

					local pos1 = firstPart.OriginalPosition.Value
					local pos2 = lastPart.OriginalPosition.Value

					-- Calculate the midpoint and adjust height
					midPoint = (pos1 + pos2) / 2
					midPoint += Vector3.new(0, self.heightAdjustment, 0)

					-- Adjust each part in the current group when not reversed
					for j = 1, self.everyCertainGroupNumber do
						local currentPartData = partData[i + j - 1]
						local currentPart = currentPartData.Part

						if midPoint then
							currentPart.CFrame = UtilityModule.calculateRotationCFrame(currentPart, midPoint, self.degrees)
							currentPart.Water.Enabled = true
							UtilityModule.setParticleHeight(self.fountainSection.Name, currentPart.Water, self.particlePower, self.lifeTime, self.fountainFadeInTime)
						else
							UtilityModule.disableParticle(self.fountainSection.Name, currentPart.Water)
						end
					end

				else
					-- Reversed mode: Calculate midpoints for new groups and switch directions
					local groupStart = i
					local groupEnd = i + self.everyCertainGroupNumber - 1

					-- Iterate through each part in the group
					for j = 1, self.everyCertainGroupNumber do
						local currentPartData = partData[groupStart + j - 1]
						local currentPart = currentPartData.Part
						local right = currentPartData.Right
						local validMidPoint

						-- Determine the range for the new midpoints
						local partIndex = groupStart + j - 1
						local newGroupStart = (right and (groupStart - self.everyCertainGroupNumber - (self.everyCertainGroupNumber / 2))) or groupEnd + 1 + (self.everyCertainGroupNumber / 2)
						local newGroupEnd = (right and (groupStart - 1 - (self.everyCertainGroupNumber / 2))) or (groupEnd + self.everyCertainGroupNumber + (self.everyCertainGroupNumber / 2))

						if newGroupStart > 0 and newGroupEnd <= fountainPartsLength then
							local newMidFirstPart = fountainParts[newGroupStart]
							local newMidLastPart = fountainParts[newGroupEnd]

							local newPos1 = newMidFirstPart.OriginalPosition.Value
							local newPos2 = newMidLastPart.OriginalPosition.Value

							-- Calculate the midpoint of the new group
							validMidPoint = (newPos1 + newPos2) / 2
							validMidPoint += Vector3.new(0, self.heightAdjustment, 0)

							midPointGroups[newGroupStart] = { FirstNumber = newGroupStart, LastNumber = newGroupEnd, midPoint = validMidPoint }
						else
							validMidPoint = nil
						end
					end

					for num = 1, fountainPartsLength do
						local currentPart = fountainParts[num]
						local water2 = currentPart.Water

						local on = false

						for _, properties in pairs(midPointGroups) do
							local firstNumber = properties.FirstNumber
							local lastNumber = properties.LastNumber
							local validMidPoint = properties.midPoint

							if num >= firstNumber and num <= lastNumber then
								UtilityModule.createTween(currentPart, "CFrame", UtilityModule.calculateRotationCFrame(currentPart, validMidPoint, self.degrees), 2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out):Play()
								currentPart.Water.Enabled = true
								UtilityModule.setParticleHeight(self.fountainSection.Name, currentPart.Water, self.particlePower, self.lifeTime, self.fountainFadeInTime)
								on = true
							else
								if not on then
									currentPart.Water.Enabled = false
									currentPart.CFrame = currentPart.OriginalCFrame.Value
								end
							end
						end
					end
				end
			end
		end
	else
		local loopStartAndStep = self.everyCertain and self.everyCertainNumber or 1

		-- Enable and animate particles in pairs
		if self.inverted then
			for i = loopStartAndStep, fountainPartsLength, loopStartAndStep do
				local fountainPart1 = fountainParts[i]
				local water1 = fountainPart1.Water

				if i - loopStartAndStep <= fountainPartsLength then
					local fountainPart2 = fountainParts[i - loopStartAndStep]
					local water2 = fountainPart2.Water

					local endSpeed = UtilityModule.getParticleHeight(self.fountainSection.Name, water1, self.particlePower)

					water1.Enabled = true
					water2.Enabled = true
					
					UtilityModule.setParticleHeight(self.fountainSection.Name, water1, self.particlePower, self.lifeTime, self.fountainFadeInTime)
					UtilityModule.setParticleHeight(self.fountainSection.Name, water2, self.particlePower, self.lifeTime, self.fountainFadeInTime)

					if self.fadeInSpeed then
						water1.Speed = NumberRange.new(0)
						water2.Speed = NumberRange.new(0)

						UtilityModule.SuperTween.new(water1, TweenInfo.new(self.fadeInTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), { Speed = endSpeed }):Play()
						UtilityModule.SuperTween.new(water2, TweenInfo.new(self.fadeInTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), { Speed = endSpeed }):Play()
					end

					task.delay(self.delayBefore, function()
						local pos1 = fountainPart1.OriginalPosition.Value
						local pos2 = fountainPart2.OriginalPosition.Value

						-- Calculate the midpoint and adjust height
						local midPoint = (pos1 + pos2) / 2
						midPoint = midPoint + Vector3.new(0, self.heightAdjustment, 0)

						-- Create tweens for part rotations
						local lookAt1 = CFrame.lookAt(pos1, midPoint)
						local lookAt2 = CFrame.lookAt(pos2, midPoint)

						UtilityModule.createTween(fountainPart1, "CFrame", lookAt1, self.fadeInTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out):Play()
						UtilityModule.createTween(fountainPart2, "CFrame", lookAt2, self.fadeInTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out):Play()
					end)
				end
			end
		else
			for i = 1, self.fountainPartsAmount, 2 do
				local fountainPart1 = self.fountainParts[i]
				local water1 = fountainPart1.Water

				if i + 1 <= self.fountainPartsAmount then
					local fountainPart2 = self.fountainParts[i + 1]
					local water2 = fountainPart2.Water

					local endSpeed = UtilityModule.getParticleHeight(self.fountainSection.Name, water1, self.particlePower)

					water1.Enabled = true
					water2.Enabled = true
					
					print(self)
					UtilityModule.setParticleHeight(self.fountainSection.Name, water1, self.particlePower, self.lifeTime, self.fountainFadeInTime)
					UtilityModule.setParticleHeight(self.fountainSection.Name, water2, self.particlePower, self.lifeTime, self.fountainFadeInTime)

					if self.fadeInSpeed then
						water1.Speed = NumberRange.new(0)
						water2.Speed = NumberRange.new(0)

						UtilityModule.SuperTween.new(water1, TweenInfo.new(self.fadeInTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), { Speed = endSpeed }):Play()
						UtilityModule.SuperTween.new(water2, TweenInfo.new(self.fadeInTime, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), { Speed = endSpeed }):Play()
					end

					task.delay(self.delayBefore, function()
						-- Get the raw positions
						local base1 = fountainPart1.OriginalPosition.Value
						local base2 = fountainPart2.OriginalPosition.Value

						-- Average X and Z only
						local midX = (base1.X + base2.X) / 2
						local midZ = (base1.Z + base2.Z) / 2

						-- Pick a Y (e.g. average or one part) plus any heightOffset
						local midY = ((base1.Y + base2.Y) / 2)
						-- or if you don’t care about differing Y’s, just:
						-- local midY = base1.Y + self.heightOffset

						local midPoint = Vector3.new(midX, midY, midZ)

						-- Then feed that into your tween calls:
						UtilityModule.createTween(
							fountainPart1, "CFrame",
							UtilityModule.calculateRotationCFrame(fountainPart1, midPoint, self.angleForPart,  self.angleForPart),
							self.fadeInTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out
						):Play()

						UtilityModule.createTween(
							fountainPart2, "CFrame",
							UtilityModule.calculateRotationCFrame(fountainPart2, midPoint, self.angleForPart, -self.angleForPart),
							self.fadeInTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out
						):Play()
					end)
				end
			end
		end

		if self.straightUpWhenStop then
			local endtime = time() + self.totalDuration

			task.spawn(function()
				while true do
					task.wait()

					if time() >= endtime then
						break
					end
				end

				for _, part2 in ipairs(fountainParts) do
					UtilityModule.createTween(part2, "CFrame", part2.OriginalCFrame.Value, self.fadeInTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out):Play()
				end
			end)
		end
	end
end

return MidpointParticlesAction







