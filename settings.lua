local _, TooltipUtils = ...
local ICON = 132252
local VERSION = "0.2.0"
local DEFAULT_WIDTH = 520
local DEFAULT_HEIGHT = 520
local tu_settings = nil
local function ShowMinimapButtonDefault()
    return TooltipUtils:GetWoWBuild() ~= "RETAIL"
end

local function ApplyDefaults()
    TOUT = TOUT or {}
    TooltipUtils:SV(TOUT, "SHOWMINIMAPBUTTON", TooltipUtils:GV(TOUT, "SHOWMINIMAPBUTTON", ShowMinimapButtonDefault()))
    TooltipUtils:SV(TOUT, "SHOWITEMLEVEL", TooltipUtils:GV(TOUT, "SHOWITEMLEVEL", true))
    TooltipUtils:SV(TOUT, "SHOWPARTYXPBAR", TooltipUtils:GV(TOUT, "SHOWPARTYXPBAR", true))
    TooltipUtils:SV(TOUT, "POLYMORPHABLE", TooltipUtils:GV(TOUT, "POLYMORPHABLE", true))
    TooltipUtils:SV(TOUT, "BANISHABLE", TooltipUtils:GV(TOUT, "BANISHABLE", true))
    TooltipUtils:SV(TOUT, "SHOWPARTYITEMS", TooltipUtils:GV(TOUT, "SHOWPARTYITEMS", true))
    TooltipUtils:SV(TOUT, "SHOWGUID", TooltipUtils:GV(TOUT, "SHOWGUID", false))
    TooltipUtils:SV(TOUT, "SHOWITEMID", TooltipUtils:GV(TOUT, "SHOWITEMID", false))
    TooltipUtils:SV(TOUT, "SHOWBONUSIDS", TooltipUtils:GV(TOUT, "SHOWBONUSIDS", false))
    TooltipUtils:SV(TOUT, "SHOWSLOTID", TooltipUtils:GV(TOUT, "SHOWSLOTID", false))
    TooltipUtils:SV(TOUT, "SHOWSPELLID", TooltipUtils:GV(TOUT, "SHOWSPELLID", false))
    TooltipUtils:SV(TOUT, "SHOWICONID", TooltipUtils:GV(TOUT, "SHOWICONID", false))
    TooltipUtils:SV(TOUT, "SHOWMACROID", TooltipUtils:GV(TOUT, "SHOWMACROID", false))
end

local function GetCollapsed(key)
    if key == nil then return nil end
    if type(TOUT) ~= "table" then return nil end
    if type(TOUT["COLLAPSED"]) ~= "table" then return nil end
    return TOUT["COLLAPSED"][key]
end

local function SetCollapsed(key, collapsed)
    if key == nil then return end
    if type(TOUT) ~= "table" then return end
    if type(TOUT["COLLAPSED"]) ~= "table" then TOUT["COLLAPSED"] = {} end
    if collapsed then
        TOUT["COLLAPSED"][key] = true
    else
        TOUT["COLLAPSED"][key] = nil
    end
end

local function AddOption(label, key, func)
    tu_settings:AddCheckbox({
        ["label"] = label,
        ["search"] = key,
        ["value"] = TooltipUtils:GV(TOUT, key, false),
        ["func"] = function(value)
            TooltipUtils:SV(TOUT, key, value)
            if func then func(value) end
        end
    })
end

function TooltipUtils:ToggleSettings()
    if tu_settings then tu_settings:Toggle() end
end

function TooltipUtils:InitSettings()
    ApplyDefaults()
    tu_settings = TooltipUtils:CreateUIWindow({
        ["name"] = "TooltipUtilsSettings",
        ["pTab"] = {"CENTER"},
        ["width"] = TooltipUtils:GV(TOUT, "WINDOWWIDTH", DEFAULT_WIDTH),
        ["height"] = TooltipUtils:GV(TOUT, "WINDOWHEIGHT", DEFAULT_HEIGHT),
        ["minWidth"] = 360,
        ["minHeight"] = 240,
        ["onResize"] = function(width, height)
            TooltipUtils:SV(TOUT, "WINDOWWIDTH", width)
            TooltipUtils:SV(TOUT, "WINDOWHEIGHT", height)
        end,
        ["getCollapsed"] = function(key) return GetCollapsed(key) end,
        ["setCollapsed"] = function(key, collapsed) SetCollapsed(key, collapsed) end,
        ["title"] = format("|T%d:16:16:0:0|t TooltipUtils v%s", ICON, TooltipUtils:GetVersion())
    })

    tu_settings:SuspendLayout()
    tu_settings:AddSearch()
    tu_settings:AddCategory({
        ["label"] = "LID_GENERAL",
        ["key"] = "GENERAL"
    })

    AddOption("LID_SHOWMINIMAPBUTTON", "SHOWMINIMAPBUTTON", function(value)
        if value then
            TooltipUtils:ShowMMBtn("TooltipUtils")
        else
            TooltipUtils:HideMMBtn("TooltipUtils")
        end
    end)

    tu_settings:AddCategory({
        ["label"] = "LID_UNITTOOLTIP",
        ["key"] = "UNITTOOLTIP"
    })

    AddOption("LID_SHOWITEMLEVEL", "SHOWITEMLEVEL")
    AddOption("LID_SHOWPARTYXPBAR", "SHOWPARTYXPBAR")
    tu_settings:AddCategory({
        ["label"] = "LID_CROWDCONTROL",
        ["key"] = "CROWDCONTROL",
        ["sub"] = true
    })

    AddOption("LID_POLYMORPHABLE", "POLYMORPHABLE")
    AddOption("LID_BANISHABLE", "BANISHABLE")
    tu_settings:AddCategory({
        ["label"] = "LID_ITEMTOOLTIP",
        ["key"] = "ITEMTOOLTIP"
    })

    AddOption("LID_SHOWPARTYITEMS", "SHOWPARTYITEMS")
    tu_settings:AddCategory({
        ["label"] = "LID_DEBUG",
        ["key"] = "DEBUG",
        ["collapsed"] = true
    })

    AddOption("LID_SHOWGUID", "SHOWGUID")
    AddOption("LID_SHOWITEMID", "SHOWITEMID")
    AddOption("LID_SHOWBONUSIDS", "SHOWBONUSIDS")
    AddOption("LID_SHOWSLOTID", "SHOWSLOTID")
    AddOption("LID_SHOWSPELLID", "SHOWSPELLID")
    AddOption("LID_SHOWICONID", "SHOWICONID")
    AddOption("LID_SHOWMACROID", "SHOWMACROID")
    tu_settings:ResumeLayout()
end

local TOUTSetup = CreateFrame("FRAME", "TOUTSetup")
TooltipUtils:RegisterEvent(TOUTSetup, "PLAYER_LOGIN")
TOUTSetup:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        TOUT = TOUT or {}
        ApplyDefaults()
        TooltipUtils:SetVersion(ICON, VERSION)
        TooltipUtils:SetAddonOutput("TooltipUtils", ICON)
        TooltipUtils:AddSlash("tu", TooltipUtils.ToggleSettings)
        TooltipUtils:AddSlash("tooltiputils", TooltipUtils.ToggleSettings)
        TooltipUtils:CreateMinimapButton({
            ["name"] = "TooltipUtils",
            ["icon"] = ICON,
            ["dbtab"] = TOUT,
            ["dbkey"] = "SHOWMINIMAPBUTTON",
            ["vTT"] = {{format("|T%d:16:16:0:0|t TooltipUtils", ICON), "v" .. TooltipUtils:GetVersion()}, {TooltipUtils:Trans("LID_LEFTCLICK"), TooltipUtils:Trans("LID_OPENSETTINGS")}, {TooltipUtils:Trans("LID_RIGHTCLICK"), TooltipUtils:Trans("LID_HIDEMINIMAPBUTTON")}},
            ["funcL"] = function() TooltipUtils:ToggleSettings() end,
            ["funcR"] = function()
                TooltipUtils:SV(TOUT, "SHOWMINIMAPBUTTON", false)
                TooltipUtils:HideMMBtn("TooltipUtils")
                TooltipUtils:MSG("Minimap Button is now hidden.")
            end
        })

        TooltipUtils:InitSettings()
        TooltipUtils:Init()
    end
end)
