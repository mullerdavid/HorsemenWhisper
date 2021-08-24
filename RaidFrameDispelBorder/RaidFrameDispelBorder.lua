local ADDON, T = ...
local L = {}

local function UpdateFrame(frame)
	if not frame.debuffHighlight
	then
		local name = nil
		if frame:GetName()
		then
			name = frame:GetName() .. "DebuffHighlight"
		end
		frame.debuffHighlight = frame:CreateTexture(name, "OVERLAY", nil, 7)
		frame.debuffHighlight:SetTexture("Interface\\RaidFrame\\Raid-FrameHighlights")
		frame.debuffHighlight:SetTexCoord(0.00781250,0.55468750,0.28906250,0.55468750)
		frame.debuffHighlight:SetAllPoints(frame);
	end
	
	local color = nil
	if frame.hasDispelCurse
	then
		color = {0.729, 0.369, 0.863, 0.7}
	elseif frame.hasDispelDisease
	then
		color = {0.914, 0.569, 0.396, 0.7}
	elseif frame.hasDispelMagic
	then
		color = {0.286, 0.616, 0.902, 0.7}
	elseif frame.hasDispelPoison
	then
		color = {0, 0.8, 0.278, 0.7}
	end
	
	if color
	then
		frame.debuffHighlight:SetVertexColor(unpack(color))
		frame.debuffHighlight:Show()
	else
		frame.debuffHighlight:Hide()
	end
end

local function Init()
	hooksecurefunc("CompactUnitFrame_UpdateAuras", UpdateFrame)
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
