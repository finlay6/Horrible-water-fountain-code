-- // Services \\ --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local SuperTween = require(ReplicatedStorage.Classes.SuperTween)

local InstanceInitialiser = require(utilityModules.InstanceInitializer)

local SongSpecificAction = {}
SongSpecificAction.__index = SongSpecificAction

function SongSpecificAction:new(config)
	local instance = setmetatable({}, SongSpecificAction)


	InstanceInitialiser.initializeInstance(instance, config)

	instance.currentStartTime = time()
	instance.totalEndTime = time() + instance.sequenceDuration
	instance.backAndForthEndTime = time() + instance.backAndForthDuration

	return instance
end

local function swayPart(part, firstCFrame, secondCFrame, transitionDuration, water, reversed, backAndForthEndTime, totalEndTime, fountainSection, disabledWhenStop, resetPositionWhenFinished)
	task.spawn(function()
		while time() < backAndForthEndTime do
			if reversed then
				local secondTween = UtilityModule.createTween(part, "CFrame", secondCFrame, transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
				secondTween:Play()
				secondTween.Completed:Wait()

				local firstTween = UtilityModule.createTween(part, "CFrame", firstCFrame, transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
				firstTween:Play()
				firstTween.Completed:Wait()
			else
				local firstTween = UtilityModule.createTween(part, "CFrame", firstCFrame, transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
				firstTween:Play()
				firstTween.Completed:Wait()

				local secondTween = UtilityModule.createTween(part, "CFrame", secondCFrame, transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
				secondTween:Play()
				secondTween.Completed:Wait()
			end
		end

		if resetPositionWhenFinished then
			local finalTween = UtilityModule.createTween(part, "CFrame", part.OriginalCFrame.Value, transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			finalTween:Play()
		end

		task.wait(totalEndTime - time())

		if disabledWhenStop then
			UtilityModule.disableParticle(fountainSection.Name, water)
		else
			if resetPositionWhenFinished then
				part.CFrame = part.OriginalCFrame.Value
			end
		end
	end)
end

local function customSequence(instance)
	local fountainParts = instance.fountainParts
	local fountainPartsAmount = instance.fountainPartsAmount
	local transitionDuration = instance.transitionTime
	local fountainSection = instance.fountainSection

	-- Step 1: Transition to X Pattern
	for i = 1, fountainPartsAmount do
		local part = fountainParts[i]
		part.Water.Enabled = true
		local xPatternCFrame = part.OriginalCFrame.Value * (i % 2 == 0 and CFrame.Angles(0, 0, math.rad(30)) or CFrame.Angles(0, 0, math.rad(-30)))
		UtilityModule.createTween(part, "CFrame", xPatternCFrame, transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut):Play()
	end

	-- Step 2: Start swaying in X pattern after 1 second
	task.delay(1, function()
		for i = 1, fountainPartsAmount do
			local part = fountainParts[i]
			part.Water.Enabled = true
			local swayLeftCFrame = part.OriginalCFrame.Value * (i % 2 == 0 and CFrame.Angles(0, 0, math.rad(45)) or CFrame.Angles(0, 0, math.rad(-5)))
			local swayRightCFrame = part.OriginalCFrame.Value * (i % 2 == 0 and CFrame.Angles(0, 0, math.rad(5)) or CFrame.Angles(0, 0, math.rad(-45)))

			swayPart(part, swayLeftCFrame, swayRightCFrame, transitionDuration, part.Water, false, time() + 6, time() + 6, fountainSection, false, false)
		end
	end)

	-- Step 3: Smooth transitions on three beats
	task.delay(9, function() -- 5 seconds of X sway + 1 second pause
		-- First beat: Move some left nozzles right
		for i = 1, fountainPartsAmount, 3 do
			local part = fountainParts[i]
			part.Water.Enabled = true
			if part then
				local rightCFrame = part.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(-45))
				UtilityModule.createTween(part, "CFrame", rightCFrame, transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut):Play()
			end
		end

		task.delay(1, function()
			-- Second beat: Move additional nozzles
			for i = 2, fountainPartsAmount, 3 do
				local part = fountainParts[i]
				print(part, i, fountainParts)
				part.Water.Enabled = true
				if part then
					local rightCFrame = part.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(-45))
					UtilityModule.createTween(part, "CFrame", rightCFrame, transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut):Play()
				end
			end
		end)

		task.delay(2, function()
			-- Third beat: Move remaining nozzles
			for i = 3, fountainPartsAmount, 3 do
				local part = fountainParts[i]
				print(part)
				part.Water.Enabled = true
				if part then
					local rightCFrame = part.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(-45))
					UtilityModule.createTween(part, "CFrame", rightCFrame, transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut):Play()
				end
			end
		end)
	end)

	-- Step 4: Disable particles after sway
	task.delay(11, function() -- 6 seconds sway + 5 seconds
		for i = 1, fountainPartsAmount do
			local part = fountainParts[i]
			UtilityModule.disableParticle(fountainSection.Name, part.Water)
		end
	end)
end

function SongSpecificAction:execute()
	customSequence(self)
end

return SongSpecificAction
