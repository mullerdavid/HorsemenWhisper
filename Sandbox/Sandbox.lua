local ADDON, T = ...
local L = {}

_G["SLASH_"..ADDON.."1"] = "/sandbox"

local function ProcessCommand(msg)
	local _, _, cmd, args = string.find(msg or "", "%s?(%w+)%s?(.*)")
	local cmdlower = strlower(cmd or "")
	if not cmd or cmdlower == "help" or cmdlower == ""
	then
		print("Syntax: " .. _G["SLASH_"..ADDON.."1"] .. " TODO help message");
	end
end

local function Init()
	print(ADDON.." Init()")
end

local function OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON
	then
		self:UnregisterEvent("ADDON_LOADED")
		SlashCmdList[ADDON] = ProcessCommand
		Init()
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)
