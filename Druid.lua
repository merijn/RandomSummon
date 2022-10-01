local AddonName, RandomSummon = ...

local _, playerClass, _ = UnitClass("player")
if playerClass == "DRUID" then
    RandomSummon.druid = {
        aquaFormId = 1066,
        travelFormId = 783,
        flightFormId = 33943,
        swiftFlightFormId = 40120,
        flyableMacro = "",
        unflyableMacro = ""
    }
    local druid = RandomSummon.druid

    function RandomSummon:IsFlightForm(spellId)
        local form = spellId or RandomSummon:CurrentForm()
        return (form == druid.flightFormId) or (form == druid.swiftFlightFormId)
    end

    function RandomSummon:CurrentForm()
        local formIdx = GetShapeshiftForm()
        if formIdx ~= 0 then
            local _, _, _, spellID = GetShapeshiftFormInfo(formIdx)
            return spellID
        end
        return 0
    end

    druid.aquaForm = GetSpellInfo(druid.aquaFormId)
    druid.travelForm = GetSpellInfo(druid.travelFormId)
    druid.flightForm = GetSpellInfo(druid.flightFormId)
    druid.swiftFlightForm = GetSpellInfo(druid.swiftFlightFormId)
    druid.oldForm = RandomSummon:CurrentForm()

    function RandomSummon:RegenDruidMacroStrings()
        flyableMacro = "#showtooltip\n/cast "
        unflyableMacro = "#showtooltip\n/cast "
        if IsSpellKnown(druid.aquaFormId) then
            local s = "[swimming] !" .. druid.aquaForm .. "; "
            flyableMacro = flyableMacro .. s
            unflyableMacro = unflyableMacro .. s
        end
        if IsSpellKnown(druid.swiftFlightFormId) then
            local s = "[flyable,nocombat] !" .. druid.swiftFlightForm .. "; "
            flyableMacro = flyableMacro .. s
        elseif IsSpellKnown(druid.flightFormId) then
            local s = "[flyable,nocombat] !" .. druid.flightForm .. "; "
            flyableMacro = flyableMacro .. s
        end
        if IsSpellKnown(druid.travelFormId) then
            local s = "!" .. druid.travelForm
            flyableMacro = flyableMacro .. s
            unflyableMacro = unflyableMacro .. s
        end

        RandomSummon.druid.flyableMacro = flyableMacro
        RandomSummon.druid.unflyableMacro = unflyableMacro
    end

    RandomSummon:RegenDruidMacroStrings()
end
