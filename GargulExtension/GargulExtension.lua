local ADDON, T = ...
local L = {}

local GL = nil

local function TMBImport(self, data, triedToDecompress)
	local firstLine = data:match("[^\n]+");
	-- TMB Tooltip format
	if (GL:strStartsWith(strtrim(firstLine), 'type,character_name,character_class')) then
		
		local datatable =  {
			["groups"] = { ["1"] = "Placeholder" },
			["loot"] = "",
			["notes"] = {},
			["tiers"] = {},
			["wishlists"] = {},
			["received"] = {},
			["stats"] = {},
		}
		
		local first = true
		for line in data:gmatch("[^\n]+") do
			-- Skip headers
			if (not first) then
				(function ()
					
					local CSVParts;
					CSVParts = GL:strSplit(line, ",");

					-- We can't handle this line it seems
					if (not CSVParts[2] or CSVParts[1] ~= "wishlist") then
						return;
					end
					
					local characterName = CSVParts[2]:lower()
					local order = CSVParts[7]
					local typ = GL.Data.Constants.tmbTypeWish -- tmbTypePrio
					local raidGroupID = "1"
					local itemID = CSVParts[8]
					local received = CSVParts[10] ~= ""
					local offspec = CSVParts[9] == "1"
					
					if offspec
					then
						characterName = characterName .. "(OS)"
					end
					
					if (not itemID) then
						return;
					end
					
					local key = received and "received" or "wishlists"
					
					local entry = table.concat({characterName, order, raidGroupID, typ}, "|")
					
					if not datatable[key][itemID]
					then
						datatable[key][itemID] = {}
					end
					table.insert(datatable[key][itemID], entry)
					
					if not datatable["stats"][characterName]
					then
						datatable["stats"][characterName] = { ["received"] = 0, ["wishlists"] = 0 }
					end
					datatable["stats"][characterName][key] = datatable["stats"][characterName][key] + 1
					
				end)()
			end
			first = false
		end
		
		local jsonEncodeSucceeded, WebsiteData = pcall(function () return GL.JSON:encode(datatable); end);
		if jsonEncodeSucceeded
		then
			local ret = L.TMBImportOriginal(self, WebsiteData, true)
			GL.DB.TMB.MetaData.stats = datatable.stats
			return ret
		end
	end
	local ret = L.TMBImportOriginal(self, data, triedToDecompress)
	GL.DB.TMB.MetaData.stats = nil
	return ret
end

local function CountForItem(itemID)
	local count = 0

    for bag = 0, 10 do
        for slot = 1, GetContainerNumSlots(bag) do
            local _, itemCount, locked, _, _, _, _, _, _, bagItemID = GetContainerItemInfo(bag, slot);

            if (bagItemID == itemID
                and not locked -- The item is locked, aka it can not be put in the window
                and (GL:inventoryItemTradeTimeRemaining(bag, slot) > 0) -- The item is tradeable
            ) then
                count = count + itemCount
            end
        end
    end

    return count;
end


local function MasterLooterUIDraw(self, itemLink)
	local ret = L.MasterLooterUIDrawOriginal(self, itemLink)
	
	local Window = GL.MasterLooterUI.InterfaceItems.Frame.Window
	local AceGUI = GL.AceGUI;
	
    local ItemIcon = GL.Interface:getItem(self, "Icon.Item")
	ItemIcon:SetCallback("OnClick", function()
		local itemLink = GL.Interface:getItem(self, "EditBox.Item"):GetText()
		local itemID = GL:getItemIdFromLink(itemLink)
		local TMBInfo = GL.TMB:byItemLink(itemLink)
		
		if (GL:empty(TMBInfo)) then
			return
		end
	
		
		local WishListEntries = {}
		local itemIsOnSomeonesWishlist = false
		for _, Entry in pairs(TMBInfo) do
			local playerName = GL:capitalize(Entry.character)
			local prio = Entry.prio
			local sortingOrder = prio
			local stats = GL.DB.TMB.MetaData.stats and GL.DB.TMB.MetaData.stats[Entry.character:lower()]
			stats = (stats and IsModifierKeyDown()) and string.format("(%d/%d)", stats["received"], stats["wishlists"]+stats["received"]) or ""
			table.insert(WishListEntries, {sortingOrder, string.format("%s[%s]%s", playerName, prio, stats)})
			itemIsOnSomeonesWishlist = true;
		end

		if itemIsOnSomeonesWishlist
		then
			local join = {}
			local count = CountForItem(itemID)
			table.sort(WishListEntries, function (a, b)
				return a[1] < b[1];
			end);
			for _, Entry in pairs(WishListEntries) do
				join[#join+1]=Entry[2]
			end
			if count > 1
			then
				itemLink = itemLink .. "x" .. count
			end
			local msg = itemLink .. " " .. table.concat(join, ", ")
			GL:sendChatMessage(msg, "OFFICER", nil, nil, false)
		end
	end)
				
	return ret
end

local function SendChatMessage(self, message, chatType, language, channel, stw)
	if message == "Stop your rolls!"
	then
		chatType = GL.User.isInRaid and "RAID" or "PARTY"
	end
	local ret = L.SendChatMessageOriginal(self, message, chatType, language, channel, false)
	return ret
end

local function Init()
	GL = _G["Gargul"]
	L.TMBImportOriginal = GL.TMB.import
	GL.TMB.import = TMBImport
	L.MasterLooterUIDrawOriginal = Gargul.MasterLooterUI.draw
	GL.MasterLooterUI.draw = MasterLooterUIDraw
	L.SendChatMessageOriginal = GL.sendChatMessage
	GL.sendChatMessage = SendChatMessage
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

-- TODO: blizzard like roll frame RollerUI.lua