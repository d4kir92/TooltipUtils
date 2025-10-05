local _, TooltipUtils = ...
local DEBUG = false
local tooltips = {GameTooltip, ItemRefTooltip, WhatevahTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ShoppingTooltip1, ShoppingTooltip2}
local invToSlot = {}
invToSlot["INVTYPE_HEAD"] = 1
invToSlot["INVTYPE_NECK"] = 2
invToSlot["INVTYPE_SHOULDER"] = 3
invToSlot["INVTYPE_BODY"] = 4
invToSlot["INVTYPE_CHEST"] = 5
invToSlot["INVTYPE_ROBE"] = 5
invToSlot["INVTYPE_WAIST"] = 6
invToSlot["INVTYPE_LEGS"] = 7
invToSlot["INVTYPE_FEET"] = 8
invToSlot["INVTYPE_WRIST"] = 9
invToSlot["INVTYPE_HAND"] = 10
invToSlot["INVTYPE_FINGER"] = 11
invToSlot["INVTYPE_TRINKET"] = 13
invToSlot["INVTYPE_CLOAK"] = 15
invToSlot["INVTYPE_WEAPON"] = 16
invToSlot["INVTYPE_2HWEAPON"] = 16
invToSlot["INVTYPE_HOLDABLE"] = 16
invToSlot["INVTYPE_RANGED"] = 18
invToSlot["INVTYPE_RANGEDRIGHT"] = 18
invToSlot["INVTYPE_TABARD"] = 19
invToSlot["INVTYPE_NON_EQUIP_IGNORE"] = false
invToSlot["INVTYPE_BAG"] = false
local missingOnce = {}
local msgPrefix = "TOTUD4"
function TooltipUtils:AddDoubleLine(tt, textLeft, textRight, noIcon)
    if noIcon then
        tt:AddDoubleLine(textLeft, textRight)
    else
        tt:AddDoubleLine("|T298591:16:16:0:0|t " .. textLeft, textRight)
    end
end

function TooltipUtils:SendMsg(typ, key, value, chatType, target)
    local message = typ .. ";" .. key .. ";" .. (value or "")
    if DEBUG then
        chatType = "SAY"
        print("[DEBUG]", message, chatType)
    end

    local success = C_ChatInfo.SendAddonMessage(msgPrefix, message, chatType, target)
    if not success then
        TooltipUtils:INFO("SendMsg FAILED", chatType, message)
    end
end

function TooltipUtils:PlyTab(unitId)
    local guid = UnitGUID(unitId)
    if guid == nil then return false end
    if string.find(guid, "Player", 1, true) == nil then return false end
    if unitId ~= "player" and UnitInParty(unitId) == false then return false end
    TOUT["units"][guid] = TOUT["units"][guid] or {}

    return true
end

local xpBar = nil
function TooltipUtils:AddXPBar(tt, unitId)
    if TooltipUtils:PlyTab(unitId) then
        local guid = UnitGUID(unitId)
        TOUT["units"][guid]["curxp"] = 0
        TOUT["units"][guid]["maxxp"] = 1
        local cur = UnitXP(unitId)
        local max = UnitXPMax(unitId)
        local per = cur / max * 100
        if xpBar == nil then
            local sw = 10
            local sh = 22
            xpBar = CreateFrame("StatusBar", nil, tt)
            xpBar:SetSize(sw, sh)
            xpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            xpBar:SetStatusBarColor(0, 0.5, 1)
            xpBar:SetPoint("TOPLEFT", tt, "TOPLEFT", 4, 4 + sh)
            xpBar:SetPoint("TOPRIGHT", tt, "TOPRIGHT", -4, 4 + sh)
            xpBar.Bg = xpBar:CreateTexture(nil, "BACKGROUND")
            xpBar.Bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
            xpBar.Bg:SetAllPoints()
            xpBar.Bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
            xpBar.textCenter = xpBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            xpBar.textCenter:SetPoint("CENTER")
            xpBar.textCenter:SetJustifyH("CENTER")
            xpBar.textCenter:SetJustifyV("MIDDLE")
            xpBar.textLeft = xpBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            xpBar.textLeft:SetPoint("LEFT", 4, 0)
            xpBar.textLeft:SetJustifyH("LEFT")
            xpBar.textLeft:SetJustifyV("MIDDLE")
            xpBar.textRight = xpBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            xpBar.textRight:SetPoint("RIGHT", -4, 0)
            xpBar.textRight:SetJustifyH("RIGHT")
            xpBar.textRight:SetJustifyV("MIDDLE")
        end

        xpBar:SetMinMaxValues(0, max)
        xpBar:SetValue(cur)
        xpBar.textCenter:SetText(string.format("%s: %0.2f%%", XP, per))
        xpBar.textLeft:SetText(AbbreviateNumbers(cur, true))
        xpBar.textRight:SetText(AbbreviateNumbers(max, true))
        xpBar:Show()
    end
end

function TooltipUtils:GetItemTooltipText(itemLink)
    local tooltip = CreateFrame("GameTooltip", "MyScanningTooltip", nil, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)
    local lines = {}
    for i = 1, tooltip:NumLines() do
        local left = _G["MyScanningTooltipTextLeft" .. i]
        local right = _G["MyScanningTooltipTextRight" .. i]
        if left then
            table.insert(lines, {left:GetText(), right:GetText()})
        end
    end

    return lines
end

local comparers = {}
local comparers2 = {}
function TooltipUtils:AddComparer(tab, i, itemLink, unitId)
    if itemLink == nil then return end
    local parent = GameTooltip
    if GameTooltip:GetLeft() and ShoppingTooltip1:GetLeft() and GameTooltip:GetLeft() < ShoppingTooltip1:GetLeft() then
        parent = ShoppingTooltip1
    end

    if i > 1 then
        parent = tab[i - 1]
    end

    if tab[i] == nil then
        local name = "Comparer" .. i
        if tab == comparers2 then
            name = name .. "_2"
        end

        tab[i] = CreateFrame("GameTooltip", name, GameTooltip:GetParent(), "GameTooltipTemplate")
        local comparer = tab[i]
        hooksecurefunc(
            GameTooltip,
            "Hide",
            function()
                comparer:Hide()
            end
        )
    end

    tab[i]:SetOwner(parent, "ANCHOR_NONE")
    tab[i]:ClearAllPoints()
    if i == 1 then
        if tab == comparers2 then
            tab[i]:SetPoint("BOTTOMLEFT", parent, "TOPRIGHT", 10, 0)
        else
            tab[i]:SetPoint("TOPLEFT", parent, "TOPRIGHT", 10, 0)
        end
    else
        tab[i]:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end

    tab[i]:SetScale(GameTooltip:GetScale())
    tab[i]:SetHyperlink(itemLink)
    tab[i]:AddLine("   ")
    tab[i]:AddDoubleLine(COMMUNITY_MEMBER_ROLE_NAME_OWNER or "OWNER", UnitName(unitId))
    tab[i]:Show()
end

function TooltipUtils:OnTooltipSetItem(tt, ...)
    if tt == nil then return end
    if tt.GetID == nil then
        TooltipUtils:MSG("[OnTooltipSetItem] GetID not available")

        return
    end

    if tt.GetItem == nil then
        TooltipUtils:MSG("[OnTooltipSetItem] GetItem not available")

        return
    end

    local item, link = tt:GetItem()
    local itemLink = link or item
    if itemLink then
        local ItemLink = select(2, C_Item.GetItemInfo(itemLink)) or itemLink
        if ItemLink then
            local IconID = select(10, TooltipUtils:GetItemInfo(ItemLink))
            if IconID and TOUT["SHOWICONID"] then
                TooltipUtils:AddDoubleLine(tt, "IconID", IconID)
            end

            local ItemID = GetItemInfoFromHyperlink(ItemLink)
            if ItemID and TOUT["SHOWITEMID"] then
                TooltipUtils:AddDoubleLine(tt, "ItemID", ItemID)
            end

            local SpellID = select(2, C_Item.GetItemSpell(ItemLink))
            if SpellID and TOUT["SHOWSPELLID"] then
                TooltipUtils:AddDoubleLine(tt, "SpellID", SpellID)
            end

            local slotId = nil
            for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
                if GetInventoryItemLink("player", i) == itemLink then
                    slotId = i
                    break
                end
            end

            if slotId and TOUT["SHOWSLOTID"] then
                TooltipUtils:AddDoubleLine(tt, "SlotId", slotId)
            end

            local equipmentSlotName = select(9, C_Item.GetItemInfo(itemLink))
            if slotId == nil and equipmentSlotName then
                if invToSlot[equipmentSlotName] == nil then
                    if missingOnce[equipmentSlotName] == nil then
                        missingOnce[equipmentSlotName] = true
                        TooltipUtils:INFO("MISSING INVTYPE [" .. equipmentSlotName .. "]")
                    end
                else
                    slotId = invToSlot[equipmentSlotName]
                end
            end

            local slotId2 = nil
            if slotId == 11 then
                slotId2 = 12
            elseif slotId == 12 then
                slotId2 = 11
            elseif slotId == 13 then
                slotId2 = 14
            elseif slotId == 14 then
                slotId2 = 13
            elseif slotId == 16 then
                slotId2 = 17
            elseif slotId == 17 then
                slotId2 = 16
            end

            if tt == GameTooltip then
                if IsShiftKeyDown() and TOUT["SHOWPARTYITEMS"] then
                    for i = 1, 4 do
                        local partyUnit = "party" .. i
                        if DEBUG then
                            partyUnit = "player"
                        end

                        if UnitExists(partyUnit) and TOUT["units"][UnitGUID(partyUnit)] then
                            local slots = TOUT["units"][UnitGUID(partyUnit)]["slots"]
                            if slots and itemLink then
                                if slotId and slots[slotId] then
                                    local slotLink = select(2, C_Item.GetItemInfo(slots[slotId]))
                                    if slotLink then
                                        TooltipUtils:AddComparer(comparers, i, slotLink, partyUnit)
                                    end
                                end

                                if slotId2 and slots[slotId2] then
                                    local slotLink = select(2, C_Item.GetItemInfo(slots[slotId2]))
                                    if slotLink then
                                        TooltipUtils:AddComparer(comparers2, i, slotLink, partyUnit)
                                    end
                                end
                            end
                        end
                    end
                else
                    for i, v in pairs(comparers) do
                        v:Hide()
                    end

                    for i, v in pairs(comparers2) do
                        v:Hide()
                    end
                end
            end
        end
    end
end

function TooltipUtils:OnTooltipSetSpell(tt, ...)
    if tt == nil then return end
    if tt.GetID == nil then
        TooltipUtils:MSG("[OnTooltipSetSpell] GetID not available")

        return
    end

    if tt.GetSpell == nil then
        TooltipUtils:MSG("[OnTooltipSetSpell] GetSpell not available")

        return
    end

    local spellID = select(2, tt:GetSpell())
    if spellID then
        local IconID = select(3, TooltipUtils:GetSpellInfo(spellID))
        if IconID and TOUT["SHOWICONID"] then
            TooltipUtils:AddDoubleLine(tt, "IconID", IconID)
        end

        local SpellID = select(7, TooltipUtils:GetSpellInfo(spellID))
        if SpellID and TOUT["SHOWSPELLID"] then
            TooltipUtils:AddDoubleLine(tt, "SpellID", SpellID)
        end
    end
end

function TooltipUtils:OnTooltipSetUnit(tt, ...)
    if tt == nil then return end
    if tt.GetUnit == nil then
        TooltipUtils:MSG("[OnTooltipSetUnit] GetUnit not available")

        return
    end

    local _, unitId = tt:GetUnit()
    if unitId == nil then
        if xpBar then
            xpBar:Hide()
        end

        return
    end

    TooltipUtils:PlyTab(unitId)
    if TOUT["SHOWGUID"] then
        TooltipUtils:AddDoubleLine(tt, "GUID", UnitGUID(unitId))
    end

    if TOUT["SHOWPARTYXPBAR"] == false and xpBar then
        xpBar:Hide()

        return
    end

    if unitId and unitId == "player" and UnitExists("player") and TooltipUtils:PlyTab("player") then
        TooltipUtils:AddXPBar(tt, "player")

        return
    end

    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) and UnitGUID(unit) == UnitGUID(unitId) and TooltipUtils:PlyTab(unit) then
            TooltipUtils:AddXPBar(tt, unit)

            return
        end
    end

    if xpBar then
        xpBar:Hide()
    end
end

function TooltipUtils:OnTooltipSet(tt, ...)
    TooltipUtils:OnTooltipSetItem(tt, ...)
    TooltipUtils:OnTooltipSetSpell(tt, ...)
    TooltipUtils:OnTooltipSetUnit(tt, ...)
end

function TooltipUtils:SendAllSlots()
    TooltipUtils:SendMsg("units/slots", "all", table.concat(TOUT["slots"], ":"), "PARTY")
end

function TooltipUtils:Init()
    TOUT = TOUT or {}
    TOUT["slots"] = TOUT["slots"] or {}
    TOUT["units"] = TOUT["units"] or {}
    TOUT["units"][UnitGUID("player")] = TOUT["units"][UnitGUID("player")] or {}
    TOUT["units"][UnitGUID("player")]["slots"] = TOUT["units"][UnitGUID("player")]["slots"] or {}
    local successfulRequest = C_ChatInfo.RegisterAddonMessagePrefix(msgPrefix)
    if not successfulRequest then
        TooltipUtils:MSG("[Init] PREFIX FAILED TO ADD")

        return
    end

    for i = 0, 23 do
        local itemLink = GetInventoryItemLink("player", i)
        if itemLink then
            local ItemID = GetItemInfoFromHyperlink(itemLink)
            if ItemID then
                TOUT["units"][UnitGUID("player")]["slots"][i] = ItemID
                TOUT["slots"][i] = ItemID
            else
                TOUT["units"][UnitGUID("player")]["slots"][i] = ""
                TOUT["slots"][i] = ""
            end
        else
            TOUT["units"][UnitGUID("player")]["slots"][i] = ""
            TOUT["slots"][i] = ""
        end
    end

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, TooltipUtils.OnTooltipSet)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, TooltipUtils.OnTooltipSet)
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, TooltipUtils.OnTooltipSet)
    else
        for _, frame in pairs(tooltips) do
            if frame then
                frame:HookScript(
                    "OnTooltipSetItem",
                    function(tt, ...)
                        TooltipUtils:OnTooltipSet(tt)
                    end
                )

                frame:HookScript(
                    "OnTooltipSetSpell",
                    function(tt, ...)
                        TooltipUtils:OnTooltipSet(tt)
                    end
                )

                frame:HookScript(
                    "OnTooltipSetUnit",
                    function(tt, ...)
                        TooltipUtils:OnTooltipSet(tt)
                    end
                )

                if frame == GameTooltip then
                    hooksecurefunc(
                        frame,
                        "SetAction",
                        function(tt, slot)
                            if tt == nil then return end
                            if slot == nil then return end
                            local actionType, MacroID = GetActionInfo(slot)
                            if actionType == "macro" and MacroID and TOUT["SHOWMACROID"] then
                                TooltipUtils:AddDoubleLine(tt, "MacroID", MacroID)
                                tt:Show()
                            end
                        end
                    )
                end
            end
        end
    end

    local equip = CreateFrame("Frame")
    TooltipUtils:RegisterEvent(equip, "PLAYER_EQUIPMENT_CHANGED")
    TooltipUtils:OnEvent(
        equip,
        function(sel, event, slot, empty)
            TOUT = TOUT or {}
            TOUT["slots"] = TOUT["slots"] or {}
            TOUT["units"] = TOUT["units"] or {}
            TOUT["units"][UnitGUID("player")] = TOUT["units"][UnitGUID("player")] or {}
            TOUT["units"][UnitGUID("player")]["slots"] = TOUT["units"][UnitGUID("player")]["slots"] or {}
            local itemLink = GetInventoryItemLink("player", slot)
            if itemLink then
                local ItemID = GetItemInfoFromHyperlink(itemLink)
                if ItemID then
                    TOUT["units"][UnitGUID("player")]["slots"][slot] = ItemID
                    TOUT["slots"][slot] = ItemID
                else
                    TOUT["units"][UnitGUID("player")]["slots"][slot] = ""
                    TOUT["slots"][slot] = ""
                end
            else
                TOUT["units"][UnitGUID("player")]["slots"][slot] = ""
                TOUT["slots"][slot] = ""
            end

            if IsInGroup() then
                TooltipUtils:SendMsg("units/slots", slot, TOUT["slots"][slot], "PARTY")
            end
        end, "equip"
    )

    local roster = CreateFrame("Frame")
    TooltipUtils:RegisterEvent(roster, "GROUP_ROSTER_UPDATE")
    TooltipUtils:OnEvent(
        roster,
        function(sel, event, ...)
            TooltipUtils:SendAllSlots()
        end, "roster"
    )

    local receiver = CreateFrame("Frame")
    TooltipUtils:RegisterEvent(receiver, "CHAT_MSG_ADDON")
    TooltipUtils:OnEvent(
        receiver,
        function(sel, event, prefix, message, chatTyp, sender, target, ...)
            if prefix == msgPrefix then
                local guid = UnitGUID(target)
                if guid then
                    local typ, key, value = strsplit(";", message)
                    if DEBUG then
                        print("[DEBUG] guid", guid, "typ", typ, "key", key, "value", value)
                    end

                    TOUT["units"] = TOUT["units"] or {}
                    TOUT["units"][guid] = TOUT["units"][guid] or {}
                    if typ == "curxp" then
                        TOUT["units"][guid]["curxp"] = value
                    elseif typ == "maxxp" then
                        TOUT["units"][guid]["maxxp"] = value
                    elseif typ == "units/slots" then
                        if key == "all" then
                            local vals = {strsplit(":", value)}
                            for x, val in pairs(vals) do
                                TOUT["units"][guid]["slots"] = TOUT["units"][guid]["slots"] or {}
                                TOUT["units"][guid]["slots"][tonumber(x)] = tonumber(val)
                            end
                        else
                            TOUT["units"][guid]["slots"] = TOUT["units"][guid]["slots"] or {}
                            TOUT["units"][guid]["slots"][tonumber(key)] = tonumber(value)
                        end
                    end
                end
            end
        end, "receiver"
    )

    local maxxp = UnitXPMax("player")
    local xpgain = CreateFrame("Frame")
    TooltipUtils:RegisterEvent(xpgain, "PLAYER_XP_UPDATE")
    TooltipUtils:OnEvent(
        xpgain,
        function(sel, event, ...)
            TooltipUtils:SendMsg("units", "curxp", UnitXP("player"), "PARTY")
            if maxxp ~= UnitXPMax("player") then
                maxxp = UnitXPMax("player")
                TooltipUtils:SendMsg("units", "maxxp", UnitXPMax("player"), "PARTY")
            end
        end, "xpgain"
    )

    TooltipUtils:After(
        2,
        function()
            if UnitInParty(unitId) == false then return false end
            TooltipUtils:SendAllSlots()
            TooltipUtils:SendMsg("units", "curxp", UnitXP("player"), "PARTY")
            TooltipUtils:SendMsg("units", "maxxp", UnitXPMax("player"), "PARTY")
        end, "INIT"
    )
end
