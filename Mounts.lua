local AddonName, RandomSummon = ...

RandomSummon.mounts = {}
local slotCache = RandomSummon.slotCache.mount
local mountDetectionStrings = RandomSummon.mountDetectionStrings[GetLocale()]

if not mountDetectionStrings then
    print("Locale", GetLocale(), "is not supported. Random mount summoning won't work.")
end

function RandomSummon:CheckMounts()
    RandomSummon.mounts = {
        fly={size=0, regular={size=0}, fast={size=0}},
        swim={size=0, regular={size=0}, fast={size=0}},
        ground={size=0, regular={size=0}, fast={size=0}},
        ahnqiraj={size=0, regular={size=0}, fast={size=0}}
    }

    for i=1,GetNumCompanions("MOUNT") do
        local creatureID, _, creatureSpellID, _, _ = GetCompanionInfo("MOUNT", i)

        slotCache[creatureID] = i

        local spell = Spell:CreateFromSpellID(creatureSpellID)
        spell:ContinueOnSpellLoad(function()
            local desc = spell:GetSpellDescription()

            local fast = string.find(desc, mountDetectionStrings.fast)
            local flying = string.find(desc, mountDetectionStrings.flying)
            local swimming = string.find(desc, mountDetectionStrings.swimming)
            local qiraji = string.find(desc, mountDetectionStrings.qiraji)

            local mountCollection
            if qiraji then
                mountCollection = RandomSummon.mounts.ahnqiraj
            elseif swimming then
                mountCollection = RandomSummon.mounts.swim
            elseif flying then
                mountCollection = RandomSummon.mounts.fly
            else
                mountCollection = RandomSummon.mounts.ground
            end

            mountCollection.size = mountCollection.size + 1
            if fast then
                mountCollection.fast.size = mountCollection.fast.size + 1
                table.insert(mountCollection.fast, creatureID)
            else
                mountCollection.regular.size = mountCollection.regular.size + 1
                table.insert(mountCollection.regular, creatureID)
            end
        end)
    end
end