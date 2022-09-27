local AddonName = ...

local Addon = CreateFrame("Frame", AddonName)
local petSlotCache = {}
local petId = nil

local origCallCompanion = CallCompanion
CallCompanion = function(companionType, slotId)
    local creatureID, creatureName, creatureSpellID,
          icon, issummoned, mountType = GetCompanionInfo(companionType, slotId)

    if companionType == "CRITTER" then
        petId = creatureID
        petSlotCache[creatureID] = slotId
        print("Summoning: ", creatureName)
    end

    origCallCompanion(companionType, slotId)
end

local origDismissCompanion = DismissCompanion
DismissCompanion = function(companionType)
    if companionType == "CRITTER" then
        petId = nil
        print("Dismissing pet!")
    end

    origDismissCompanion(companionType)
end

local function SummonRandom()
    local num = GetNumCompanions("CRITTER")
    if num > 0 then
        CallCompanion("CRITTER", random(num))
    end
end

local function CheckActivePet()
    if petId then
        local creatureID, creatureName, creatureSpellID, icon, issummoned,
              mountType = GetCompanionInfo("CRITTER", petSlotCache[petId])

        if creatureID == petId and issummoned then
            print("Still same slot for", creatureName, "and active")
            return true
        end
    end

    local activeFound = false
    local oldPetId = petId
    petId = nil
    for i=1,GetNumCompanions("CRITTER") do
        local creatureID, creatureName, creatureSpellID,
            icon, issummoned, mountType = GetCompanionInfo("CRITTER", i)

        petSlotCache[creatureID] = i

        if issummoned then
            activeFound = true
            petId = creatureID
            if oldPetId == creatureID then
                print("Slot changed for", creatureName)
            else
                print("Active pet changed to", creatureName)
            end
        end
    end
    return activeFound
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
    if IsStealthed() or IsMounted() or InCombatLockdown() or UnitIsDeadOrGhost("player") then
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
    elseif not CheckActivePet() then
        SummonRandom()
    end
end

local function RandomSummon_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        print("Entering world:", select(1, ...), select(2, ...))

        local active = CheckActivePet()

        if select(1, ...) or select(2, ...) then
            -- Initialisation
        end

        EnsureRandomCompanion()
    elseif event == "COMPANION_LEARNED" or event == "COMPANION_UNLEARNED" then
        -- rebuild metadata
        print("Companions updated:", event)
    elseif event == "UPDATE_STEALTH" and IsStealthed() then
        DismissCompanion("CRITTER")
    elseif event == "COMPANION_UPDATE" then
        if select(1, ...) == "CRITTER" then
            CheckActivePet()
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
