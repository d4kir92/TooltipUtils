local _, TooltipUtils = ...
local TOUTSetup = CreateFrame("FRAME", "TOUTSetup")
TooltipUtils:RegisterEvent(TOUTSetup, "PLAYER_LOGIN")
TOUTSetup:SetScript(
    "OnEvent",
    function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            TOUT = TOUT or {}
            TooltipUtils:SetVersion(132252, "0.1.30")
            TooltipUtils:SetAddonOutput("TooltipUtils", 132252)
            TooltipUtils:AddSlash("tu", TooltipUtils.ToggleSettings)
            TooltipUtils:AddSlash("tooltiputils", TooltipUtils.ToggleSettings)
            local mmbtn = nil
            TooltipUtils:CreateMinimapButton(
                {
                    ["name"] = "TooltipUtils",
                    ["icon"] = 132252,
                    ["var"] = mmbtn,
                    ["dbtab"] = TOUT,
                    ["vTT"] = {{"T|cff3FC7EBooltip|rU|cff3FC7EBtils|r", "v|cff3FC7EB" .. TooltipUtils:GetVersion()}, {TooltipUtils:Trans("LID_LEFTCLICK"), TooltipUtils:Trans("LID_OPENSETTINGS")}, {TooltipUtils:Trans("LID_RIGHTCLICK"), TooltipUtils:Trans("LID_HIDEMINIMAPBUTTON")}},
                    ["funcL"] = function()
                        TooltipUtils:ToggleSettings()
                    end,
                    ["funcR"] = function()
                        TooltipUtils:SV(TOUT, "SHOWMINIMAPBUTTON", false)
                        TooltipUtils:HideMMBtn("TooltipUtils")
                        TooltipUtils:MSG("Minimap Button is now hidden.")
                    end,
                    ["dbkey"] = "SHOWMINIMAPBUTTON"
                }
            )

            TooltipUtils:InitSettings()
            TooltipUtils:Init()
        end
    end
)

local cu_settings = nil
function TooltipUtils:ToggleSettings()
    if cu_settings then
        if cu_settings:IsShown() then
            cu_settings:Hide()
        else
            cu_settings:Show()
        end
    end
end

function TooltipUtils:InitSettings()
    TOUT = TOUT or {}
    cu_settings = TooltipUtils:CreateWindow(
        {
            ["name"] = "TooltipUtils",
            ["pTab"] = {"CENTER"},
            ["sw"] = 520,
            ["sh"] = 520,
            ["title"] = format("T|cff3FC7EBooltip|rU|cff3FC7EBtils|r v|cff3FC7EB%s", TooltipUtils:GetVersion())
        }
    )

    local x = 15
    local y = 10
    TooltipUtils:SetAppendX(x)
    TooltipUtils:SetAppendY(y)
    TooltipUtils:SetAppendParent(cu_settings)
    TooltipUtils:SetAppendTab(TOUT)
    TooltipUtils:AppendCategory("GENERAL")
    TooltipUtils:AppendCheckbox(
        "SHOWMINIMAPBUTTON",
        TooltipUtils:GetWoWBuild() ~= "RETAIL",
        function()
            if TooltipUtils:GV(TOUT, "SHOWMINIMAPBUTTON", TooltipUtils:GetWoWBuild() ~= "RETAIL") then
                TooltipUtils:ShowMMBtn("TooltipUtils")
            else
                TooltipUtils:HideMMBtn("TooltipUtils")
            end
        end
    )

    TooltipUtils:AppendCategory("TOOLTIP")
    TooltipUtils:AppendCheckbox("SHOWPARTYITEMS", true)
    TooltipUtils:AppendCheckbox("SHOWPARTYXPBAR", true)
    TooltipUtils:AppendCheckbox("POLYMORPHABLE", true)
    TooltipUtils:AppendCheckbox("BANISHABLE", true)
    TooltipUtils:AppendCategory("DEBUG")
    TooltipUtils:AppendCheckbox("SHOWITEMID", false)
    TooltipUtils:AppendCheckbox("SHOWSPELLID", false)
    TooltipUtils:AppendCheckbox("SHOWGUID", false)
    TooltipUtils:AppendCheckbox("SHOWUNITID", false)
    TooltipUtils:AppendCheckbox("SHOWICONID", false)
    TooltipUtils:AppendCheckbox("SHOWSLOTID", false)
    TooltipUtils:AppendCheckbox("SHOWMACROID", false)
end
