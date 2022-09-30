local AddonName, RandomSummon = ...

local slotCache = RandomSummon.slotCache.pet

local function SummonRandom()
    local num = GetNumCompanions("CRITTER")
    if num > 0 then
        CallCompanion("CRITTER", random(num))
    end
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

function RandomSummon:CheckActivePet()
    if RandomSummon.petId then
        local creatureID, _, _, _, issummoned
              = GetCompanionInfo("CRITTER", slotCache[RandomSummon.petId])

        if creatureID == RandomSummon.petId and issummoned then return true end
    end

    local activeFound = false
    local oldPetId = RandomSummon.petId
    RandomSummon.petId = nil
    for i=1,GetNumCompanions("CRITTER") do
        local creatureID, creatureName, _, _, issummoned
              = GetCompanionInfo("CRITTER", i)

        slotCache[creatureID] = i

        if issummoned then
            activeFound = true
            RandomSummon.petId = creatureID
            if oldPetId == creatureID then
                print("Slot changed for", creatureName)
            else
                print("Active pet changed to", creatureName)
            end
        end
    end
    return activeFound
end

function RandomSummon:EnsureRandomCompanion()
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
    elseif not RandomSummon:CheckActivePet() then
        SummonRandom()
    end
end
