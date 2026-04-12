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
	instance.delayBetweenGroups = config.DelayBetweenGroups
	instance.fireGroupAmount = config.FireGroupCount
	instance.leftToRight = config.LeftToRight
	instance.repeatTime = config.RepeatTime

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
		end
		
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

-- Function to trigger fire groups sequentially
function FireGroupAction:fireGroups()
	local start = self.leftToRight and 1 or self.fireGroupAmount
	local finish = self.leftToRight and self.fireGroupAmount or 1
	local thingymajig = (start > finish) and -1 or 1
	
	for index = start, finish, thingymajig do
		local currentFireFolder = self.fountainSection:FindFirstChild(index)
		

		if currentFireFolder then
			self:activateFireFolder(currentFireFolder, true)
		end

		task.wait(self.delayBetweenGroups)

		if self.lastFireFolder then
			self:activateFireFolder(self.lastFireFolder, false)
		end

		self.lastFireFolder = currentFireFolder
	end

	if self.lastFireFolder then
		self:activateFireFolder(self.lastFireFolder, false)
	end
end

-- Main execution function
function FireGroupAction:execute()
	if self.repeatTime then
		for _ = 1, self.repeatTime do
			self:fireGroups()
			task.wait(1)
		end
	else
		self:fireGroups()
	end
end

return FireGroupAction





