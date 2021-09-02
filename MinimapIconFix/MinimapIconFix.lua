local ADDON, T = ...
local L = {}


local function Init()
	local eye = MiniMapLFGFrameIcon
	eye:SetScript("OnUpdate", nil);
	if ( eye.Texture.frame ) then
		eye.Texture.frame = 1;
	end
	local textureInfo = LFG_EYE_TEXTURES["default"];
	eye.Texture:SetTexCoord(0, textureInfo.iconSize / textureInfo.width, 0, textureInfo.iconSize / textureInfo.height);
	MiniMapWorldMapButton:Hide()
	MiniMapWorldMapButton:HookScript("OnShow", function(self) MiniMapWorldMapButton:Hide() end)
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
