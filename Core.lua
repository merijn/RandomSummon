local AddonName, RandomSummon = ...

RandomSummon.petId = nil
RandomSummon.slotCache = { pet={} }

local origCallCompanion = CallCompanion
CallCompanion = function(companionType, slotId)
    local creatureID, creatureName, _, _, _ = GetCompanionInfo(companionType, slotId)

    if companionType == "CRITTER" then
        RandomSummon.petId = creatureID
        RandomSummon.slotCache.pet[creatureID] = slotId
        print("Summoning: ", creatureName)
    elseif companionType == "MOUNT" then
        RandomSummon.slotCache.mount[creatureID] = slotId
    else
        error("CallCompanion received unknown companion type")
    end

    origCallCompanion(companionType, slotId)
end

local origDismissCompanion = DismissCompanion
DismissCompanion = function(companionType)
    if companionType == "CRITTER" then RandomSummon.petId = nil end

    origDismissCompanion(companionType)
end

function RandomSummon:CallSpecific(companionType, creatureId)
    local slotCache
    if companionType == "CRITTER" then
        RandomSummon.petId = creatureId
        slotCache = RandomSummon.slotCache.pet
    elseif companionType == "MOUNT" then
        slotCache = RandomSummon.slotCache.mount
    else
        error("CallSpecific received unknown companion type")
    end

    local slotId = slotCache[creatureId]

    local creatureID, _, _, _, _ = GetCompanionInfo(companionType, slotId)

    if creatureID ~= creatureId then
        slotId = -1
        for i=1, GetNumCompanions(companionType) do
            creatureID, _, _, _, _ = GetCompanionInfo(companionType, i)

            slotCache[creatureID] = i

            if creatureID == creatureId then
                slotId = i
                break
            end
        end

        if slotId == -1 then
            error("CallSpecific received unknown creature id")
        end
    end

    origCallCompanion(companionType, slotId)
end

local zoneStrings = RandomSummon.zoneStrings[GetLocale()]

function RandomSummon:CanFly()
    if IsFlyableArea() then
        name, _, _, _, _, _, _, instanceID, _, _ = GetInstanceInfo()
        -- Need Cold Weather Flying in Northrend
        if instanceID == 571 then
            -- Can't fly in Dalaran, except Krasus' Landing
            if not IsSpellKnown(54197) then
                return false
            elseif GetZoneText() == zoneStrings.dalaran then
                return (GetSubZoneText() == zoneStrings.krasus)
            end
        end

        return true
    end

    return false
end
