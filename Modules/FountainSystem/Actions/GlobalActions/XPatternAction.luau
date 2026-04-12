-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- XPatternAction Module
local XPatternAction = {}
XPatternAction.__index = XPatternAction

-- Constructor
function XPatternAction:new(config)
	local instance = setmetatable({}, XPatternAction)
	
	InstanceInitialiser.initializeInstance(instance, config)
	
	instance.tweens = {}
	instance.finalTime = time() + instance.sequenceDuration

	return instance
end

-- Function to perform the X Pattern action
function XPatternAction:execute()
	for i = 1, #self.fountainParts, 2 do
		local fountainPart1, fountainPart2 = self.fountainParts[i], self.fountainParts[i + 1]
		if fountainPart2 then

			UtilityModule.setParticleHeight(self.fountainSection.Name, fountainPart1.Water, self.particlePower)
			UtilityModule.setParticleHeight(self.fountainSection.Name, fountainPart2.Water, self.particlePower)

			local cframe1, cframe2 = fountainPart1.OriginalCFrame.Value, fountainPart2.OriginalCFrame.value
			local midPoint = (fountainPart1.Position + fountainPart2.Position) / 2

			local function createRotTween(part, targetCFrame) 
				return UtilityModule.createTween(part, "CFrame", targetCFrame, self.transitionTime, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			end

			local part1TweenIn = createRotTween(fountainPart1, UtilityModule.calculateRotationCFrame(fountainPart1, midPoint, self.angleOne))
			local part2TweenIn = createRotTween(fountainPart2, UtilityModule.calculateRotationCFrame(fountainPart2, midPoint, self.angleTwo))
			local part1TweenOut = createRotTween(fountainPart1, cframe1)
			local part2TweenOut = createRotTween(fountainPart2, cframe2)

			table.insert(self.tweens, part1TweenIn)
			table.insert(self.tweens, part2TweenIn)
			table.insert(self.tweens, part1TweenOut)
			table.insert(self.tweens, part2TweenOut)
			

			task.delay(self.sequenceDuration, function()
				for _, tween in pairs(self.tweens) do 
					tween:Cancel() 
					tween:Destroy() 
				end
				self.tweens = {}
				if self.resetPositionWhenComplete then
					fountainPart1.CFrame = fountainPart1.OriginalCFrame.Value
					fountainPart2.CFrame = fountainPart2.OriginalCFrame.Value
				end
				if self.disabledWhenStop then 
					UtilityModule.disableParticle(self.fountainSection.Name, fountainPart1.Water)
					UtilityModule.disableParticle(self.fountainSection.Name, fountainPart2.Water)
				end
			end)
			
			fountainPart1.Water.Enabled = true
			fountainPart2.Water.Enabled = true

			task.spawn(function()
				local finalTime = time() + self.backAndForthDuration
				while time() < finalTime do
					print(1)
					part1TweenIn:Play() 
					part2TweenIn:Play()
					part1TweenIn.Completed:Wait()
					part1TweenOut:Play() 
					part2TweenOut:Play()
					part1TweenOut.Completed:Wait()
				end
			end)
		end
	end
end

return XPatternAction








