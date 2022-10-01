local AddonName, RandomSummon = ...

local AddonFrame = CreateFrame("Frame", AddonName)

function RandomSummonMountType(mountType, speed)
    local mountCollection
    if mountType == "GROUND" then
        mountCollection = RandomSummon.mounts.ground
    elseif mountType == "FLY" then
        mountCollection = RandomSummon.mounts.fly
    elseif mountType == "QIRAJI" then
        mountCollection = RandomSummon.mounts.ahnqiraj
    elseif mountType == "SWIM" then
        mountCollection = RandomSummon.mounts.swim
    else
        error("Unsupported mount type!")
    end

    local creatureId
    if speed == "ANY" and mountCollection.size > 0 then
        num = random(mountCollection.size)
        if num <= mountCollection.regular.size then
            creatureId = mountCollection.regular[num]
        else
            num = num - mountCollection.regular.size
            creatureId = mountCollection.fast[num]
        end
    elseif speed == "FAST" and mountCollection.fast.size > 0 then
        creatureId = mountCollection.fast[random(mountCollection.fast.size)]
    elseif mountCollection.regular.size > 0 then
        creatureId = mountCollection.regular[random(mountCollection.regular.size)]
    end

    if creatureId then
        RandomSummon:CallSpecific("MOUNT", creatureId)
        RandomSummon:UpdateMountMacroIcon(creatureId)
    end
end

function RandomSummonMount()
    if IsMounted() then
        DismissCompanion("MOUNT")
        RandomSummon:UpdateMountMacroIcon()
        return
    elseif InCombatLockdown() then
        return
    end

    local mounts = RandomSummon.mounts
    local name, _, _, _, _, _, _, instanceID, _, _ = GetInstanceInfo()
    if instanceID == 509 or instanceID == 531 and mounts.ahnqiraj.size > 0 then
        RandomSummonMountType("QIRAJI", "FAST")
    elseif (IsSwimming() or IsSubmerged()) and mounts.swim.size > 0 then
        RandomSummonMountType("SWIM", "FAST")
    elseif RandomSummon:CanFly() and mounts.fly.size > 0 then
        RandomSummonMountType("FLY", "FAST")
    else
        RandomSummonMountType("GROUND", "FAST")
    end
end

local function RandomSummon_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local active = RandomSummon:CheckActivePet()

        if select(1, ...) or select(2, ...) then
            -- Initialisation
            RandomSummon:CheckMounts()
        end

        RandomSummon:UpdateMountMacroIcon()
        RandomSummon:EnsureRandomCompanion()
    elseif event == "COMPANION_LEARNED" or event == "COMPANION_UNLEARNED" then
        -- rebuild metadata
        RandomSummon:CheckMounts()
        print("Companions updated:", event)
    elseif event == "UPDATE_STEALTH" and IsStealthed() then
        DismissCompanion("CRITTER")
    elseif event == "COMPANION_UPDATE" then
        if select(1, ...) == "CRITTER" then
            RandomSummon:CheckActivePet()
        end
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        if not IsMounted() then
            C_Timer.After(0.12, function()
                if not IsFalling() then
                    RandomSummon:EnsureRandomCompanion()
                end
            end)
        end
    else
        RandomSummon:EnsureRandomCompanion()
    end
end

AddonFrame:SetScript("OnEvent", RandomSummon_OnEvent)
AddonFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
AddonFrame:RegisterEvent("COMPANION_LEARNED")
AddonFrame:RegisterEvent("COMPANION_UNLEARNED")
AddonFrame:RegisterEvent("UPDATE_STEALTH")
AddonFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
AddonFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
AddonFrame:RegisterEvent("PLAYER_ALIVE")
AddonFrame:RegisterEvent("PLAYER_UNGHOST")
AddonFrame:RegisterEvent("COMPANION_UPDATE")
