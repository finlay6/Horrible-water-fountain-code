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

	-- Assign config properties
	InstanceInitialiser.initializeInstance(instance, config)

	instance.tweens = {}  -- To keep track of the tweens

	return instance
end

-- Execution function
function AnglePartsAction:execute()
	-- First loop: Apply angle transformation
	for i = 1, self.fountainPartsAmount, 1 do
		local fountainPart = self.fountainParts[i]
		
		local cframe1 = UtilityModule.calculateRotationCFrame(fountainPart, self.centerPosition, self.angleForPart)

		if fountainPart then
			local cframeTween = UtilityModule.createTween(fountainPart, "CFrame", cframe1, self.transitionTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			cframeTween:Play()
			UtilityModule.setParticleHeight(self.fountainSection.Name, fountainPart.Water, self.particlePower)
			fountainPart.Water.Enabled = true
		end
	end

	task.wait(self.durationForAngle)

	-- Second loop: Reset CFrame to original
	if self.resetPositionWhenFinished then
		for i = 1, self.fountainPartsAmount, 1 do
			local fountainPart = self.fountainParts[i]

			if fountainPart then
				local angleCFrame = fountainPart.OriginalCFrame.Value
				local cframeTween = UtilityModule.createTween(fountainPart, "CFrame", angleCFrame, self.transitionTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				cframeTween:Play()
			end
		end
	end
	
	if self.sequenceDuration ~= self.durationForAngle then
		task.wait(self.sequenceDuration - self.durationForAngle)
	end

	if self.deactivateWhenComplete then
		for i = 1, self.fountainPartsAmount, 1 do
			local fountainPart = self.fountainParts[i]

			if fountainPart and self.deactivateWhenComplete then
				UtilityModule.disableParticle(self.fountainSection.Name, fountainPart.Water)
			end
		end
	end
end

return AnglePartsAction
