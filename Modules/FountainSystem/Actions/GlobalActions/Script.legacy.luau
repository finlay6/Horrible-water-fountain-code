local ServerStorage = game:GetService("ServerStorage")

local songConfigsFolder = game.ServerStorage.Functions.SongConfigs

local categoryMappings = {
	Parts = {
		FountainSection = "FountainSection",
		PartGroupingSize = "GroupSize",
		FirstAngle = "AngleOne",
		SecondAngle = "AngleTwo",
		FirstPart = "SpecificPartOne",
		SecondPart = "SpecificPartTwo",
		PartAngle = "AngleForPart",
		Orientation = "PartAngle",
		FirstNumParts = "InitialPartInRange",
		SecondNumParts = "FinalPartInRange",
	},
	Timings = {
		TotalDuration = "SequenceDuration",
		AngleDuration = "DurationForAngle",
		SwayTime = "SwayDuration",
		TransitionDuration = "TransitionTime",
		FadeInDuration = "FadeInTime",
		DelayBetweenPulse = "PulseDelay",
		LoopCodeDuration = "LoopDuration",
		DurationBetween = "DurationInterval",
		DurationBetweenEachPulse = "PulseInterval",
		BackAndForthDuration = "BackAndForthDuration",
		DelayTimeBetweenParts = "PartDelayTime",
		RepeatTime = "LoopCodeDuration",
		ArpeggioAmount = "LoopCodeDuration",
	},
	Behavior = {
		Reversed = "IsReversed",
		Inverted = "IsInverted",
		BackAndForth = "IsBackAndForthMotion",
		Clockwise = "IsClockwise",
		Forwards = "IsForwardsMotion",
		PartsBetween = "PartsSeperation",
		ResetPositionWhenFinished = "ResetOnFinish",
		DisableWhenStop = "DeactivateWhenComplete",
		DeactivateWhenComplete = "DeactivateWhenComplete",
		Power = "PowerLevel",
		FireGroupAmount = "FireGroupCount",
		FinalYRotation = "FinalRotationY",
		CustomPartSelectionInterval = "CustomSelectionInterval",
		EveryCertainNumber = "CustomSelectionInterval",
		MultipleGroupsAtOnceAmount = "MaxGroupsAtOnce",
		GroupingAmount = "GroupCount",
		PartGroupProcessingMode = "GroupProcessingMode",
	},
	Customization = {
		WeirdPoint = "SpecialPoint",
		FallAfterRise = "FallAfterRiseFlag",
		LeftToRight = "IsLeftToRightMotion",
		HeightAdjustment = "HeightOffset",
		TotalStaircases = "TotalStaircases",
	},
	ParticleControl = {},
}

local attributeInfo = {}
for category, map in pairs(categoryMappings) do
	for oldName, newName in pairs(map) do
		attributeInfo[oldName] = { newName = newName, category = category }
	end
end

for _, songConfig in ipairs(songConfigsFolder:GetChildren()) do
	for _, timestampedConfig in ipairs(songConfig:GetChildren()) do
		for _, func in ipairs(timestampedConfig:GetChildren()) do
			local attributes = func:GetChildren()
			
			local categoryFolders = {}
			for categoryName in pairs(categoryMappings) do
				local folder = songConfigsFolder:FindFirstChild(categoryName)
				if not folder then
					folder = Instance.new("Folder")
					folder.Name = categoryName
					folder.Parent = func
				end
				categoryFolders[categoryName] = folder
			end
			
			for _, value in pairs(attributes) do
				local oldName = value.Name
				if attributeInfo[oldName] then
					local info = attributeInfo[oldName]
					local newName = info.newName
					local category = info.category

					value.Name = newName

					local targetFolder = categoryFolders[category]
					if targetFolder then
						local existing = targetFolder:FindFirstChild(newName)
						if not existing then
							value.Parent = targetFolder
						end
					else
						warn("Folder not found for category: " .. category)
					end
				end
			end
		end
	end
end