-- // Services \\ --

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- // Directories \\ -- 

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local Classes = ReplicatedStorage.Classes

-- // Requires \\ --

local SuperTween = require(Classes.SuperTween)
local ParticleConfig = require(utilityModules.ParticleConfig)

-- // Config \\ --

local heights = ParticleConfig.Heights
local defaultPulseTimes = ParticleConfig.DefaultPulseTimes

local UtilityModule = {}

UtilityModule.SuperTween = SuperTween
UtilityModule.heights = heights

function UtilityModule.getParts(fountainSection, partNamePrefix, partLowerBound, partUpperBound, selectionInterval)
	local parts = {}

	if not partNamePrefix then
		warn("Missing partNamePrefix for section: " .. fountainSection.Name)
		return {}
	end

	-- Select parts within bounds
	if partLowerBound and partUpperBound then
		for i = partLowerBound, partUpperBound do
			local part = fountainSection:FindFirstChild(partNamePrefix .. i)
			if part then
				table.insert(parts, part)
			end
		end

		-- Apply selection interval
		if selectionInterval and selectionInterval > 1 then
			local filteredParts = {}
			for i = 1, #parts, selectionInterval do
				table.insert(filteredParts, parts[i])
			end
			return filteredParts
		end

		return parts
	end

	-- Default: Collect all parts in the folder matching the prefix
	for i = 1, #fountainSection:GetChildren(), 1 do
		local part = fountainSection:FindFirstChild(partNamePrefix .. i)
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	return parts
end

function UtilityModule.isEven(number: number)
	return number % 2 == 0
end

function UtilityModule.calculateRotationCFrame(fountainPart, centerPosition, verticalDegrees, horizontalDegrees)
	-- Positions and direction
	local partPos = fountainPart.OriginalPosition.Value
	local toTarget = centerPosition - partPos
	if toTarget.Magnitude == 0 then
		return fountainPart.CFrame
	end
	local dirUnit = toTarget.Unit

	-- Start with CFrame at the part’s position
	local resultCf = CFrame.new(partPos)
	local currentCf = fountainPart.CFrame

	-- 1) Vertical rotation (pitch): rotate up/down to look at the target, clamped by verticalDegrees
	if verticalDegrees and verticalDegrees ~= 0 then
		local upVec = currentCf.UpVector
		local cosAngle = math.clamp(upVec:Dot(dirUnit), -1, 1)
		local rawAngle = math.acos(cosAngle)               -- how much we “must” rotate
		local maxAngle = math.rad(verticalDegrees)         -- clamp in radians
		local angle = math.min(rawAngle, maxAngle)
		local axisRaw = upVec:Cross(dirUnit)
		if axisRaw.Magnitude > 1e-6 then
			local axis = axisRaw.Unit
			resultCf = resultCf * CFrame.fromAxisAngle(axis, angle)
		end
	end

	-- 2) Horizontal rotation (yaw): rotate around world-up to face the target on the XZ plane
	if horizontalDegrees and horizontalDegrees ~= 0 then
		-- Project look direction onto XZ plane
		local lookVec = (currentCf.LookVector * Vector3.new(1, 0, 1)).Unit
		local targetHoriz = (dirUnit * Vector3.new(1, 0, 1))
		if targetHoriz.Magnitude > 0 then
			targetHoriz = targetHoriz.Unit
			local cosH = math.clamp(lookVec:Dot(targetHoriz), -1, 1)
			local rawH = math.acos(cosH)
			local maxH = math.rad(math.abs(horizontalDegrees))
			local angleH = math.min(rawH, maxH)
			-- Determine direction (+ or –) based on sign of horizontalDegrees
			local sign = horizontalDegrees >= 0 and 1 or -1
			-- Y-axis is world-up for yaw
			resultCf = resultCf * CFrame.fromAxisAngle(Vector3.new(0, 1, 0), angleH * sign)
		end
	end

	return resultCf
end

function speedForHeightGetter(height, acceleration)
	local v = 0
	local u
	local s = height
	local a = acceleration
	
	u = math.sqrt((math.pow(v, 2)) - (2 * a * s)) -- v^2 + 2as
	
	return u
end

function UtilityModule.getParticleHeight(fountainName: string, particle: ParticleEmitter, particlePower: number)
	local thisFountainHeight = heights[fountainName]

	if particlePower then
		thisFountainHeight *= (particlePower / 100)
	end
	
	local initalSpeed = speedForHeightGetter(thisFountainHeight, particle.Acceleration.Y)

	local finalSpeed = NumberRange.new(initalSpeed - 10, initalSpeed)
	
	return finalSpeed
end

function UtilityModule.setParticleHeight(fountainName: string, particle: ParticleEmitter, particlePower: number, lifetime: number, fadeInTime: number)
	local thisFountainHeight = heights[fountainName]

	if particlePower then
		thisFountainHeight *= (particlePower / 100)
	end

	local initalSpeed = speedForHeightGetter(thisFountainHeight, particle.Acceleration.Y)

	local finalSpeed = NumberRange.new(initalSpeed - 10, initalSpeed)
	
	if fadeInTime and fadeInTime ~= 0 then
		particle.Speed = NumberRange.new(0, 0)
		local tween = SuperTween.new(particle, TweenInfo.new(fadeInTime), {Speed = finalSpeed})
		tween:Play()
	else
		particle.Speed = finalSpeed
	end
	
	particle.Lifetime = lifetime and NumberRange.new(lifetime) or NumberRange.new(2)
end

function UtilityModule.createTween(target, property, endValue, duration, EasingStyle, EasingDirection)
	duration = tonumber(duration)
	local tweenInfo = TweenInfo.new(duration, EasingStyle, EasingDirection)
	local goal = {[property] = endValue}
	local tween = TweenService:Create(target, tweenInfo, goal)
	return tween
end

function UtilityModule.disableParticle(fountainName: string, particle: Water)
	local pulseTime = defaultPulseTimes[fountainName]

	if not pulseTime then
		particle.Enabled = false
		return
	end

	local tweenInfo = TweenInfo.new(pulseTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenGoal = {Speed = NumberRange.new(0, 0)}

	local speedTween = SuperTween.new(particle, tweenInfo, tweenGoal)
	speedTween:Play()

	speedTween.Completed:Once(function()
		particle.Enabled = false

		task.wait(0.1)
		
		local initalSpeed = speedForHeightGetter(heights[fountainName], particle.Acceleration.Y)

		particle.Speed = NumberRange.new(initalSpeed - 10, initalSpeed)
		particle.Parent.CFrame = particle.Parent.OriginalCFrame.Value
	end)

	return speedTween
end

function UtilityModule.fadeInParticle(fountainName, particle, transitionDuration, particlePower)
	local thisFountainHeight = heights[fountainName]

	if particlePower then
		thisFountainHeight *= (particlePower / 100)
	end

	local initalSpeed = speedForHeightGetter(thisFountainHeight, particle.Acceleration.Y)

	local finalSpeed = NumberRange.new(initalSpeed - 10, initalSpeed)

	particle.Speed = NumberRange.new(0,0)

	particle.Enabled = true

	local tweenInfo = TweenInfo.new(transitionDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenGoal = {Speed = finalSpeed}

	local speedTween = SuperTween.new(particle, tweenInfo, tweenGoal)
	speedTween:Play()

	return speedTween
end

function UtilityModule.getLengthOfDictionary(dictionary)
	local i = 0

	for index, value in dictionary do
		i += 1
	end

	return i
end

function UtilityModule.getFountainPartAmount(fountainParts)
	local biggest = 0

	for index, _ in fountainParts do
		if index > biggest then
			biggest = index
		end
	end

	return biggest
end

return UtilityModule

