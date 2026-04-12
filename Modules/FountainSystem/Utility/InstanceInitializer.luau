-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local utilityModules = fountainSystem.Utility

local UtilityModule = require(utilityModules.UtilityModule)

-- InstanceInitializer Module
local InstanceInitializer = {}

-- // Helper Functions \\ --

-- Function to convert a string to camelCase
local function toCamelCase(str)
	local result = str:lower()
	result = result:gsub("_(%a)", function(a) return a:upper() end)
	return result
end

local function getPartByName(fountainSection, specificPartKey)
	for _, value in fountainSection:GetChildren() do
		if value.Name == specificPartKey then
			return value
		end
	end
end

-- // Main Functions \\ --

function InstanceInitializer.initializeInstance(instance, config)
	-- Preserve existing metatable by setting __index only if not already set
	local mt = getmetatable(instance) or {}
	mt.__index = mt.__index or instance -- Ensure it refers to its original class
	setmetatable(instance, mt)

	-- Convert config attributes to instance variables (CamelCase)
	for key, value in pairs(config) do
		local formattedKey = key:sub(1, 1):lower() .. key:sub(2) -- Convert to camelCase
		instance[formattedKey] = value
	end

	-- Determine part selection method (specific parts vs range)
	local specificParts = {}
	local partLowerBound = config.PartLowerBound
	local partUpperBound = config.PartUpperBound
	
	-- Check for specific part selection
	for i = 1, 100 do -- Assume a reasonable limit to prevent infinite loops
		local specificPartKey = "SpecificPart" .. i
		if config[specificPartKey] then
			table.insert(specificParts, getPartByName(config.FountainSection, config[specificPartKey]))
		else
			break
		end
	end
	
	-- Assign fountain parts based on selection method
	if #specificParts > 0 then
		instance.fountainParts = specificParts
	elseif partLowerBound and partUpperBound then
		instance.fountainParts = UtilityModule.getPartsInRange(
			instance.fountainSection,
			partLowerBound,
			partUpperBound,
			"Part"
		)
	else
		-- Default to normal selection method
		instance.fountainParts = UtilityModule.getParts(
			instance.fountainSection,
			"Part",
			instance.customPartSelectionEnabled,
			instance.customPartSelectionInterval
		)
	end
	
	-- Apply exclusion logic (only keep parts between exclusionStartPoint and exclusionEndPoint)
	if instance.exclusionStartPoint and instance.exclusionEndPoint then
		local exclusionStartIndex, exclusionEndIndex

		-- Find index positions of exclusionStartPoint and exclusionEndPoint
		for index, part in ipairs(instance.fountainParts) do
			if part.Name == instance.exclusionStartPoint then
				exclusionStartIndex = index
			end
			if part.Name == instance.exclusionEndPoint then
				exclusionEndIndex = index
			end
		end

		-- If valid indices are found, filter the list
		if exclusionStartIndex and exclusionEndIndex and exclusionStartIndex <= exclusionEndIndex then
			local filteredParts = {}
			for i = exclusionStartIndex, exclusionEndIndex do
				table.insert(filteredParts, instance.fountainParts[i])
			end
			instance.fountainParts = filteredParts
			
			print(filteredParts)
		else
			-- If invalid indices, clear the list to avoid unintended behavior
			instance.fountainParts = {}
		end
	end

	instance.fountainPartsAmount = UtilityModule.getLengthOfDictionary(instance.fountainParts)
	instance.partNamePrefix = "Part"

	return instance
end


return InstanceInitializer

