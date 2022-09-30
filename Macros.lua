local AddonName, Addon = ...

function Addon:UpdateMountMacroIcon(creatureId)
    if GetMacroInfo("RandomSummonMount") then
        local spellID
        if creatureId then
            local slotId = Addon.slotCache.mount[creatureId]
            _, _, spellID, _, _ = GetCompanionInfo("MOUNT", slotId)
        else
            local num = GetNumCompanions("MOUNT")
            _, _, spellID, _, _ = GetCompanionInfo("MOUNT", random(num))
        end
        SetMacroSpell("RandomSummonMount", GetSpellInfo(spellID))
    end
end

local aquaFormId = 1066
local travelFormId = 783
local flightFormId = 33943
local swiftFlightFormId = 40120
local aquaForm = GetSpellInfo(aquaFormId)
local travelForm = GetSpellInfo(travelFormId)
local flightForm = GetSpellInfo(flightFormId)
local swiftFlightForm = GetSpellInfo(swiftFlightFormId)

local flyableMacro, unflyableMacro

function Addon:RegenDruidMacroStrings()
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

-- Immediately initalise macro strings
Addon:RegenDruidMacroStrings()

local mountMacro = [[
#showtooltip
/cancelform [nocombat,form:1/2/3/4]
/run RandomSummonMount()
]]

function Addon:UpdateMacros()
    if not GetMacroInfo("RandomSummonMount") and not InCombatLockdown() then
        CreateMacro("RandomSummonMount", "INV_MISC_QUESTIONMARK", mountMacro)
    end
    Addon:UpdateMountMacroIcon()

    _, playerClass, _ = UnitClass("player")
    if playerClass == "DRUID" and not InCombatLockdown() then
        if not GetMacroInfo("RandomSummonTravelForm") then
            if Addon:CanFly() then
                CreateMacro("RandomSummonTravelForm", "INV_MISC_QUESTIONMARK",
                            flyableMacro, true)
            else
                CreateMacro("RandomSummonTravelForm", "INV_MISC_QUESTIONMARK",
                            unflyableMacro, true)
            end
        elseif Addon:CanFly() then
            EditMacro("RandomSummonTravelForm", "RandomSummonTravelForm",
                      "INV_MISC_QUESTIONMARK", flyableMacro, true)
        else
            EditMacro("RandomSummonTravelForm", "RandomSummonTravelForm",
                      "INV_MISC_QUESTIONMARK", unflyableMacro, true)
        end
    end
end
