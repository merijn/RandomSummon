local AddonName, RandomSummon = ...

RandomSummon.mounts = {}

function RandomSummon:UpdateMountMacroIcon(mountID)
    if GetNumCompanions("MOUNT") == 0 then
        return
    end
    if GetMacroInfo("RandomSummonMount") then
        local spellID
        if mountID then
            local _, spellID, _, _, _, _, _, _, _, _, _, _ = C_MountJournal.GetMountInfoByID(mountID)
        else
            local num = GetNumCompanions("MOUNT")
            _, _, spellID, _, _ = GetCompanionInfo("MOUNT", random(num))
        end
        SetMacroSpell("RandomSummonMount", GetSpellInfo(spellID))
    end
end

local function UpdateMount(mountID, mountTypeID)
    local mountCollection
    if mountTypeID == 241 then
        mountCollection = RandomSummon.mounts.ahnqiraj
    elseif mountTypeID == 231 then
        mountCollection = RandomSummon.mounts.swim
    elseif mountTypeID == 248 then
        mountCollection = RandomSummon.mounts.fly
    elseif mountTypeID == 230 then
        mountCollection = RandomSummon.mounts.ground
    else
        error("Unsupported mount type: " .. mountTypeID .. "!")
    end

    mountCollection.size = mountCollection.size + 1
    table.insert(mountCollection, mountID)
end

function RandomSummon:CheckMounts()
    if not GetMacroInfo("RandomSummonMount") and not InCombatLockdown() then
        CreateMacro("RandomSummonMount", "INV_MISC_QUESTIONMARK", [[
#showtooltip
/cancelform [nocombat,form:1/2/3/4]
/run RandomSummonMount()
]])
    end

    RandomSummon.mounts = {
        fly={size=0},
        swim={size=0},
        ground={size=0},
        ahnqiraj={size=0},
    }

    for _, mountID in ipairs(C_MountJournal.GetMountIDs()) do
        local name, spellID, _, _, isUsable, _, isFavorite, _, _, _,
                isCollected, _ = C_MountJournal.GetMountInfoByID(mountID)

        if isCollected then
            local _, _, _, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountID)

            UpdateMount(mountID, mountTypeID)
        end
    end
end
