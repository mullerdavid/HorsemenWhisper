--[[ Globals ]]--

HorsemenWhisper_Addon = "HorsemenWhisper"
SLASH_HorsemenWhisper1 = "/hmw"

--[[ SAVED VARIABLES ]]--

--[[ Code ]]--

local rotation = {}
local bosses = {[0]="{rt8}Thane", "{rt6}Morgrain", "{rt5}Zeliek", "{rt7}Blaumeux", }

local addon_loaded = false
local dbm_loaded = false


local function MoveToBoss(i, boss)
	i = i % 12
	if i == 0 then i = 12 end
	boss = boss % 4
	boss = bosses[boss]
	local names = rotation[i]
	if names and names ~= ""
	then
		local tbl = { strsplit(",", names) }
		for i=1,#tbl
		do
			ChatThrottleLib:SendChatMessage("ALERT", "", "Move to " .. boss, "WHISPER", nil, tbl[i]);
		end 
	end
end

local function OnMark(num)
	if (num>0)
	then
		MoveToBoss(4-num,1)
		MoveToBoss(7-num,2)
		MoveToBoss(10-num,3)
		MoveToBoss(13-num,4)
	else
		for i=1,12 
		do
			MoveToBoss(i, math.floor((i-1)/3))
		end
	end
end

local function ProcessCommand(msg)
	local _, _, pos, name = string.find(msg, "%s?(%w+)%s?(.*)")
	if pos
	then
		pos = tonumber(pos)
		if pos
		then
			if name ~= ""
			then
				rotation[pos]=name
				print(pos .. ": " .. name)
			else
				OnMark(pos)
			end
		else
			print("Invlid number")
		end
	else
		print("Syntax: " .. SLASH_HorsemenWhisper1 .. " (pos name[,name,name...]|mark) ");
		print("Current settings:")
		for i=1,12 
		do
			local t = rotation[i]
			if t
			then
				print(i .. ": " .. t)
			end
		end
	end
end

local function DBMCallback(event, id, msg, timer, icon, type, spell, color, mod, keep, fade, name, guid)
	if mod == "Horsemen"
	then
		local mark, num = strsplit(" ", msg, 2)
		if mark == "Mark"
		then
			OnMark(tonumber(num)-1)
		end
	end
end

local function RegisterDBM()
	if (not dbm_loaded) and (DBM)
	then
		dbm_loaded = true
		DBM:RegisterCallback("DBM_TimerStart", DBMCallback)
		-- DBM-Naxx\MilitaryQuarter\Horsemen.lua, add 16168 (Stoneskin Gargoyle) to SetCreatureID for debug
	end
end

local function Init()
	if (not addon_loaded)
	then
		addon_loaded = true
		RegisterDBM()
		SlashCmdList[HorsemenWhisper_Addon] = ProcessCommand
	end
end

local function OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == HorsemenWhisper_Addon
	then
		Init()
	elseif event == "ADDON_LOADED" and arg1 == "DBM-Core"
	then
		RegisterDBM()
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)
