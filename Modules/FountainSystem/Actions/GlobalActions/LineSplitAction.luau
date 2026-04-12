-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

-- LineSplitAction Module
local LineSplitAction = {}
LineSplitAction.__index = LineSplitAction

-- Constructor
function LineSplitAction:new(config)
	local instance = setmetatable({}, LineSplitAction)

	-- Assign config properties
	instance.fountainSection = config.FountainSection
	instance.partNamePrefix = config.PartNamePrefix
	instance.totalDuration = config.TotalDuration
	instance.transitionDuration = config.TransitionDuration
	instance.delayBetweenParts = config.DelayBetweenParts
	instance.partAngle = config.PartAngle
	instance.disableWhenComplete = config.DisableWhenComplete
	instance.Reverse = config.Reverse

	instance.fountainParts = UtilityModule.getParts(instance.fountainSection, false, nil, instance.partNamePrefix)
	instance.fountainPartsAmount = UtilityModule.getLengthOfDictionary(instance.fountainParts)

	instance.midPoint = instance.fountainPartsAmount / 2

	instance.easingStyle = Enum.EasingStyle.Quad
	instance.easingDirection = Enum.EasingDirection.Out

	return instance
end

-- Function to activate water and create the tween animation for a part
local function activatePart(fountainSection, fountainPart, finalCFrame, transitionDuration, easingStyle, easingDirection)
	local water = fountainPart.Water
	water.Enabled = true
	UtilityModule.setParticleHeight(fountainSection.Name, water)

	local tween = UtilityModule.createTween(fountainPart, "CFrame", finalCFrame, transitionDuration, easingStyle, easingDirection)
	tween:Play()
end

-- Main execution function
function LineSplitAction:execute()
	-- First half of fountain parts
	task.spawn(function()
		for loop = self.midPoint, 1, -1 do
			local fountainPart = self.fountainParts[loop]
			local cframeAngle = self.Reverse and -self.partAngle or self.partAngle
			local finalCFrame = fountainPart.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(cframeAngle))

			activatePart(self.fountainSection, fountainPart, finalCFrame, self.transitionDuration, self.easingStyle, self.easingDirection)
			task.wait(self.delayBetweenParts)
		end
	end)

	-- Second half of fountain parts
	task.spawn(function()
		for loop = self.midPoint + 1, self.fountainPartsAmount do
			local fountainPart = self.fountainParts[loop]
			local cframeAngle = self.Reverse and self.partAngle or -self.partAngle
			local finalCFrame = fountainPart.OriginalCFrame.Value * CFrame.Angles(0, 0, math.rad(cframeAngle))

			activatePart(self.fountainSection, fountainPart, finalCFrame, self.transitionDuration, self.easingStyle, self.easingDirection)
			task.wait(self.delayBetweenParts)
		end
	end)

	-- Disable water when complete
	task.delay(self.totalDuration, function()
		if self.disableWhenComplete then
			for _, fountainPart in ipairs(self.fountainParts) do
				UtilityModule.disableParticle(self.fountainSection.Name, fountainPart.Water)
			end
		end
	end)
end

return LineSplitAction







