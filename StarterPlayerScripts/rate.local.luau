--!strict
-- // Services \\ --
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

-- // Device Detection \\ --
-- Detects touch-primary devices while ignoring touchscreen desktop laptops
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- // Core Configuration Variables \\ --
local CONFIG = {
	EMITTER_NAME = "Water",
	EMITTER_TAG = "FountainWater",      -- Optional CollectionService tag support

	MAX_GLOBAL_PARTICLES = IS_MOBILE and 3500 or 14000, -- Dynamic budget (3,500 Mobile / 14,000 Desktop)
	MAX_SINGLE_EMITTER_RATE = 250,      -- Absolute ceiling rate per emitter
	SMOOTH_SPEED = 8,                   -- Exponential smoothing factor for rate transitions

	EPSILON = 0.05,                     -- Threshold to consider rate lerp complete
}

-- // Types \\ --
type EmitterState = {
	Emitter: ParticleEmitter,
	BaseRate: number,                    -- Design rate target
	TargetRate: number,                  -- Calculated safe budget target
	CurrentRate: number,                 -- Smooth interpolated active rate
	Connections: { RBXScriptConnection },
}

-- // State Management \\ --
local trackedEmitters: { [ParticleEmitter]: EmitterState } = {}
local heartbeatConnection: RBXScriptConnection? = nil
local isUpdating = false

-- Forward declaration of helper function
local wakeUpdateLoop: () -> ()

-- // Helper Functions \\ --

-- FPS-Independent Exponential Lerp
local function expLerp(current: number, target: number, speed: number, dt: number): number
	return current + (target - current) * (1 - math.exp(-speed * dt))
end

-- Safely retrieves max lifetime of an emitter
local function getMaxLifetime(emitter: ParticleEmitter): number
	local lifetime = emitter.Lifetime
	return math.max(lifetime.Max, 0.1)
end

-- // Budget Calculation Logic \\ --

local function recalculateParticleBudget()
	local totalRequestedParticles = 0

	-- 1. Calculate total particle demand across all active emitters
	for emitter, state in pairs(trackedEmitters) do
		if emitter.Enabled then
			local emitterLifetime = getMaxLifetime(emitter)
			totalRequestedParticles += (state.BaseRate * emitterLifetime)
		end
	end

	-- 2. Determine global scaling factor (Scale down if over budget)
	local scaleFactor = 1.0
	if totalRequestedParticles > CONFIG.MAX_GLOBAL_PARTICLES and totalRequestedParticles > 0 then
		scaleFactor = CONFIG.MAX_GLOBAL_PARTICLES / totalRequestedParticles
	end

	-- 3. Assign target rates proportional to each emitter's original weight
	for emitter, state in pairs(trackedEmitters) do
		if emitter.Enabled then
			local budgetedRate = state.BaseRate * scaleFactor
			state.TargetRate = math.clamp(budgetedRate, 0, CONFIG.MAX_SINGLE_EMITTER_RATE)
		else
			state.TargetRate = 0
		end
	end

	-- Wake up the updating loop
	wakeUpdateLoop()
end

-- // Render Loop Management \\ --

local function updateRates(dt: number)
	local matchesNeeded = 0
	local totalEmitters = 0

	for emitter, state in pairs(trackedEmitters) do
		totalEmitters += 1

		-- Interpolate rate frame-by-frame
		if math.abs(state.CurrentRate - state.TargetRate) > CONFIG.EPSILON then
			state.CurrentRate = expLerp(state.CurrentRate, state.TargetRate, CONFIG.SMOOTH_SPEED, dt)
			emitter.Rate = state.CurrentRate
		else
			-- Snap to final target once close enough
			if state.CurrentRate ~= state.TargetRate then
				state.CurrentRate = state.TargetRate
				emitter.Rate = state.TargetRate
			end
			matchesNeeded += 1
		end
	end

	-- Sleep update loop when all active emitters have settled at their target rates
	if matchesNeeded == totalEmitters and isUpdating then
		if heartbeatConnection then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
		end
		isUpdating = false
	end
end

function wakeUpdateLoop()
	if not isUpdating then
		isUpdating = true
		heartbeatConnection = RunService.Heartbeat:Connect(updateRates)
	end
end

-- // Core Binding Logic \\ --

local function unbindEmitter(emitter: ParticleEmitter)
	local state = trackedEmitters[emitter]
	if state then
		for _, conn in ipairs(state.Connections) do
			conn:Disconnect()
		end
		trackedEmitters[emitter] = nil
		recalculateParticleBudget()
	end
end

local function bindEmitter(emitter: ParticleEmitter)
	if trackedEmitters[emitter] then return end

	-- Determine initial base rate (Supports custom Studio attribute override)
	local customBaseRate = emitter:GetAttribute("BaseRate")
	local initialBaseRate = customBaseRate or (emitter.Rate > 0 and emitter.Rate or 50)

	local state: EmitterState = {
		Emitter = emitter,
		BaseRate = initialBaseRate,
		TargetRate = 0,
		CurrentRate = emitter.Rate,
		Connections = {},
	}

	-- Watch property changes
	local function watch(propName: string, callback: () -> ())
		table.insert(state.Connections, emitter:GetPropertyChangedSignal(propName):Connect(function()
			callback()
			recalculateParticleBudget()
		end))
	end

	watch("Enabled", function() end)
	watch("Lifetime", function() end)

	-- Catch base rate adjustments made in Studio or by external scripts
	watch("Rate", function()
		if not isUpdating and math.abs(emitter.Rate - state.CurrentRate) > CONFIG.EPSILON then
			state.BaseRate = emitter.Rate
		end
	end)

	-- Cleanup on destroy
	table.insert(state.Connections, emitter.Destroying:Connect(function()
		unbindEmitter(emitter)
	end))

	trackedEmitters[emitter] = state
	recalculateParticleBudget()
end

-- // Discovery & Event Setup \\ --

local function scanInstance(instance: Instance)
	if instance:IsA("ParticleEmitter") then
		if instance.Name == CONFIG.EMITTER_NAME or instance:HasTag(CONFIG.EMITTER_TAG) then
			bindEmitter(instance)
		end
	end
end

-- CollectionService Support
CollectionService:GetInstanceAddedSignal(CONFIG.EMITTER_TAG):Connect(function(inst)
	if inst:IsA("ParticleEmitter") then bindEmitter(inst) end
end)

for _, taggedObj in ipairs(CollectionService:GetTagged(CONFIG.EMITTER_TAG)) do
	if taggedObj:IsA("ParticleEmitter") then bindEmitter(taggedObj) end
end

-- Workspace Descendant Setup
Workspace.DescendantAdded:Connect(scanInstance)
for _, descendant in ipairs(Workspace:GetDescendants()) do
	scanInstance(descendant)
end