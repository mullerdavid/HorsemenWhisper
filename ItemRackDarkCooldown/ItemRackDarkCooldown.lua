local ADDON, T = ...
local L = {}


local function FixColorButton()
	for i in pairs(ItemRackUser.Buttons) do
		_G["ItemRackButton"..i.."Cooldown"]:SetSwipeColor(0, 0, 0)
	end
end

local function FixColorMenu()
	for i=1,#(ItemRack.Menu) do
		baseID = tonumber(ItemRack.GetIRString(ItemRack.Menu[i],true)) --get baseID and convert it to number to be able to use it in numerical comparisons below
		if baseID and baseID>0 and ItemRack.menuOpen<20 then
			_G["ItemRackMenu"..i.."Cooldown"]:SetSwipeColor(0, 0, 0)
		end
	end

end

local function FixMinimapTooltip(tooltip)
	tooltip:ClearAllPoints()
	tooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y);
end

local function Init()
	hooksecurefunc(ItemRack, "UpdateButtonCooldowns", FixColorButton)
	hooksecurefunc(ItemRack, "UpdateMenuCooldowns", FixColorMenu)
	hooksecurefunc(ItemRack, "MinimapOnEnter", FixMinimapTooltip)
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
