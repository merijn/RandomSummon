local AddonName, Addon = ...

Addon.petId = nil
Addon.slotCache = { pet={}, mount={} }

local origCallCompanion = CallCompanion
CallCompanion = function(companionType, slotId)
    local creatureID, creatureName, _, _, _ = GetCompanionInfo(companionType, slotId)

    if companionType == "CRITTER" then
        Addon.petId = creatureID
        Addon.slotCache.pet[creatureID] = slotId
        print("Summoning: ", creatureName)
    elseif companionType == "MOUNT" then
        Addon.slotCache.mount[creatureID] = slotId
    else
        error("CallCompanion received unknown companion type")
    end

    origCallCompanion(companionType, slotId)
end

local origDismissCompanion = DismissCompanion
DismissCompanion = function(companionType)
    if companionType == "CRITTER" then Addon.petId = nil end

    origDismissCompanion(companionType)
end

function Addon:CallSpecific(companionType, creatureId)
    local slotCache
    if companionType == "CRITTER" then
        Addon.petId = creatureId
        slotCache = Addon.slotCache.pet
    elseif companionType == "MOUNT" then
        slotCache = Addon.slotCache.mount
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
