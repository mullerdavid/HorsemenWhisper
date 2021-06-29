local ADDON, T = ...
local L = {}

local frame = CreateFrame("Frame")

local function Init()
	-- print(ADDON.." Loaded.")
end

local function UpdateZone()
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
	if maxPlayers >= 10
	then
		if (not LoggingCombat())
		then
			LoggingCombat(true)
			print("Entering raid instance, enabling combat log.")
		end
	else
		if (LoggingCombat())
		then
			LoggingCombat(false)
			print("Leaving raid instance, disabling combat log.")
		end
	end
end

local function OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON
	then
		self:UnregisterEvent("ADDON_LOADED")
		Init()
	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" or event == "UPDATE_INSTANCE_INFO"
	then
		UpdateZone()
	end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
--frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("UPDATE_INSTANCE_INFO")
frame:SetScript("OnEvent", OnEvent)
