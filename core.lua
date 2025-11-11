local _, TooltipUtils = ...
local DEBUG = false
local tooltips = {GameTooltip, ItemRefTooltip, WhatevahTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ShoppingTooltip1, ShoppingTooltip2}
local invToSlot = {}
invToSlot["INVTYPE_AMMO"] = 0
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
invToSlot["INVTYPE_WEAPONMAINHAND"] = 16
invToSlot["INVTYPE_WEAPONOFFHAND"] = 16
invToSlot["INVTYPE_WEAPON"] = 16
invToSlot["INVTYPE_2HWEAPON"] = 16
invToSlot["INVTYPE_HOLDABLE"] = 17
invToSlot["INVTYPE_SHIELD"] = 17
invToSlot["INVTYPE_THROWN"] = 18
invToSlot["INVTYPE_RANGED"] = 18
invToSlot["INVTYPE_RANGEDRIGHT"] = 18
invToSlot["INVTYPE_TABARD"] = 19
invToSlot["INVTYPE_NON_EQUIP_IGNORE"] = false
invToSlot["INVTYPE_BAG"] = false
invToSlot["INVTYPE_PROFESSION_TOOL"] = false
local missingOnce = {}
local queue = {}
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
        TooltipUtils:DEB("SendMsg", message, chatType)
    end

    local success = C_ChatInfo.SendAddonMessage(msgPrefix, message, chatType, target)
    if not success then
        TooltipUtils:INFO("SendMsg FAILED", chatType, message)
    end

    return success
end

function TooltipUtils:QueueMsg(typ, key, value, chatType, target)
    tinsert(queue, {typ, key, value, chatType, target})
end

function TooltipUtils:QueueThink(from)
    if #queue > 0 then
        local msgData = queue[1]
        if TooltipUtils:SendMsg(msgData[1], msgData[2], msgData[3], msgData[4], msgData[5]) then
            tremove(queue, 1)
            TooltipUtils:After(
                0.9,
                function()
                    TooltipUtils:QueueThink("Success")
                end, "QueueSuccess"
            )
        else
            TooltipUtils:After(
                1.8,
                function()
                    TooltipUtils:QueueThink("Failed")
                end, "QueueFailed"
            )
        end
    else
        TooltipUtils:After(
            1.3,
            function()
                TooltipUtils:QueueThink("AFK")
            end, "QueueAFK"
        )
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

function TooltipUtils:ItemLinkToItemString(itemLink)
    local pattern = "|H(item:.-)|h"

    return itemLink:match(pattern)
end

local xpBar = nil
function TooltipUtils:AddXPBar(tt, unitId)
    if TooltipUtils:PlyTab(unitId) then
        local guid = UnitGUID(unitId)
        TOUT["units"][guid]["curxp"] = 0
        TOUT["units"][guid]["maxxp"] = 1
        local cur = UnitXP(unitId)
        local max = UnitXPMax(unitId)
        if max <= 0 then
            if xpBar then
                xpBar:Hide()
            end

            return
        end

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
        xpBar.textLeft:SetText(AbbreviateNumbers(cur))
        xpBar.textRight:SetText(AbbreviateNumbers(max))
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

function TooltipUtils:OnTooltipSetItem(tt, data)
    if tt == nil then return end
    local itemLink = nil
    if data and data.id then
        itemLink = select(2, TooltipUtils:GetItemInfo(data.id))
    elseif tt.GetItem then
        itemLink = select(2, tt:GetItem())
    end

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
            for i = 0, 23 do
                if GetInventoryItemLink("player", i) == itemLink then
                    slotId = i
                    break
                end
            end

            if slotId ~= nil and TOUT["SHOWSLOTID"] then
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
                                if slotId ~= nil and slots[slotId] then
                                    local slotLink = select(2, C_Item.GetItemInfo(slots[slotId]))
                                    if slotLink then
                                        TooltipUtils:AddComparer(comparers, i, slotLink, partyUnit)
                                    end
                                end

                                if slotId2 ~= nil and slots[slotId2] then
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

function TooltipUtils:OnTooltipSetSpell(tt, data)
    if tt == nil then return end
    local spellID = nil
    if data and data.id then
        spellID = data.id
    elseif tt.GetSpell then
        spellID = select(2, tt:GetSpell())
    end

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

function TooltipUtils:OnTooltipSetUnit(tt, data)
    if tt == nil then return end
    local unitId = nil
    if tt.GetUnit then
        unitId = select(2, tt:GetUnit())
    end

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

local function OnTooltipSet(tt, ...)
    TooltipUtils:OnTooltipSetItem(tt, ...)
    TooltipUtils:OnTooltipSetSpell(tt, ...)
end

function TooltipUtils:SendAllSlots()
    for i = 0, 23 do
        TooltipUtils:QueueMsg("units/slots", i, TOUT["slots"][i], "PARTY")
    end
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
            itemLink = TooltipUtils:ItemLinkToItemString(itemLink)
            TOUT["units"][UnitGUID("player")]["slots"][i] = itemLink
            TOUT["slots"][i] = itemLink
        else
            TOUT["units"][UnitGUID("player")]["slots"][i] = ""
            TOUT["slots"][i] = ""
        end
    end

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(
            Enum.TooltipDataType.Item,
            function(tt, data)
                TooltipUtils:OnTooltipSetItem(tt, data)
            end
        )

        TooltipDataProcessor.AddTooltipPostCall(
            Enum.TooltipDataType.Spell,
            function(tt, data)
                TooltipUtils:OnTooltipSetSpell(tt, data)
            end
        )

        TooltipDataProcessor.AddTooltipPostCall(
            Enum.TooltipDataType.Unit,
            function(tt, data)
                TooltipUtils:OnTooltipSetUnit(tt, data)
            end
        )
    else
        for _, frame in pairs(tooltips) do
            if frame then
                frame:HookScript(
                    "OnTooltipSetItem",
                    function(tt, ...)
                        TooltipUtils:OnTooltipSetItem(tt, ...)
                    end
                )

                frame:HookScript(
                    "OnTooltipSetSpell",
                    function(tt, ...)
                        TooltipUtils:OnTooltipSetSpell(tt, ...)
                    end
                )

                frame:HookScript(
                    "OnTooltipSetUnit",
                    function(tt, ...)
                        TooltipUtils:OnTooltipSetUnit(tt, ...)
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
                itemLink = TooltipUtils:ItemLinkToItemString(itemLink)
                TOUT["units"][UnitGUID("player")]["slots"][slot] = itemLink
                TOUT["slots"][slot] = itemLink
            else
                TOUT["units"][UnitGUID("player")]["slots"][slot] = ""
                TOUT["slots"][slot] = ""
            end

            if IsInGroup() then
                TooltipUtils:QueueMsg("units/slots", slot, TOUT["slots"][slot], "PARTY")
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
                        TooltipUtils:DEB("RECEIVE", "guid", guid, "typ", typ, "key", key, "value", value)
                    end

                    TOUT["units"] = TOUT["units"] or {}
                    TOUT["units"][guid] = TOUT["units"][guid] or {}
                    if typ == "units" then
                        TOUT["units"][guid][key] = value
                    elseif typ == "units/slots" then
                        if key ~= "all" then
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
            if maxxp ~= UnitXPMax("player") then
                maxxp = UnitXPMax("player")
                TooltipUtils:QueueMsg("units", "maxxp", UnitXPMax("player"), "PARTY")
            end

            TooltipUtils:QueueMsg("units", "curxp", UnitXP("player"), "PARTY")
        end, "xpgain"
    )

    TooltipUtils:After(
        2,
        function()
            if not DEBUG and UnitInParty(unitId) == false then return false end
            TooltipUtils:QueueMsg("units", "maxxp", UnitXPMax("player"), "PARTY")
            TooltipUtils:QueueMsg("units", "curxp", UnitXP("player"), "PARTY")
            TooltipUtils:SendAllSlots()
            TooltipUtils:QueueThink("Init")
        end, "INIT"
    )
end
