local ADDON, T = ...
local L = {}

local function Init()
	PTR_IssueReporter:SetAlpha(0)
	PTR_IssueReporter:SetScale(0.0001)
end

local function OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON
	then
		self:UnregisterEvent("ADDON_LOADED")
		Init()
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)
