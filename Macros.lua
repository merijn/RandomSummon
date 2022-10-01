local AddonName, RandomSummon = ...

function RandomSummon:UpdateMountMacroIcon(creatureId)
    if GetMacroInfo("RandomSummonMount") then
        local spellID
        if creatureId then
            local slotId = RandomSummon.slotCache.mount[creatureId]
            _, _, spellID, _, _ = GetCompanionInfo("MOUNT", slotId)
        else
            local num = GetNumCompanions("MOUNT")
            _, _, spellID, _, _ = GetCompanionInfo("MOUNT", random(num))
        end
        SetMacroSpell("RandomSummonMount", GetSpellInfo(spellID))
    end
end

local mountMacro = [[
#showtooltip
/cancelform [nocombat,form:1/2/3/4]
/run RandomSummonMount()
]]

function RandomSummon:UpdateMacros()
    if not GetMacroInfo("RandomSummonMount") and not InCombatLockdown() then
        CreateMacro("RandomSummonMount", "INV_MISC_QUESTIONMARK", mountMacro)
    end
    RandomSummon:UpdateMountMacroIcon()

    if RandomSummon.druid and not InCombatLockdown() then
        if not GetMacroInfo("RandomSummonTravelForm") then
            if RandomSummon:CanFly() then
                CreateMacro("RandomSummonTravelForm", "INV_MISC_QUESTIONMARK",
                            RandomSummon.druid.flyableMacro, true)
            else
                CreateMacro("RandomSummonTravelForm", "INV_MISC_QUESTIONMARK",
                            RandomSummon.druid.unflyableMacro, true)
            end
        elseif RandomSummon:CanFly() then
            EditMacro("RandomSummonTravelForm", "RandomSummonTravelForm",
                      "INV_MISC_QUESTIONMARK",
                      RandomSummon.druid.flyableMacro, true)
        else
            EditMacro("RandomSummonTravelForm", "RandomSummonTravelForm",
                      "INV_MISC_QUESTIONMARK",
                      RandomSummon.druid.unflyableMacro, true)
        end
    end
end
