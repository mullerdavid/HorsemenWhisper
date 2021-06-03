local ADDON, T = ...
local L = {}

_G["SLASH_"..ADDON.."1"] = "/automark"

local frame = CreateFrame("Frame")
local timer = nil
local markState = {} 
local markGuid = {} 
local skull,cross,circle,star,square,triangle,diamond,moon = 8,7,2,1,6,4,3,5

local function ProcessCommand(msg)
	local _, _, cmd, args = string.find(msg or "", "%s?(%w+)%s?(.*)")
	local cmdlower = strlower(cmd or "")
	if not cmd or cmdlower == "help"
	then
		print("Syntax: " .. _G["SLASH_"..ADDON.."1"] .. " (toggle|on|off)");
	elseif cmdlower == "" or cmdlower == "toggle"
	then
		if frame:IsEventRegistered("UPDATE_MOUSEOVER_UNIT")
		then
			frame:UnRegisterEvent("UPDATE_MOUSEOVER_UNIT")
			frame:UnRegisterEvent("PLAYER_LEAVE_COMBAT")
			print("Automark off")
		else
			frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
			frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
			L.ClearState()
			print("Automark on")
		end
	elseif cmdlower == "on" or cmdlower == "1"
	then
		frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
		L.ClearState()
		print("Automark on")
	elseif cmdlower == "off" or cmdlower == "0"
	then
		frame:UnRegisterEvent("UPDATE_MOUSEOVER_UNIT")
		frame:UnRegisterEvent("PLAYER_LEAVE_COMBAT")
		print("Automark off")
	end
end

local function Init()
	print(ADDON.." Loaded.")
end


function L.ClearState()
	markState = {true, true, true, true, true, true, true, true}
	markGuid = {}
	if timer
	then
		timer:Cancel()
		timer = nil
	end
	print("Mark states cleared")
end

function L.StartClearStateTimer()
	if not timer
	then
		timer = C_Timer.NewTimer(30, L.ClearState)
	end
end

local default = {square, cross, skull, moon, circle, diamond, star, triangle}
function L.GetNextFreeMark(targets)
	if targets
	then
		for i=1,#targets
		do
			local t = targets[i]
			if markState[t]
			then
				return t
			end
		end
	end
	for i=1,#default
	do
		local t = default[i]
		if markState[t]
		then
			return t
		end
	end
end

local function OnMouseOverUpdate()
	if not IsAltKeyDown() then return end
	local unit = "mouseover"
	local name = UnitName(unit)
	local guid = UnitGUID(unit)
	if name and not GetRaidTargetIndex(unit) and not UnitIsDead(unit) and UnitIsEnemy("player", unit) and not markGuid[guid]
	then
		local mark = L.GetNextFreeMark(L.db[name])
		if mark
		then
			SetRaidTarget(unit, mark)
			markGuid[guid] = true
			markState[mark] = false
			L.StartClearStateTimer()
		end
	end
end

local function OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON
	then
		self:UnregisterEvent("ADDON_LOADED")
		SlashCmdList[ADDON] = ProcessCommand
		Init()
	elseif event == "UPDATE_MOUSEOVER_UNIT"
	then
		OnMouseOverUpdate()
	elseif event == "PLAYER_LEAVE_COMBAT"
	then
		L.ClearState()
	end
end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)


L.db = {
	["name"] = {}
}
