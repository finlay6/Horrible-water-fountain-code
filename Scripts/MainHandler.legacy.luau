-- // Services \\ --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

-- // Folders \\ --
local Core = ServerScriptService.Core
local Modules = Core.Modules
local FountainSystem = Modules.FountainSystem
local UtilityModules = FountainSystem.Utility
local Functions = ServerStorage.Functions

-- // Modules \\ --
local ParticleConfig = require(UtilityModules.ParticleConfig)
local ActionManager = require(FountainSystem.ActionManager)

-- // Directories \\ --
local ParticleHeights = ParticleConfig.Heights
local SongConfigs = Functions.SongConfigs

local Components = ReplicatedStorage.Components
local Sounds = Components.Sounds
local Music = Sounds.Music

-- // SongConfigs \\ --
local StarSpangeledBannerConfig = SongConfigs.StarSpangledBanner
local TribalUprisingConfig = SongConfigs.TribalUprising
local RainingTacosConfig = SongConfigs.RainingTacos
local LaBambaConfig = SongConfigs.LaBamba
local OverturesConfig = SongConfigs.Overtures
local BlueDanubeConfig = SongConfigs.BlueDanube
local FurEliseConfig = SongConfigs.FurElise

local TimeBeforeSequenceStarts = SongConfigs.TimeBeforeSequenceStarts.Value

-- // Helper Functions \\ --
function getAllFunctionsAndVariablesFromConfig(Config)
	local functions = {}
	local duplicates = 0

	for _, nextFunction in ipairs(Config:GetChildren()) do
		if nextFunction:IsA("Configuration") then
			local selfIdentifier
			if functions[nextFunction.Name] then
				duplicates = duplicates + 1
				selfIdentifier = string.format("%s%d", nextFunction.Name, duplicates)
				functions[selfIdentifier] = {Variables = {Heights = ParticleHeights}}
			else
				selfIdentifier = nextFunction.Name
				functions[selfIdentifier] = {Variables = {Heights = ParticleHeights}}
			end

			for _, variable in ipairs(nextFunction:GetDescendants()) do
				if variable:IsA("ValueBase") then
					local variableValue = variable.Value
					functions[selfIdentifier].Variables[variable.Name] = variableValue
				end
			end
		end
	end

	return functions
end

function executeFunctions(functions)
	for functionName, nextFunction in pairs(functions) do
		local cleanName = functionName:gsub("%d", "")
		local functionVariables = nextFunction.Variables
		ActionManager.CallAction(cleanName, functionVariables)
	end
end

-- // Main Functions \\ --
function playSong(songName, completeEvent, startOffset)
	startOffset = startOffset or 0

	local audio = Music:FindFirstChild(songName)
	if not audio then
		warn("No audio found for song " .. songName)
		completeEvent:Fire()
		return false
	end

	-- helper to finish
	local function finish()
		completeEvent:Fire()
	end

	if audio:IsA("Folder") then
		-- gather and sort parts
		local parts = audio:GetChildren()
		table.sort(parts, function(a, b)
			return a.Order.Value < b.Order.Value
		end)

		-- if offset skips some entire parts...
		local cumTime = 0
		local idx = 1
		while idx <= #parts do
			local length = parts[idx].TimeLength
			if startOffset >= cumTime + length then
				-- skip this whole part
				cumTime = cumTime + length
				idx = idx + 1
			else
				break
			end
		end

		-- play remaining, with the first one jumped in
		for i = idx, #parts do
			local part = parts[i]
			part.TimePosition = math.max(0, startOffset - cumTime)
			part:Play()
			part.Ended:Wait()
			cumTime = cumTime + part.TimeLength
			-- after the first, don't reapply offset
			startOffset = 0
		end

		finish()
	else
		-- single Sound
		audio.TimePosition = startOffset
		audio:Play()
		audio.Ended:Wait()
		finish()
	end

	return true
end

-- songExecuter now takes startOffset
function songExecuter(songConfig, startOffset)
	startOffset = startOffset or 0

	local children = songConfig:GetChildren()
	if #children == 0 then
		warn("No configurations found for this song.")
		return false
	end

	-- 1) Build flat list of { time, order, config }
	local configTimings = {}
	for _, child in ipairs(children) do
		local stamp = child.Name
		-- detect sign
		local sign = stamp:match("^%-") and -1 or 1
		local body = stamp:gsub("^[-+]", "")

		local m, s
		if body:find(":") then
			-- format "m:s" or "m:ss.fraction"
			m, s = body:match("^(%d+%.?%d*):(%d+%.?%d*)$")
			if not m or not s then
				warn("Bad timestamp: "..stamp)
				return false
			end
			m, s = tonumber(m), tonumber(s)
		else
			-- plain decimal = minutes
			m = tonumber(body)
			if not m then
				warn("Bad timestamp: "..stamp)
				return false
			end
			s = 0
		end

		local t = (m * 60 + s) * sign
		table.insert(configTimings, {
			time   = t,
			order  = child.Order.Value,
			config = child
		})
	end

	-- 2) Sort by time asc, then order asc
	table.sort(configTimings, function(a, b)
		if a.time == b.time then
			return a.order < b.order
		end
		return a.time < b.time
	end)

	-- 3) Shift times by startOffset, drop anything before 0
	for i = #configTimings, 1, -1 do
		local ct = configTimings[i]
		ct.happTime = ct.time - startOffset
		if ct.happTime < 0 then
			table.remove(configTimings, i)
		end
	end

	-- 4) Find earliest (might be zero)
	local earliest = configTimings[1] and configTimings[1].happTime or 0
	local preDelay = (earliest < 0) and -earliest or 0

	-- 5) Bindable for song end
	local songDone = Instance.new("BindableEvent")

	-- 6) Schedule each future config
	local startAt = tick() + preDelay
	for _, ct in ipairs(configTimings) do
		task.spawn(function()
			local target = startAt + ct.happTime
			local waitFor = target - tick()
			if waitFor > 0 then task.wait(waitFor) end
			executeFunctions(getAllFunctionsAndVariablesFromConfig(ct.config))
			print(ct.config.Name)
		end)
	end

	-- 7) Schedule the song playback at the right wall-clock time
	task.spawn(function()
		local waitFor = startAt - tick()
		if waitFor > 0 then task.wait(waitFor) end
		playSong(songConfig.Name, songDone, startOffset)
	end)

	-- 8) Wait for endpa
	songDone.Event:Wait()
	return true
end

-- // Main Loop \\ --
local songs = {
	TribalUprisingConfig,
	LaBambaConfig,
	BlueDanubeConfig,
	StarSpangeledBannerConfig,
	RainingTacosConfig,
	FurEliseConfig,
	
	OverturesConfig,
}

task.wait(2)

while true do
	for _, song in ipairs(songs) do
		songExecuter(song, 80)
		task.wait(1) -- small delay between songs
	end
end

for _, value in workspace.Fountain:GetDescendants() do
	if value.Name == "Water" then
		local Parent = value.Parent
		local Clone = workspace.Water:Clone()
		Clone.Parent = Parent
		value:Destroy()
	end
end