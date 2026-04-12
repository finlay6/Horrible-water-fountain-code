-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

local FallForwardAction = {}
FallForwardAction.__index = FallForwardAction

-- // Type Declarations \\ --

type Config = {
	FountainSection: Instance,
	CustomPartSelectionEnabled: boolean,
	CustomPartSelectionInterval: number,
	PartNamePrefix: string,
	ParticlePower: number,
	SelectParts: boolean,
	FirstNumParts: number,
	SecondNumParts: number
}

-- // Helper Functions \\ --

-- FallForwardAction Module
local FallForwardAction = {}
FallForwardAction.__index = FallForwardAction

-- // Helper Functions \\ --

local function handleFountainPart(fountainPart, angle, newCFrame, fadeInDuration, fountainSectionName, disabledWhenStop)
	local cframeTween = UtilityModule.createTween(fountainPart, "CFrame", newCFrame, fadeInDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	fountainPart.Water.Enabled = true
	UtilityModule.setParticleHeight(fountainSectionName, fountainPart.Water)

	-- Play the tween
	cframeTween:Play()
	UtilityModule.disableParticle(fountainSectionName, fountainPart.Water)
end

-- Constructor
function FallForwardAction:new(config)
	local fallForwardActionInstance = setmetatable({}, FallForwardAction)

	-- Store config properties
	fallForwardActionInstance.fountainSection = config.FountainSection
	fallForwardActionInstance.partNamePrefix = config.PartNamePrefix
	fallForwardActionInstance.disabledWhenStop = config.DisabledWhenStop
	fallForwardActionInstance.orientation = config.Orientation
	fallForwardActionInstance.forwards = config.Forward
	fallForwardActionInstance.fadeInDuration = config.FadeInDuration
	fallForwardActionInstance.everyCertain = config.EveryCertain
	fallForwardActionInstance.everyCertainNumber = config.EveryCertainNumber

	-- Retrieve fountain parts
	fallForwardActionInstance.fountainParts = UtilityModule.getParts(
		fallForwardActionInstance.fountainSection,
		fallForwardActionInstance.everyCertain,
		fallForwardActionInstance.everyCertainNumber,
		fallForwardActionInstance.partNamePrefix
	)

	return fallForwardActionInstance
end

-- Execution logic
function FallForwardAction:execute()
	local angle = math.rad(self.forwards and -self.orientation or self.orientation)

	for _, fountainPart in ipairs(self.fountainParts) do
		local newCFrame = fountainPart.OriginalCFrame.Value * CFrame.Angles(angle, 0, 0)
		handleFountainPart(fountainPart, angle, newCFrame, self.fadeInDuration, self.fountainSection.Name, self.disabledWhenStop)
	end
end

return FallForwardAction
