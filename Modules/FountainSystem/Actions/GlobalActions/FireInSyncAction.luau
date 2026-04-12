-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)
local InstanceInitialiser = require(utilityModules.InstanceInitializer)

-- FireInSyncAction Module
local FireInSyncAction = {}
FireInSyncAction.__index = FireInSyncAction

-- Constructor
function FireInSyncAction:new(config)
	local instance = setmetatable({}, FireInSyncAction)

	InstanceInitialiser.initializeInstance(instance, config)
	instance.endTime = time() + instance.sequenceDuration
	
	return instance
end

-- Function to fire in sync
--function FireInSyncAction:execute()
--	local lastFiredIndices = {}

--	while time() < self.endTime do
--		local currentFiredIndices = {}

--		if self.groupCount then
--			local indices = {}

--			-- Function to check if the selected group overlaps with previously fired indices
--			local function isGroupOverlapping(startIndex)
--				for i = startIndex, startIndex + self.groupCount - 1 do
--					if table.find(lastFiredIndices, i) or table.find(currentFiredIndices, i) then
--						return true
--					end
--				end
--				-- Ensure a gap between groups
--				if table.find(lastFiredIndices, startIndex - self.groupCount) or table.find(lastFiredIndices, startIndex + self.groupCount) then
--					return true
--				end
--				return false
--			end

--			-- Generate unique start indices ensuring no repeat, overlap, and no adjacent groups
--			local groupsToFire = self.maxGroupsAtOnce or 1
--			for _ = 1, groupsToFire do
--				local startIndex
	
--				startIndex = math.random(1, self.fountainPartsAmount - self.groupCount + 1)


--				-- Fire the group
--				for i = startIndex, startIndex + self.groupCount - 1 do
--					table.insert(currentFiredIndices, i)
--					local part = self.fountainSection:FindFirstChild(self.partNamePrefix .. i)
--					if part and part:FindFirstChild("Water") then
--						part.Water.Enabled = true
--						UtilityModule.setParticleHeight(self.fountainSection.Name, part.Water, self.particlePower)
--					end
--				end
--			end
--		else
--			-- Enable all particle emitters
--			for _, part in ipairs(self.fountainSection:GetDescendants()) do
--				if part:IsA("ParticleEmitter") then
--					part.Enabled = true
--					UtilityModule.setParticleHeight(self.fountainSection.Name, part, self.particlePower)
--				end
--			end
--		end

--		task.wait(self.durationInterval)

--		-- Disable all particle emitters if required
--		if self.deactivateWhenComplete then
--			for _, part in ipairs(self.fountainSection:GetDescendants()) do
--				if part:IsA("ParticleEmitter") then
--					part.Enabled = false
--					part.Parent.CFrame = part.Parent.OriginalCFrame.Value
--				end
--			end
--		end

--		task.wait(self.durationInterval)

--		-- Update lastFiredIndices to avoid repeat and adjacent activations
--		lastFiredIndices = currentFiredIndices
--	end

--	-- Ensure all particles are disabled when the sequence stops
--	if self.deactivateWhenComplete then
--		for _, part in ipairs(self.fountainSection:GetDescendants()) do
--			if part:IsA("ParticleEmitter") then
--				part.Enabled = false
--				part.Parent.CFrame = part.Parent.OriginalCFrame.Value
--			end
--		end
--	end
--end

function FireInSyncAction:execute()
	local lastFiredStarts = {} -- store start indices (not every part index)

	while time() < self.endTime do
		local currentFiredStarts = {}

		if self.groupCount then
			local g = self.groupCount
			local maxStart = self.fountainPartsAmount - g + 1
			if maxStart >= 1 then
				-- helper: valid start if it keeps >= 1-part gap from any start already chosen
				local function isValidStart(start)
					-- check against last tick's groups
					for _, s in ipairs(lastFiredStarts) do
						if math.abs(start - s) < (g + 1) then
							return false
						end
					end
					-- check against groups chosen this tick (prevent adjacent within same tick)
					for _, s in ipairs(currentFiredStarts) do
						if math.abs(start - s) < (g + 1) then
							return false
						end
					end
					return true
				end

				-- gather all valid candidate starts
				local candidates = {}
				for s = 1, maxStart do
					if isValidStart(s) then
						table.insert(candidates, s)
					end
				end

				-- shuffle candidates (Fisher–Yates)
				for i = #candidates, 2, -1 do
					local j = math.random(1, i)
					candidates[i], candidates[j] = candidates[j], candidates[i]
				end

				local groupsToFire = math.min(self.maxGroupsAtOnce or 1, #candidates)
				for i = 1, groupsToFire do
					local startIndex = candidates[i]
					table.insert(currentFiredStarts, startIndex)

					-- Fire the group parts
					for idx = startIndex, startIndex + g - 1 do
						local part = self.fountainSection:FindFirstChild(self.partNamePrefix .. idx)
						if part and part:FindFirstChild("Water") then
							part.Water.Enabled = true
							UtilityModule.setParticleHeight(self.fountainSection.Name, part.Water, self.particlePower)
						end
					end
				end
			end
		else
			-- Enable all particle emitters
			print(self.fountainParts)
			for _, part in ipairs(self.fountainParts) do
				if part:IsA("Part") then
					part.Water.Enabled = true
					UtilityModule.setParticleHeight(self.fountainSection.Name, part.Water, self.particlePower)
				end
			end
		end

		task.wait(self.durationInterval)

		-- Disable all particle emitters if required
		if self.deactivateWhenComplete then
			for _, part in ipairs(self.fountainSection:GetDescendants()) do
				if part:IsA("ParticleEmitter") then
					part.Enabled = false
					part.Parent.CFrame = part.Parent.OriginalCFrame.Value
				end
			end
		end

		task.wait(self.durationInterval)

		-- update lastFiredStarts for next tick
		lastFiredStarts = currentFiredStarts
	end

	-- Ensure all particles are disabled when the sequence stops
	if self.deactivateWhenComplete then
		for _, part in ipairs(self.fountainSection:GetDescendants()) do
			if part:IsA("ParticleEmitter") then
				part.Enabled = false
				part.Parent.CFrame = part.Parent.OriginalCFrame.Value
			end
		end
	end
end

return FireInSyncAction






