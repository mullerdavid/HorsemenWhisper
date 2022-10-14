local ADDON, T = ...
local L = {}

local function AtlasLootOpen(autoopen)
	if _G.AtlasLoot then
		if autoopen then
			oldvalue = _G.AtlasLoot.db.enableAutoSelect
			_G.AtlasLoot.db.enableAutoSelect = false
			_G.AtlasLoot.SlashCommands:Run("")
			_G.AtlasLoot.db.enableAutoSelect = oldvalue
		else
			_G.AtlasLoot.SlashCommands:Run("")
		end
	end
	
end

local function Init()
	local eye = MiniMapLFGFrameIcon
	eye:SetScript("OnUpdate", nil);
	if ( eye.Texture.frame ) then
		eye.Texture.frame = 1;
	end
	local textureInfo = LFG_EYE_TEXTURES["default"];
	eye.Texture:SetTexCoord(0, textureInfo.iconSize / textureInfo.width, 0, textureInfo.iconSize / textureInfo.height);	
	MiniMapWorldMapButton:HookScript("OnMouseUp", 
		function(self, button) 
			if button == "RightButton" then
				AtlasLootOpen(false)
			end
			if button == "MiddleButton" then
				AtlasLootOpen(true)
			end
		end)
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
