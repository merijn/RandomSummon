local AddonName, RandomSummon = ...

RandomSummon.mounts = {}
local slotCache = RandomSummon.slotCache.mount
local mountDetectionStrings = RandomSummon.mountDetectionStrings[GetLocale()]

if not mountDetectionStrings then
    print("Locale", GetLocale(), "is not supported. Random mount summoning won't work.")
end

function RandomSummon:UpdateMountMacroIcon(creatureId)
    if GetNumCompanions("MOUNT") == 0 then
        return
    end
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

local function UpdateMount(creatureID, fast, flying, swimming, qiraji)
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
end

local uniqueMounts = {
    -- creatureID = { fast, flying, swimming, qiraji }
    [24654]={true, true, false, false},
    [33029]={false, true, false, false},
    [33030]={true, true, false, false}
}

function RandomSummon:CheckMounts()
    if not GetMacroInfo("RandomSummonMount") and not InCombatLockdown() then
        CreateMacro("RandomSummonMount", "INV_MISC_QUESTIONMARK", [[
#showtooltip
/cancelform [nocombat,form:1/2/3/4]
/run RandomSummonMount()
]])
    end

    RandomSummon.mounts = {
        fly={size=0, regular={size=0}, fast={size=0}},
        swim={size=0, regular={size=0}, fast={size=0}},
        ground={size=0, regular={size=0}, fast={size=0}},
        ahnqiraj={size=0, regular={size=0}, fast={size=0}}
    }

    for i=1,GetNumCompanions("MOUNT") do
        local creatureID, name, creatureSpellID, _, _ = GetCompanionInfo("MOUNT", i)

        slotCache[creatureID] = i

        if uniqueMounts[creatureID] then
            UpdateMount(creatureID, unpack(uniqueMounts[creatureID]))
        else
            local spell = Spell:CreateFromSpellID(creatureSpellID)
            spell:ContinueOnSpellLoad(function()
                local desc = spell:GetSpellDescription()

                local fast = string.find(desc, mountDetectionStrings.fast)
                local flying = string.find(desc, mountDetectionStrings.flying)
                local swimming = string.find(desc, mountDetectionStrings.swimming)
                local qiraji = string.find(desc, mountDetectionStrings.qiraji)

                UpdateMount(creatureID, fast, flying, swimming, qiraji)
            end)
        end
    end
end
