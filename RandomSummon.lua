local AddonName = ...

local Addon = CreateFrame("Frame", AddonName)

local petId = nil
local petSlot = nil

local origCallCompanion = CallCompanion
CallCompanion = function(companionType, slotId)
    local creatureID, creatureName, creatureSpellID,
          icon, issummoned, mountType = GetCompanionInfo(companionType, slotId)

    if companionType == "CRITTER" then
        petId = creatureID
        petSlot = slotId
        print("Summoning: ", creatureName)
    end

    origCallCompanion(companionType, slotId)
end

local origDismissCompanion = DismissCompanion
DismissCompanion = function(companionType)
    if companionType == "CRITTER" then
        petId = nil
        petSlot = nil
        print("Dismissing pet!")
    end

    origDismissCompanion(companionType)
end

local function SummonRandom()
    CallCompanion("CRITTER", random(GetNumCompanions("CRITTER")))
end

local function CheckPetActive()
    if petId then
        local creatureID, creatureName, creatureSpellID,
            icon, issummoned, mountType = GetCompanionInfo("CRITTER", petSlot)
        if creatureID == petId then
            print("Still same slot for", petId, "and active is", issummoned)
            return true
        else
            print("Slot changed for", petId)
        end
    end
    return false
end

local function CheckBusy()
    if UnitCastingInfo("player") then
        return "CASTING"
    elseif UnitChannelInfo("player") then
        return "CHANNELING"
    end

    local start, duration, enabled, modRate = GetSpellCooldown(61304)
    if start ~= 0 then
        return "GCD"
    end

    return "IDLE"
end

local function EnsureRandomCompanion()
    if IsStealthed() or IsMounted() or InCombatLockdown() then
        -- Don't break stealth, dismount, or trigger GCD in combat
        return
    end

    local activity = CheckBusy()
    if activity == "CASTING" then
        print("Busy casting!")
    elseif activity == "CHANNELING" then
        print("Busy channeling!")
    elseif activity == "GCD" then
        print("Busy GCD!")
    else
        if not CheckPetActive() then
            SummonRandom()
        end
    end
end

local function RandomSummon_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        print("Entering world:", select(1, ...), select(2, ...))
    elseif event == "COMPANION_LEARNED" or event == "COMPANION_UNLEARNED" then
        -- rebuild metadata
        print("Companions updated:", event)
    elseif event == "UPDATE_STEALTH" and IsStealthed() then
        DismissCompanion("CRITTER")
    elseif event == "COMPANION_UPDATE" then
        if select(1, ...) == "CRITTER" then
            print("Critter update!")
        else
            -- No op
        end
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        if not IsMounted() then
            C_Timer.After(0.12, function() EnsureRandomCompanion() end)
        end
    else
        EnsureRandomCompanion()
    end
end

Addon:SetScript("OnEvent", RandomSummon_OnEvent)
Addon:RegisterEvent("PLAYER_ENTERING_WORLD")
Addon:RegisterEvent("COMPANION_LEARNED")
Addon:RegisterEvent("COMPANION_UNLEARNED")
Addon:RegisterEvent("UPDATE_STEALTH")
Addon:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
Addon:RegisterEvent("PLAYER_REGEN_ENABLED")
Addon:RegisterEvent("COMPANION_UPDATE")
