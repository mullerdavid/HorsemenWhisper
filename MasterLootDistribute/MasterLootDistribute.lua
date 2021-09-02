--[[ Globals ]]--

MasterLootDistribute_Addon = "MasterLootDistribute"
SLASH_MasterLootDistribute1 = "/mld"

MasterLootDistribute_Current = {}

--[[ SAVED VARIABLES ]]--

MasterLootDistribute_Profiles = nil

--[[ Event and command handling ]]--

local frame = CreateFrame("Frame")
local event_registered = false
local addon_loaded = false
local autoloot = false

local function MasterLootDistribute_OnLootMethodChanged()
	local lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod();
	local playerRaidID= UnitInRaid("player")
	local inRaid = IsInRaid()
	if lootmethod == "master" and ((inRaid and masterlooterRaidID==playerRaidID) or (not inRaid and masterlooterPartyID==0)) or autoloot
	then
		event_registered = true
		frame:RegisterEvent("LOOT_READY")
		print("You are the masterlooter or autoloot is turned on, activating auto distribution.")
	else
		if event_registered
		then
			print("You are not the masterlooter anymore and autoloot is disabled, stopping auto distribution.")
		end
		event_registered = false
		frame:UnregisterEvent("LOOT_READY")
	end
end

local function MasterLootDistribute_OnLootReady()
	for i = GetNumLootItems(),1,-1
	do
		if (LootSlotHasItem(i)) 
		then
			local iteminfo, done = GetLootSlotLink(i), false;
			if iteminfo
			then
				local _, itemid = strsplit(":", iteminfo)
				local candidate = MasterLootDistribute_Current[itemid]
				if candidate
				then
					for ci = 1, 40 
					do
						if GetMasterLootCandidate(i, ci) == candidate
						then 
							GiveMasterLoot(i, ci)
							done = true
						end
					end
				end
			end
			if (autoloot and not done)
			then
				LootSlot(i)
				ConfirmLootSlot(i)
			end
		else
			LootSlot(i)
		end
    end
end

local function ProcessCommand(msg)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if cmd
	then
		cmd = cmd:lower()
	end
	if cmd == "print"
	then
		print("Current:")
		for itemid, character in pairs(MasterLootDistribute_Current) do
			itemname = GetItemInfo(itemid) or "invalid or loading"
			print("  " .. itemid .. " (" .. itemname .. ") to " .. character )
		end
		print("Profiles:")
		for profile, v in pairs(MasterLootDistribute_Profiles) do
			print("  " .. profile)
		end
	elseif cmd == "reset" 
	then
		MasterLootDistribute_Profiles = {}
		print("All profiles deleted.")
	elseif cmd == "save" 
	then
		MasterLootDistribute_Profiles[args] = MasterLootDistribute_Current
		print("Profile '" .. args .. "' saved.")
	elseif cmd == "load" 
	then
		if MasterLootDistribute_Profiles[args]
		then
			MasterLootDistribute_Current = MasterLootDistribute_Profiles[args]
			print("Profile '" .. args .. "' loaded.")
		else
			print("No such profile!")
		end
	elseif cmd == "clear" 
	then
		MasterLootDistribute_Current = {}
		print("Current cleared.")
	elseif cmd == "add" 
	then
		local _, _, itemid, character = string.find(args, "(%d+)%s+(.*)")
		if itemid and character
		then
			MasterLootDistribute_Current[itemid] = character
			print("Item " .. args .. " added to current.")
		else
			print("Invalid argument.")
		end
	elseif cmd == "del" 
	then
		MasterLootDistribute_Current[args] = nil
		print("Item " .. args .. " deleted from current.")
	elseif cmd == "autoloot" 
	then
		if (args=="on")
		then
			autoloot = true
			MasterLootDistribute_OnLootMethodChanged()
		else
			autoloot = false
			MasterLootDistribute_OnLootMethodChanged()
		end
	else
		print("Syntax: " .. SLASH_MasterLootDistribute1 .. " ( print | reset | save name | load name | clear | add itemid character | del itemid | autoloot on/off )");
	end
end

local function Init()
	if (not addon_loaded)
	then
		addon_loaded = true
		MasterLootDistribute_Profiles = MasterLootDistribute_Profiles or {}
		SlashCmdList[MasterLootDistribute_Addon] = ProcessCommand
		MasterLootDistribute_OnLootMethodChanged()
	end
end

local function OnReadyCheck()
	SlackerCore.DoRecording("Ready Check")
end

local function OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == MasterLootDistribute_Addon
	then
		Init()
    elseif event == "PARTY_LOOT_METHOD_CHANGED" 
	then
        MasterLootDistribute_OnLootMethodChanged()
    elseif event == "LOOT_READY" 
	then
        MasterLootDistribute_OnLootReady()
	end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
frame:SetScript("OnEvent", OnEvent)



