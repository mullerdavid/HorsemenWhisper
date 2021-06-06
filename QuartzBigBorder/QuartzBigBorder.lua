local ADDON, T = ...
local L = {}

local function Init()
	local Quartz3 = LibStub("AceAddon-3.0"):GetAddon("Quartz3")
	if Quartz3
	then
		hooksecurefunc(Quartz3.CastBarTemplate.template, "ApplySettings", 
		function(self) 
			local db = self.config
			self:SetWidth(db.w + 16)
			self:SetHeight(db.h + 16)
			self.backdrop.tileSize = 20
			self.backdrop.edgeSize = 20
		end )
	end
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
