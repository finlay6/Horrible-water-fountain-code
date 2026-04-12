-- // Services \\ --

local ServerScriptService = game:GetService("ServerScriptService")

-- // Directories \\ --

local core = ServerScriptService.Core
local modules = core.Modules
local fountainSystem = modules.FountainSystem
local actionModules = fountainSystem.Actions
local globalActions = actionModules.GlobalActions
local songSpecificActions = actionModules.SongSpecificActions
local lightingActions = actionModules.LightingActions

-- ActionManager Module
local ActionManager = {}
ActionManager.__index = ActionManager

function ActionManager.CallAction(actionName: string, actionVariables)
	local actionFolder
	if actionName:sub(1, 1) == "*" then
		actionFolder = songSpecificActions
	elseif string.find(actionName, "Lighting") then
		actionFolder = lightingActions
	else
		actionFolder = globalActions
	end

	if not actionFolder then
		warn("Action folder not found!")
		return
	end

	local actionModule = actionFolder:FindFirstChild(actionName)
	if not actionModule then
		warn("Action module '" .. actionName .. "' not found!")
		return
	end

	local actionClass = require(actionModule)
	if not actionClass or type(actionClass.new) ~= "function" or type(actionClass.execute) ~= "function" then
		warn("Invalid action module: " .. actionName)
		return
	end

	local actionInstance = actionClass:new(actionVariables)
	local actionInstanceThread = task.spawn(function()
		actionInstance:execute()
	end)
	
	return actionInstanceThread
end

return ActionManager
