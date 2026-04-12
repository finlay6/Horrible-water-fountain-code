-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local InstanceInitialiser = require(utilityModules.InstanceInitializer)
local UtilityModule = require(utilityModules.UtilityModule)

-- FireGroupAction Module
local FireGroupAction = {}
FireGroupAction.__index = FireGroupAction

-- Constructor
function FireGroupAction:new(config)
	local instance = setmetatable({}, FireGroupAction)

	-- Assign config properties
	instance.fountainSection = config.FountainSection
	instance.sequenceDuration = config.SequenceDuration

	instance.lastFireFolder = nil

	return instance
end

-- Function to activate or deactivate a fire group
function FireGroupAction:activateFireFolder(fireFolder, active)
	for _, part in fireFolder:GetChildren() do
		local emitter = part:FindFirstChildWhichIsA("ParticleEmitter")
		local light = part:FindFirstChildWhichIsA("PointLight") or part:FindFirstChildWhichIsA("SurfaceLight")
		if emitter then
			emitter.Enabled = active
			

			task.spawn(function()
				task.wait(0.2)
				if light then
					-- If activating the light, tween brightness from 0 to 10
					if active then
						light.Enabled = true
						light.Brightness = 0  -- Start with brightness 0

						-- Create a tween to animate the brightness from 0 to 10 over 1 second
						local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
						local goal = { Brightness = 10 }
						local tween = TweenService:Create(light, tweenInfo, goal)
						tween:Play()
					else
						-- If deactivating the light, tween brightness from 10 to 0
						local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
						local goal = { Brightness = 0 }
						local tween = TweenService:Create(light, tweenInfo, goal)

						-- Play the tween to reduce brightness to 0, and then disable the light after the tween completes
						tween:Play()
						tween.Completed:Connect(function()
							light.Enabled = false
						end)
					end
				end
			end)
		end
	end
end

-- Main execution function
function FireGroupAction:execute()
	self:activateFireFolder(self.fountainSection, true)
	
	task.wait(self.sequenceDuration)
	
	self:activateFireFolder(self.fountainSection, false)
end

return FireGroupAction





