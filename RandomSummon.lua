local AddonName, Addon = ...

local AddonFrame = CreateFrame("Frame", AddonName)

local mounts = {}

local function CheckMounts()
    local locale = GetLocale()
    local mountDetectionStrings = Addon.mountDetectionStrings[locale]
    if not mountDetectionStrings then
        print("Locale", locale, "is not supported. Random mount summoning won't work.")
        return
    end

    mounts = {
        fly={size=0, regular={size=0}, fast={size=0}},
        swim={size=0, regular={size=0}, fast={size=0}},
        ground={size=0, regular={size=0}, fast={size=0}},
        ahnqiraj={size=0, regular={size=0}, fast={size=0}}
    }

    for i=1,GetNumCompanions("MOUNT") do
        local creatureID, creatureName, creatureSpellID,
            icon, issummoned = GetCompanionInfo("MOUNT", i)

        Addon.slotCache.mount[creatureID] = i

        local spell = Spell:CreateFromSpellID(creatureSpellID)
        spell:ContinueOnSpellLoad(function()
            local desc = spell:GetSpellDescription()

            local fast = string.find(desc, mountDetectionStrings.fast)
            local flying = string.find(desc, mountDetectionStrings.flying)
            local swimming = string.find(desc, mountDetectionStrings.swimming)
            local qiraji = string.find(desc, mountDetectionStrings.qiraji)

            local mountCollection
            if qiraji then
                mountCollection = mounts.ahnqiraj
            elseif swimming then
                mountCollection = mounts.swim
            elseif flying then
                mountCollection = mounts.fly
            else
                mountCollection = mounts.ground
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

function RandomSummonMountType(mountType, speed)
    local mountCollection
    if mountType == "GROUND" then
        mountCollection = mounts.ground
    elseif mountType == "FLY" then
        mountCollection = mounts.fly
    elseif mountType == "QIRAJI" then
        mountCollection = mounts.ahnqiraj
    elseif mountType == "SWIM" then
        mountCollection = mounts.swim
    else
        error("Unsupported mount type!")
    end

    local creatureId
    if speed == "ANY" and mountCollection.size > 0 then
        num = random(mountCollection.size)
        if num <= mountCollection.regular.size then
            creatureId = mountCollection.regular[num]
        else
            creatureId = mountCollection.fast[num - mountCollection.regular.size]
        end
    elseif speed == "FAST" and mountCollection.fast.size > 0 then
        creatureId = mountCollection.fast[random(mountCollection.fast.size)]
    elseif mountCollection.regular.size > 0 then
        creatureId = mountCollection.fast[random(mountCollection.regular.size)]
    end

    if creatureId then
        Addon:CallSpecific("MOUNT", creatureId)
        Addon:UpdateMountMacroIcon(creatureId)
    end
end

function RandomSummonMount()
    if IsMounted() then
        DismissCompanion("MOUNT")
        Addon:UpdateMountMacroIcon()
        return
    elseif InCombatLockdown() then
        return
    end

    name, _, _, _, _, _, _, instanceID, _, _ = GetInstanceInfo()
    if instanceID == 509 or instanceID == 531 and mounts.ahnqiraj.size > 0 then
        RandomSummonMountType("QIRAJI", "FAST")
    elseif (IsSwimming() or IsSubmerged()) and mounts.swim.size > 0 then
        RandomSummonMountType("SWIM", "FAST")
    elseif Addon:CanFly() and mounts.fly.size > 0 then
        RandomSummonMountType("FLY", "FAST")
    else
        RandomSummonMountType("GROUND", "FAST")
    end
end

local function RandomSummon_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local active = Addon:CheckActivePet()

        if select(1, ...) or select(2, ...) then
            -- Initialisation
            CheckMounts()
        end

        Addon:UpdateMacros()
        Addon:EnsureRandomCompanion()
    elseif event == "COMPANION_LEARNED" or event == "COMPANION_UNLEARNED" then
        -- rebuild metadata
        CheckMounts()
        print("Companions updated:", event)
    elseif event == "UPDATE_STEALTH" and IsStealthed() then
        DismissCompanion("CRITTER")
    elseif event == "COMPANION_UPDATE" then
        if select(1, ...) == "CRITTER" then
            Addon:CheckActivePet()
        end
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        if not IsMounted() then
            C_Timer.After(0.12, function()
                if not IsFalling() then
                    Addon:EnsureRandomCompanion()
                end
            end)
        end
    elseif event == "LEARNED_SPELL_IN_TAB" then
        -- Only fires for druids, rerun macro code in case we learned a new
        -- travel form
        Addon:RegenDruidMacroStrings()
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        print(event, ...)
    else
        Addon:EnsureRandomCompanion()
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
_, playerClass, _ = UnitClass("player")
if playerClass == "DRUID" then
    AddonFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    AddonFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
end
