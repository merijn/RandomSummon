local AddonName, RandomSummon = ...

local _, playerClass, _ = UnitClass("player")
if playerClass ~= "DRUID" then
    return
end

local DruidFrame = CreateFrame("Frame", AddonName .. "Druid")

local aquaFormId = 1066
local travelFormId = 783
local flightFormId = 33943
local swiftFlightFormId = 40120
local flyableMacro = ""
local unflyableMacro = ""
local aquaForm
local travelForm
local flightForm
local swiftFlightForm
local oldForm

local function UpdateMacro()
    if InCombatLockdown() then
        DruidFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    if not GetMacroInfo("RandomSummonTravelForm") then
        if RandomSummon:CanFly() then
            CreateMacro("RandomSummonTravelForm", "INV_MISC_QUESTIONMARK",
                        flyableMacro, true)
        else
            CreateMacro("RandomSummonTravelForm", "INV_MISC_QUESTIONMARK",
                        unflyableMacro, true)
        end
    elseif RandomSummon:CanFly() then
        EditMacro("RandomSummonTravelForm", "RandomSummonTravelForm",
                "INV_MISC_QUESTIONMARK", flyableMacro, true)
    else
        EditMacro("RandomSummonTravelForm", "RandomSummonTravelForm",
                "INV_MISC_QUESTIONMARK", unflyableMacro, true)
    end
end

local function CurrentForm()
    local formIdx = GetShapeshiftForm()
    if formIdx ~= 0 then
        local _, _, _, spellID = GetShapeshiftFormInfo(formIdx)
        return spellID
    end
    return 0
end

local function IsFlightForm(spellId)
    local form = spellId or CurrentForm()
    return (form == flightFormId) or (form == swiftFlightFormId)
end

local function RegenDruidMacroStrings()
    flyableMacro = "#showtooltip\n/cast "
    unflyableMacro = "#showtooltip\n/cast "
    if IsSpellKnown(aquaFormId) then
        local s = "[swimming] !" .. aquaForm .. "; "
        flyableMacro = flyableMacro .. s
        unflyableMacro = unflyableMacro .. s
    end
    if IsSpellKnown(swiftFlightFormId) then
        local s = "[flyable,nocombat] !" .. swiftFlightForm .. "; "
        flyableMacro = flyableMacro .. s
    elseif IsSpellKnown(flightFormId) then
        local s = "[flyable,nocombat] !" .. flightForm .. "; "
        flyableMacro = flyableMacro .. s
    end
    if IsSpellKnown(travelFormId) then
        local s = "!" .. travelForm
        flyableMacro = flyableMacro .. s
        unflyableMacro = unflyableMacro .. s
    end
end

local zoneStrings = RandomSummon.zoneStrings[GetLocale()]

local function RandomSummonDruid_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        aquaForm = GetSpellInfo(aquaFormId)
        travelForm = GetSpellInfo(travelFormId)
        flightForm = GetSpellInfo(flightFormId)
        swiftFlightForm = GetSpellInfo(swiftFlightFormId)

        oldForm = CurrentForm()
        RegenDruidMacroStrings()

        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "PLAYER_REGEN_ENABLED" then
        UpdateMacro()
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    elseif event == "LEARNED_SPELL_IN_TAB" then
        RegenDruidMacroStrings()
    elseif event == "ZONE_CHANGED" then
        if GetZoneText() ~= zoneStrings.dalaran then
            DruidFrame:UnregisterEvent("ZONE_CHANGED")
        else
            UpdateMacro()
        end
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        if GetZoneText() == zoneStrings.dalaran then
            DruidFrame:RegisterEvent("ZONE_CHANGED")
        else
            DruidFrame:UnregisterEvent("ZONE_CHANGED")
        end
        C_Timer.After(0, function() UpdateMacro() end)
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        local activeForm = CurrentForm()
        if oldForm ~= activeForm and not IsFlightForm(activeForm) then
            if IsFlightForm(oldForm) then
                C_Timer.After(0, function()
                    if not IsFalling() then
                        RandomSummon:EnsureRandomCompanion()
                    end
                end)
            end
        end
        oldForm = activeForm
    end
end

DruidFrame:SetScript("OnEvent", RandomSummonDruid_OnEvent)
DruidFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
DruidFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
if GetZoneText() == zoneStrings.dalaran then
    DruidFrame:RegisterEvent("ZONE_CHANGED")
end
DruidFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
DruidFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
