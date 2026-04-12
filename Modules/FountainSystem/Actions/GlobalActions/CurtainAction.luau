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

-- CurtainAction Module
local CurtainAction = {}
CurtainAction.__index = CurtainAction

-- Constructor
function CurtainAction:new(config)
	local instance = setmetatable({}, CurtainAction)
	
	InstanceInitialiser.initializeInstance(instance, config)
	instance.middlePartIndex = UtilityModule.isEven(instance.fountainPartsAmount) and (instance.fountainPartsAmount / 2) or ((instance.fountainPartsAmount + 1) / 2)
	
	return instance
end

local function animatePart(fountainSection, water, isClone)
	if not isClone then 
		local waterClone = water.Water:Clone() 
		waterClone.Parent = water  
		water = waterClone
	end
	UtilityModule.disableParticle(fountainSection.Name, water)
end

local function playParticle(instance, part)
	if part then
		local CloneTest = part.Water:Clone()
		CloneTest.Parent = part
		CloneTest.Enabled = true
		UtilityModule.setParticleHeight(instance.fountainSection.Name, CloneTest, instance.particlePower)
		task.delay(.2, function()
			animatePart(instance.fountainSection, CloneTest, true)
		end)
	end
end

local function playAnimation(instance, startIdx, stopIdx, step)
	for num = startIdx, stopIdx, step do
		local part = instance.fountainParts[num]
		if part then
			playParticle(instance, part)
			-- Use sequenceDuration instead of totalDuration
			task.wait(math.abs(instance.sequenceDuration / (instance.middlePartIndex - 1)))
		end
	end
end

local function runNonGroupedAnimation(instance)
	if not instance.isReversed then
		task.spawn(function()
			playAnimation(instance, instance.middlePartIndex - 1, 1, -1)
			task.wait(math.abs(instance.sequenceDuration / (instance.middlePartIndex - 1)))
			animatePart(instance.fountainSection, instance.fountainParts[instance.middlePartIndex])
		end)
		task.spawn(function()
			playAnimation(instance, instance.middlePartIndex + 1, instance.fountainPartsAmount, 1)
		end)
	else
		task.spawn(function()
			playAnimation(instance, 1, instance.middlePartIndex - 1, 1)
			task.wait(math.abs(instance.sequenceDuration / (instance.middlePartIndex - 1)))
			animatePart(instance.fountainSection, instance.fountainParts[instance.middlePartIndex])
		end)
		task.spawn(function()
			playAnimation(instance, instance.fountainPartsAmount, instance.middlePartIndex + 1, -1)
		end)
	end
end

local function playGroupedAnimation(instance)
	local groupSize = math.ceil(instance.fountainPartsAmount / instance.groupCount)
	for groupIndex = 1, instance.groupCount do
		local groupStart = (groupIndex - 1) * groupSize + 1
		local groupEnd = math.min(groupIndex * groupSize, instance.fountainPartsAmount)
		local groupMiddle = UtilityModule.isEven(groupEnd + groupStart) and ((groupEnd + groupStart) / 2) or ((groupEnd + groupStart + 1) / 2)
		task.spawn(function()
			if not instance.isReversed then
				task.spawn(function()
					playAnimation(instance, groupMiddle - 1, groupStart, -1)
					task.wait(math.abs(instance.sequenceDuration / (groupMiddle - 1)))
					playParticle(instance, instance.fountainParts[groupMiddle])
				end)
				task.spawn(function()
					playAnimation(instance, groupMiddle + 1, groupEnd, 1)
				end)
			else
				task.spawn(function()
					playAnimation(instance, groupStart, groupMiddle - 1, 1)
					task.wait(math.abs(instance.sequenceDuration / (groupMiddle)))
					playParticle(instance, instance.fountainParts[groupMiddle])
				end)
				task.spawn(function()
					playAnimation(instance, groupEnd, groupMiddle + 1, -1)
				end)
			end
		end)
	end
end

local function runCurtainAnimation(instance)
	if instance.groupCount then
		playGroupedAnimation(instance)
	else
		runNonGroupedAnimation(instance)
	end
end

function CurtainAction:execute()
	if self.loopDuration then
		local startTime = os.clock()
		while os.clock() - startTime < self.loopDuration do
			runCurtainAnimation(self)
			task.wait(self.sequenceDuration)
		end
	else
		runCurtainAnimation(self)
	end
end


return CurtainAction









