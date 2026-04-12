-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- AnglePartsAction Module
local AnglePartsAction = {}
AnglePartsAction.__index = AnglePartsAction

-- Constructor
function AnglePartsAction:new(config)
	local instance = setmetatable({}, AnglePartsAction)

	instance = InstanceInitialiser.initializeInstance(instance, config)

	return instance
end

-- Execution function
function AnglePartsAction:execute()
	local tweenDuration = self.transitionTime
	local angleDuration = self.angleDuration  -- Duration the parts hold the angled CFrame
	local totalDuration = self.sequenceDuration
	local groupProcessingMode = self.groupProcessingMode  -- e.g. "LayeredConverge"
	local groupSize = self.groupSize or self.fountainPartsAmount  -- default: one group (all parts)
	local totalParts = self.fountainPartsAmount
	local allParts = self.fountainParts
	local loopCount = self.loopCodeDuration or 1
	local leftToRight = self.leftToRight
	local partDelay = self.partDelayTime

	-- Helper: Create and play tween for a part with a given angle (in degrees)
	local function applyAngleTween(part, angle)
		local targetCFrame = self.xAxis and part.OriginalCFrame.Value * CFrame.Angles(math.rad(angle), 0, 0) or part.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(angle))
		local tween = UtilityModule.createTween(part, "CFrame", targetCFrame, tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		tween:Play()
	end
	
	if groupProcessingMode == "Staggered" then
		local startIndex, endIndex, step = 1, totalParts, groupSize
		if not leftToRight then
			startIndex, endIndex, step = totalParts, 1, -groupSize
		end

		for i = startIndex, endIndex, step do
			local lastIndex = math.min(i + groupSize - 1, totalParts)

			for j = i, lastIndex do
				applyAngleTween(allParts[j], self.angleForPart)
			end

			task.wait(partDelay)
		end
		
	else if groupProcessingMode == "LayeredConverge" then
		local halfGroup = math.floor(groupSize / 2)

		for i = 1, totalParts, groupSize do
			local lastIndex = math.min(i + groupSize - 1, totalParts)

			for j = i + 1, lastIndex - 1 do
				local part = allParts[j]
				local midPoint = i + halfGroup
				
				if j < midPoint then
					applyAngleTween(part, self.angleForPart)
				else
					applyAngleTween(part, -self.angleForPart)
				end
			end
		end
	else
		for _, part in ipairs(allParts) do
			applyAngleTween(part, self.angleForPart)
			end
		end
	end 
	

	-- Second phase: Reset each part's CFrame to its original value
	if angleDuration ~= -1 then
		task.wait(angleDuration)

		for _, part in ipairs(self.fountainParts) do
			if part then
				local resetTween = UtilityModule.createTween(part, "CFrame", part.OriginalCFrame.Value, tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				resetTween:Play()
			end
		end

		-- Third phase: Disable particles if required
		if self.deactivateWhenComplete then
			task.wait(totalDuration - angleDuration)
			
			for _, part in ipairs(self.fountainParts) do
				if part and self.deactivateWhenComplete then
					UtilityModule.disableParticle(self.fountainSection.Name, part.Water)
				end
			end
		end
	end
end


return AnglePartsAction


