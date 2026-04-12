-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

-- RotateAAction Module
local RotateAAction = {}
RotateAAction.__index = RotateAAction

-- Constructor
function RotateAAction:new(config)
	local instance = setmetatable({}, RotateAAction)

	instance.fountainSection = config.FountainSection
	instance.sequenceDuration = config.SequenceDuration
	instance.finalRotationY = config.FinalRotationY or 0
	instance.finalRotationZ = config.FinalRotationZ or 0
	instance.particlePower = config.ParticlePower or 100
	instance.lifeTime = config.LifeTime
	instance.fadeInTime = config.FadeInTime
	instance.mainPart = instance.fountainSection.PrimaryPart

	-- Sway parameters
	instance.enableSway = config.EnableSway or false
	instance.swayAmplitude = config.SwayAmplitude or 50
	instance.swayFrequency = config.SwayFrequency or 2
	instance.swayAxis = config.SwayAxis or "X"  -- "X" or "Z"

	return instance
end

function RotateAAction:execute()
	local startTime = tick()
	local startCFrame = self.mainPart.CFrame

	-- Enable particles
	for _, part in ipairs(self.fountainSection:GetChildren()) do
		if part:FindFirstChild("Water") then
			part.CanCollide = true 
			part.Water.Enabled = true
			UtilityModule.setParticleHeight(
				self.fountainSection.Name, 
				part.Water, 
				self.particlePower, 
				self.lifeTime, 
				self.fadeInTime
			)
		end
	end

	-- Animation loop
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local alpha = math.min(elapsed / self.sequenceDuration, 1)

		-- Base Y rotation (continuous)
		local yRotation = math.rad(self.finalRotationY) * alpha
		local zRotation = math.rad(self.finalRotationZ) * alpha

		-- Sway oscillation
		local xSway = 0
		local zSway = 0

		if self.enableSway then
			local swayPhase = alpha * self.swayFrequency * math.pi * 2
			local swayValue = math.rad(self.swayAmplitude) * math.sin(swayPhase)

			if self.swayAxis == "X" then
				xSway = swayValue
			elseif self.swayAxis == "Z" then
				zSway = swayValue
			end
		end

		-- Apply combined rotation
		self.mainPart.CFrame = startCFrame * CFrame.Angles(xSway, yRotation, zRotation + zSway)

		-- Cleanup when done
		if alpha >= 1 then
			connection:Disconnect()

			for _, part in ipairs(self.fountainSection:GetChildren()) do
				if part:FindFirstChild("Water") then
					UtilityModule.disableParticle(self.fountainSection.Name, part.Water)
				end
			end
		end
	end)
end

return RotateAAction








