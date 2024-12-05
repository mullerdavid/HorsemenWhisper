local ADDON, T = ...
local L = {}

ItemRackWeaponMod = {}

local GetContainerNumSlots = _G.GetContainerNumSlots or C_Container.GetContainerNumSlots
local GetItemCooldown = _G.GetItemCooldown or C_Container.GetItemCooldown


local slot_mh = GetInventorySlotInfo("MainHandSlot")
local slot_oh = GetInventorySlotInfo("SecondaryHandSlot")
local slot_ran = GetInventorySlotInfo("RangedSlot")

local HiddenTooltip = CreateFrame("GameTooltip", "ItemRackWeaponModTooltip", nil, "GameTooltipTemplate")
HiddenTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
HiddenTooltip:SetScript("Onload", function(self) self:SetOwner(WorldFrame, "ANCHOR_NONE") end)
for i=1,32 do
	HiddenTooltip:AddFontStrings(
		HiddenTooltip:CreateFontString( "$parentTextLeft"..i, nil, "GameTooltipText" ),
		HiddenTooltip:CreateFontString( "$parentTextRight"..i, nil, "GameTooltipText" )
	)
end

function ItemRackWeaponMod:CreateMenuHook()
end

function ItemRackWeaponMod:CreateButtonHook()
end

local WeaponBuildMenu
local SetTempEnchantIcon
local ExtractTempEnchName
local UpdateTempEnchantsEquipped

local function GetMenuItems(id)
	local menu = {}
	
	local function AddToMenuBag(bag, slot, id)
		local item = {}
		item.type = "bag"
		item.bag = bag
		item.slot = slot
		item.id = id
		table.insert(menu, item)
	end
	
	for i=0,4 do
		for j=1,GetContainerNumSlots(i) do
			itemID = ItemRack.GetID(i,j)
			itemName,itemTexture,equipSlot = ItemRack.GetInfoByID(itemID)
			if ItemRack.SlotInfo[id][equipSlot] and ItemRack.PlayerCanWear(id,i,j) and (ItemRackSettings.HideTradables=="OFF" or ItemRack.IsSoulbound(i,j)) then
				if itemID~=0 then
					AddToMenuBag(i, j, itemID)
				end
			end
		end
	end
	
	return menu
end

local Menu = {}

local function GetOrCreateMenuFrame(id)
	local parent_str = "ItemRackButton"..id
	local parent = _G[parent_str]
	local menu_str = parent_str.."Menu"
	local menu = _G[menu_str]
	if not menu
	then	
		local proxy_str = parent_str.."Proxy"
		local proxy = CreateFrame("Button", proxy_str, parent, "SecureActionButtonTemplate,SecureFrameTemplate,SecureHandlerBaseTemplate")
		parent.Proxy = proxy
		menu = CreateFrame("Frame", menu_str, proxy, "SecureFrameTemplate,SecureHandlerEnterLeaveTemplate")
		menu.Buttons = {}
		proxy.Menu = menu
		proxy:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
		proxy:SetAllPoints(parent)
		proxy:RegisterForClicks("AnyDown")
		proxy:SetFrameRef("menu", menu)
		proxy:SetFrameRef("parent", parent)
		
		proxy:WrapScript(proxy, "OnEnter", [=[ -- self
			local MenuOnShift = self:GetAttribute("MenuOnShift")
			local MenuOnRight = self:GetAttribute("MenuOnRight")
			if MenuOnRight ~= "ON" and (MenuOnShift ~= "ON" or IsShiftKeyDown())
			then
				local menu = self:GetFrameRef("menu")
				menu:Show()
			end
		]=])
		proxy:WrapScript(proxy, "OnClick", [=[ -- self, button, down
			local MenuOnRight = self:GetAttribute("MenuOnRight")
			if MenuOnRight ~= "ON"
			then
				local mtext = self:GetAttribute("*macrotext1")
				self:SetAttribute("*macrotext2", mtext.." RightButton")
			else
				self:SetAttribute("*macrotext2", "")
				if button == "RightButton"
				then
					local menu = self:GetFrameRef("menu")
					if menu:IsShown()
					then
						menu:Hide()
					else
						menu:Show()
					end
				end
			end
		]=])
		proxy:HookScript('OnEnter', function() ItemRack.OnEnterButton(parent) ItemRackMenuFrame:Hide() WeaponBuildMenu(id)  end)
		proxy:HookScript('OnLeave', function() ItemRack.ClearTooltip(parent) end)
		proxy:WrapScript(proxy, "OnLeave", [=[ -- self
			local menu = self:GetFrameRef("menu")
			if not menu:IsUnderMouse()
			then
				menu:Hide()
			end
		]=])
		proxy:WrapScript(proxy, "OnHide", [=[ -- self
			local menu = self:GetFrameRef("menu")
			menu:Hide()
		]=])
		proxy:SetAttribute("*type1", "macro")
		proxy:SetAttribute("*type2", "macro")
		proxy:SetAttribute("*macrotext1", "/click "..parent:GetName())
		
		proxy:SetAttribute("MenuOnShift", ItemRackSettings.MenuOnShift)
		proxy:SetAttribute("MenuOnRight", ItemRackSettings.MenuOnRight)
		
		--Debug
		RegisterStateDriver(proxy, "visibility", "[combat,nomod:alt] show; hide")
		--RegisterStateDriver(proxy, "visibility", "[combat,nomod:alt][mod:ctrl,nomod:alt] show; hide")
		
		menu:SetFrameStrata("HIGH")
		menu:EnableMouse(true) 
		menu:IsMovable(false) 
		menu:Hide()
		menu:SetClampedToScreen(true)
		menu:SetToplevel(true) 
		menu:SetSize(64,64) 
		menu:SetID(id)
		
		menu:SetFrameRef("proxy", proxy)
		menu:SetAttribute("_onleave", [=[ -- self
			local proxy = self:GetFrameRef("proxy")
			local menu = self
			if not proxy:IsUnderMouse() and not menu:IsUnderMouse()
			then
				menu:Hide()
			end
		]=])
		
		
		for name, func in pairs(Menu)
		do
			if not menu[name]
			then
				menu[name] = Menu[name]
			end
		end
		
		ItemRackWeaponMod.CreateMenuHook(menu)
	end
	
	return menu
end

local Button = {}

function Menu:GetOrCreateButton(i)
	local id = self:GetID()
	local menu_str = self:GetName()
	local button_str = menu_str..i
	local button = _G[button_str]
	if not button
	then
		button = CreateFrame("Button", button_str, self, "SecureHandlerBaseTemplate,SecureHandlerEnterLeaveTemplate,ActionButtonTemplate,SecureActionButtonTemplate")
		button:SetID(i)
		button:SetFrameStrata("HIGH")
		button:SetToplevel(true) 
		button:SetFrameLevel(self:GetFrameLevel()+1)
		
		button:WrapScript(button, "OnClick", [=[ -- self, button, down
			self:GetParent():Hide()
		]=])
		button:SetFrameRef("proxy", self:GetParent())
		button:SetFrameRef("menu", self)
		button:SetAttribute("_onleave", [=[ -- self
			local proxy = self:GetFrameRef("proxy")
			local menu = self:GetFrameRef("menu")
			if not proxy:IsUnderMouse() and not menu:IsUnderMouse()
			then
				menu:Hide()
			end
		]=])
		
		button:SetAttribute("type", "macro")
		button:SetAttribute("macrotext", "")
	
		button:SetScript("OnEnter",function(self)
			local bag = self:GetAttribute("bag")
			local slot = self:GetAttribute("slot")
			if bag and slot
			then
				ItemRack.AnchorTooltip(self)
				GameTooltip:SetBagItem(bag, slot)
				ItemRack.ShrinkTooltip(self)
				GameTooltip:Show()
			end
		end)
		button:SetScript("OnLeave",function(self) 
			GameTooltip:Hide()
		end)
		
		table.insert(self.Buttons, button)
		
		for name, func in pairs(Button)
		do
			if not button[name]
			then
				button[name] = Button[name]
			end
		end
		
		ItemRackWeaponMod.CreateButtonHook(button)
	end
	
	return button
end

function Menu:HideButtons()
	local id = self:GetID()
	local menu_str = self:GetName()
	local button
	local i = 1
	while true
	do
		local button_str = menu_str..i
		button = _G[button_str]
		if button
		then
			button:Hide()
		else
			break
		end
		i = i + 1
    end
end

function Button:SetBagSlot(bag, slot)
	local id = self:GetParent():GetID()
	local macrotext
	-- /equip and /equipslot is grabbing the wrong item with multiple identical items, just different temporary enchants
	-- /use is picking the correct item, but can not be used to put in offhand usually
	if id == slot_oh
	then
		macrotext = "/equipslot "..id.." "..bag.." "..slot
	else
		macrotext = "/use "..bag.." "..slot
	end
	self:SetAttribute("macrotext", macrotext)
	self:SetAttribute("bag", bag)
	self:SetAttribute("slot", slot)
end

function Button:UpdateIcon()
	if self:IsShown()
	then
		local id = self:GetParent():GetID()
		local bag = self:GetAttribute("bag")
		local slot = self:GetAttribute("slot")
		if bag and slot
		then
			local itemID = ItemRack.GetID(bag,slot)
			local itemName,itemTexture,equipSlot = ItemRack.GetInfoByID(itemID)
			local good = ItemRack.SlotInfo[id][equipSlot] and ItemRack.PlayerCanWear(id,bag,slot)
			self.icon:SetTexture(itemTexture)
			self.icon:SetDesaturated(not good)
			
			baseID = tonumber(ItemRack.GetIRString(itemID,true))
			if baseID and baseID>0 then
				CooldownFrame_Set(self.cooldown,GetItemCooldown(baseID))
			else
				self.cooldown:Hide()
			end
		end
		
		HiddenTooltip:ClearLines()
		HiddenTooltip:SetBagItem(bag, slot)
		local name, shortname = ExtractTempEnchName(HiddenTooltip)
		SetTempEnchantIcon(self, name, shortname)
	end
end

local function WeaponBuildMenuNoCombat(id)
	
	local items = GetMenuItems(id)
	local menu = GetOrCreateMenuFrame(id)
	local proxy = menu:GetParent()
	
	proxy:SetAttribute("MenuOnShift", ItemRackSettings.MenuOnShift)
	proxy:SetAttribute("MenuOnRight", ItemRackSettings.MenuOnRight)
	
	local max_cols = 1
	local numitems = #items
	local extra = (not ItemRack.BankOpen and ItemRackSettings.AllowEmpty=="ON") and 1 or 0

	if ItemRackUser.SetMenuWrap=="ON" then
		max_cols = ItemRackUser.SetMenuWrapValue
	elseif (numitems+extra)>24 then
		max_cols = 5
	elseif (numitems+extra)>18 then
		max_cols = 4
	elseif (numitems+extra)>9 then
		max_cols = 3
	elseif (numitems+extra)>4 then
		max_cols = 2
	end
	
	local menuDock = "BOTTOMLEFT"
	local mainDock = "TOPLEFT"
	local menuOrient = "VERTICAL"
	if ItemRackUser.Buttons[id]
	then
		local parent = ItemRack.FindParent(id)
		menuDock = ItemRackUser.Buttons[parent].MenuDock or menuDock
		mainDock = ItemRackUser.Buttons[parent].MainDock or mainDock
		menuOrient = ItemRackUser.Buttons[parent].MenuOrient or menuOrient
	end
	local currentDock = mainDock..menuDock
	local xstart, ystart = ItemRack.DockInfo[currentDock].xstart, ItemRack.DockInfo[currentDock].ystart
	local xoff, yoff = ItemRack.DockInfo[currentDock].xoff, ItemRack.DockInfo[currentDock].yoff
	local xdir, ydir = ItemRack.DockInfo[currentDock].xdir, ItemRack.DockInfo[currentDock].ydir
	
	menu:ClearAllPoints()
	menu:HideButtons()
	menu:SetPoint(menuDock,menu:GetParent(),mainDock,xoff,yoff)
	menu:SetScale(ItemRackUser.MenuScale)
			
	if 0<numitems then	
		local col,row = 0,0
		local xpos, ypos = xstart, ystart
		for i=1,numitems do
			button = menu:GetOrCreateButton(i)
			button:SetPoint("TOPLEFT",menu,menuDock,xpos,ypos)
			if menuOrient=="VERTICAL" then
				xpos = xpos + xdir*40
				col = col + 1
				if col==max_cols then
					xpos = xstart
					col = 0
					ypos = ypos + ydir*40
					row = row + 1
				end
			else
				ypos = ypos + ydir*40
				col = col + 1
				if col==max_cols then
					ypos = ystart
					col = 0
					xpos = xpos + xdir*40
					row = row + 1
				end
			end
			
			bag = items[i].bag
			slot = items[i].slot
			button:SetBagSlot(bag, slot)
			button:Show()
		end
		
		if col==0 then
			row = row-1
		end

		if menuOrient=="VERTICAL" then
			menu:SetWidth(12+(max_cols*40))
			menu:SetHeight(12+((row+1)*40))
		else
			menu:SetWidth(12+((row+1)*40))
			menu:SetHeight(12+(max_cols*40))
		end
		
	end
end

local function WeaponUpdateMenu(id)
	local parent_str = "ItemRackButton"..id
	local parent = _G[parent_str]
	
	for i,button in ipairs(parent.Proxy.Menu.Buttons)
	do 
		button:UpdateIcon()
	end
end


local lastcache
-- Called every time before buildmenu AddToMenu somewhere
local function HookGetID()
	lastcache = nil
end

-- Called every time on bags and bank
local function HookPlayerCanWear(invID,bag,slot)
	if not ItemRack.BankOpen then
		if invID==slot_mh or invID==slot_oh or invID==slot_ran
		then
			lastcache = {}
			lastcache.bag = bag
			lastcache.slot = slot
		end
	end
end

local menucache = {}
local function HookAddToMenu(itemID)
	-- Same condition
	if ItemRackSettings.AllowHidden=="OFF" or (IsAltKeyDown() or not ItemRack.IsHidden(itemID)) then
		menucache[#ItemRack.Menu]=lastcache -- no need to delete, items are overriden
	end
end

local function HookBuildMenu()
	for i=1,#(ItemRack.Menu) 
	do
		local button = _G["ItemRackMenu"..i]
		if button:IsShown() 
		then
			local name, shortname
			if ItemRack.Menu[i]~=0 and menucache[i]
			then
				HiddenTooltip:ClearLines()
				HiddenTooltip:SetBagItem(menucache[i].bag, menucache[i].slot)
				name, shortname = ExtractTempEnchName(HiddenTooltip)
			end
			SetTempEnchantIcon(button, name, shortname)
		end
	end
end

WeaponBuildMenu = function(id)
	if not InCombatLockdown()
	then
		WeaponBuildMenuNoCombat(id)
	else
		if ItemRack.WeaponBuildAllMenu and ItemRack.RunAfterCombat
		then
			local found = false
			for i=1,#(ItemRack.RunAfterCombat) do
				if ItemRack.RunAfterCombat[i]=="WeaponBuildAllMenu"
				then
					found = true
					break
				end
			end
			if not found
			then
				table.insert(ItemRack.RunAfterCombat,"WeaponBuildAllMenu")
			end
		end
	end
	
	WeaponUpdateMenu(id)
end

local function WeaponBuildAllMenu()
	WeaponBuildMenu(slot_mh)
	WeaponBuildMenu(slot_oh)
	WeaponBuildMenu(slot_ran)
end

local initialized = false

local function WeaponInitButtons()
	initialized = true
	WeaponBuildAllMenu()
	ItemRack.WeaponBuildAllMenu = WeaponBuildAllMenu
end

local function WeaponUpdateButtonCooldowns()
	if not initialized then return end
	WeaponUpdateMenu(slot_mh)
	WeaponUpdateMenu(slot_oh)
	WeaponUpdateMenu(slot_ran)
end

local timer
local function WeaponRebuildAllMenu()
	if not initialized then return end
	if timer
	then
		timer:Cancel()
	end
	timer = C_Timer.NewTimer(0.1, WeaponBuildAllMenu)
end

local function Init()
	UpdateTempEnchantsEquipped()
	
	hooksecurefunc(ItemRack, "InitButtons", WeaponInitButtons)
	hooksecurefunc(ItemRack, "OnUnitInventoryChanged", WeaponRebuildAllMenu)
	hooksecurefunc(ItemRack, "OnBankClose", WeaponRebuildAllMenu)
	hooksecurefunc(ItemRack, "UpdateButtonCooldowns", WeaponUpdateButtonCooldowns)

	hooksecurefunc(ItemRack, "PlayerCanWear", HookPlayerCanWear)
	hooksecurefunc(ItemRack, "AddToMenu", HookAddToMenu)
	hooksecurefunc(ItemRack, "GetID", HookGetID)
	hooksecurefunc(ItemRack, "BuildMenu", HookBuildMenu)
end

local function InitOptions()
	hooksecurefunc(ItemRackOpt, "OptListCheckButtonOnClick", WeaponRebuildAllMenu)
end
		
local initmain = false
local initopts = false
local function OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON
	then
		Init()
		initmain = true
	elseif event == "ADDON_LOADED" and arg1 == "ItemRackOptions"
	then
		InitOptions()
		initopts = true
	end
	if initmain and initopts
	then
		self:UnregisterEvent("ADDON_LOADED")
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)

local frameupdate = CreateFrame("Frame")
frameupdate:RegisterEvent("BAG_UPDATE")
frameupdate:SetScript("OnEvent", WeaponRebuildAllMenu)

local function RemoveTime(str)
	local replaced, _ = string.gsub(str, "%s?%(%d+%D+%)%s*$", "")
	return replaced
end

ExtractTempEnchName = function(tooltip)
	for i,region in ipairs({ tooltip:GetRegions() })
	do
		if( region:IsObjectType("FontString") )
		then
			-- logic from WeakAuras
			local text = region:GetText();
            if(text) 
			then
                local _, _, name, shortenedName = text:find("^((.-) ?+?[VIX%d]*) ?%(%d+%D+%)$");
                if(name and name ~= "" and not string.find(name, ":")) then
					return RemoveTime(name), RemoveTime(shortenedName);
                end
                _, _, name, shortenedName = text:find("^((.-) ?+?[VIX%d]*)%（%d+.%D%）$");
                if(name and name ~= "" and not string.find(name, ":")) then
					return RemoveTime(name), RemoveTime(shortenedName);
                end
            end
        end
    end
	return
end

SetTempEnchantIcon = function(parent, name, shortname)
	if not parent.TempEnchant
	then
		local fname = parent:GetName() and parent:GetName().."TempEnchant" or nil
		local frame = CreateFrame("Frame", fname, parent)
		parent.TempEnchant = frame
		frame:SetSize(16,16)
		frame:SetPoint("BOTTOMRIGHT", 2, -2)
		frame:EnableMouse(false)
		local icon = frame:CreateTexture(nil, "OVERLAY")
		frame.Icon = icon
		icon:SetAllPoints()
	end
	
	if name or shortname
	then
		local icon
		if name
		then
			icon = T.TempEnchantsDB[name]
		end
		if not icon and shortname
		then
			icon = T.TempEnchantsDB[shortname]
		end
		if not icon and name and string.find(name, "Fishing Lure")
		then
			icon = T.TempEnchantsDB[shortname]
		end
		icon = icon or 134400 -- inv-misc-questionmark
		
		parent.TempEnchant.Icon:SetTexture(icon)
		parent.TempEnchant:Show()
	else
		parent.TempEnchant:Hide()
	end
end

UpdateTempEnchantsEquipped = function()
	for _,id in ipairs({slot_mh, slot_oh, slot_ran})
	do
		HiddenTooltip:ClearLines()
		HiddenTooltip:SetInventoryItem("player", id)
		local name, shortname = ExtractTempEnchName(HiddenTooltip)
		SetTempEnchantIcon(_G["ItemRackButton"..id], name, shortname)
	end
end

local timer_tench
local function UpdateTempEnchantsEquippedDelayed()
	if timer_tench
	then
		timer_tench:Cancel()
	end
	timer_tench = C_Timer.NewTimer(0.1, UpdateTempEnchantsEquipped)
end

local frametench = CreateFrame("Frame")
frametench:RegisterEvent("UNIT_INVENTORY_CHANGED")
frametench:RegisterEvent("PLAYER_ENTERING_WORLD")
frametench:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frametench:SetScript("OnEvent", UpdateTempEnchantsEquippedDelayed)
