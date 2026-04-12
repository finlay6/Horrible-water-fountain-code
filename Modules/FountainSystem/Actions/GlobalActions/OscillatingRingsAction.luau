-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local InstanceInitialiser = require(utilityModules.InstanceInitializer)
local UtilityModule = require(utilityModules.UtilityModule)

-- OscillatingRingsAction Module
local OscillatingRingsAction = {}
OscillatingRingsAction.__index = OscillatingRingsAction

-- Constructor
function OscillatingRingsAction:new(config)
	local instance = setmetatable({}, OscillatingRingsAction)
	
	InstanceInitialiser.initializeInstance(instance, config)
	
	return instance
end

-- Execution function
function OscillatingRingsAction:execute()
	-- Start tween animations
	for _, fountainPart in ipairs(self.fountainParts) do
		local water = fountainPart.Water

		local cframe1 = UtilityModule.calculateRotationCFrame(fountainPart, self.centerPosition, self.partAngle)
		local cframe2 = UtilityModule.calculateRotationCFrame(fountainPart, self.centerPosition, -self.partAngle)

		fountainPart.CFrame = cframe1

		local partCFrameTween = UtilityModule.createTween(
			fountainPart, 
			"CFrame", 
			cframe1, 
			self.transitionTime, 
			Enum.EasingStyle.Quad, 
			Enum.EasingDirection.In
		)

		local partCFrameTween2 = UtilityModule.createTween(
			fountainPart, 
			"CFrame", 
			cframe2, 
			self.transitionTime, 
			Enum.EasingStyle.Quad, 
			Enum.EasingDirection.In
		)
		
		water.Enabled = true
		UtilityModule.setParticleHeight(self.fountainSection.Name, water, self.particlePower)

		task.spawn(function()
			local endTime = time() + self.sequenceDuration
			while time() < endTime do
				partCFrameTween2:Play()
				partCFrameTween2.Completed:Wait()
				
				if time() > endTime then break end

				partCFrameTween:Play()
				partCFrameTween.Completed:Wait()
			end
			print(water)
			UtilityModule.disableParticle(self.fountainSection.Name, fountainPart.Water)
		end)
	end
end

return OscillatingRingsAction




