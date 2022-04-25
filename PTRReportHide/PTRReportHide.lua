local ADDON, T = ...
local L = {}

local function TooltipRemove()
	for _,region in pairs({GameTooltip:GetRegions()}) 
	do 
		if region and region:GetObjectType() == "FontString" 
		then 
			local text = region:GetText() 
			if text and strfind(text, "to submit a bug for this") 
			then 
				region:SetText(nil) 
			end
		end 
	end 
end

local function Init()
	PTR_IssueReporter:SetAlpha(0)
	PTR_IssueReporter:SetScale(0.0001)
	GameTooltip.ShowHook = TooltipRemove
	GameTooltip:HookScript("OnShow", GameTooltip.ShowHook);
	
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
