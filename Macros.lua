local AddonName, RandomSummon = ...

function RandomSummon:UpdateMacros()
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
