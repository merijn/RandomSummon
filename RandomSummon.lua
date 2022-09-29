local AddonName = ...

local Addon = CreateFrame("Frame", AddonName)

local petSlotCache = {}
local petId = nil

local mountSlotCache = {}
local mounts = {}

local origCallCompanion = CallCompanion
CallCompanion = function(companionType, slotId)
    local creatureID, creatureName, creatureSpellID,
          icon, issummoned = GetCompanionInfo(companionType, slotId)

    if companionType == "CRITTER" then
        petId = creatureID
        petSlotCache[creatureID] = slotId
        print("Summoning: ", creatureName)
    elseif companionType == "MOUNT" then
        mountSlotCache[creatureID] = slotId
    else
        error("CallCompanion received unknown companion type")
    end

    origCallCompanion(companionType, slotId)
end

local origDismissCompanion = DismissCompanion
DismissCompanion = function(companionType)
    if companionType == "CRITTER" then petId = nil end

    origDismissCompanion(companionType)
end

local function CallSpecific(companionType, creatureId)
    local slotId = -1
    if companionType == "CRITTER" then
        petId = creatureId
        slotId = petSlotCache[creatureId]
    elseif companionType == "MOUNT" then
        slotId = mountSlotCache[creatureId]
    else
        error("CallSpecific received unknown companion type")
    end

    local creatureID, creatureName, creatureSpellID,
          icon, issummoned = GetCompanionInfo(companionType, slotId)

    if creatureID ~= creatureId then
        slotId = -1
        for i=1, GetNumCompanions(companionType) do
            creatureID, creatureName, creatureSpellID,
                icon, issummoned = GetCompanionInfo(companionType, i)

            if companionType == "CRITTER" then
                petSlotCache[creatureID] = i
            else
                mountSlotCache[creatureID] = i
            end

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

local function SummonRandom()
    local num = GetNumCompanions("CRITTER")
    if num > 0 then
        CallCompanion("CRITTER", random(num))
    end
end

local function CheckActivePet()
    if petId then
        local creatureID, creatureName, creatureSpellID, icon, issummoned
              = GetCompanionInfo("CRITTER", petSlotCache[petId])

        if creatureID == petId and issummoned then return true end
    end

    local activeFound = false
    local oldPetId = petId
    petId = nil
    for i=1,GetNumCompanions("CRITTER") do
        local creatureID, creatureName, creatureSpellID,
            icon, issummoned = GetCompanionInfo("CRITTER", i)

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
    elseif IsFalling() then
        return "FALLING"
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

local function CheckMounts()
    mounts = {
        fly={size=0},
        swim={size=0},
        ground={size=0}
    }

    for i=1,GetNumCompanions("MOUNT") do
        local creatureID, creatureName, creatureSpellID,
            icon, issummoned = GetCompanionInfo("MOUNT", i)

        mountSlotCache[creatureID] = i

        local spell = Spell:CreateFromSpellID(creatureSpellID)
        spell:ContinueOnSpellLoad(function()
            local desc = spell:GetSpellDescription()

            local flying = string.find(desc, "This mount can only be summoned in Outland or Northrend.")
            local epic = string.find(desc, "This is a very fast mount.")
            local swimming = string.find(desc, "This mount can't move very quickly on land, but she's a great swimmer.")

            if swimming then
                mounts.swim.size = mounts.swim.size + 1
                table.insert(mounts.swim, creatureID)
            elseif flying then
                mounts.fly.size = mounts.fly.size + 1
                table.insert(mounts.fly, creatureID)
            else
                mounts.ground.size = mounts.ground.size + 1
                table.insert(mounts.ground, creatureID)
            end
        end)
    end
end

local function CanFly()
    if IsFlyableArea() then
        name, _, _, _, _, _, _, instanceID, _, _ = GetInstanceInfo()
        -- Need Cold Weather Flying in Northrend
        if instanceID == 571 then
            return IsSpellKnown(54197)
        end

        return true
    end

    return false
end

function RandomSummonMount()
    if IsMounted() then
        DismissCompanion("MOUNT")
        return
    end

    if (IsSwimming() or IsSubmerged()) and mounts.swim.size > 0 then
        CallSpecific("MOUNT", mounts.swim[random(mounts.swim.size)])
    elseif CanFly() and mounts.fly.size > 0 then
        CallSpecific("MOUNT", mounts.fly[random(mounts.fly.size)])
    else
        CallSpecific("MOUNT", mounts.ground[random(mounts.ground.size)])
    end
end

local macroFlyable = "#showtooltip\n/cast [swimming] Aquatic Form; [flyable,nocombat] !Swift Flight Form; !Travel Form"
local macroUnflyable = "#showtooltip\n/cast [swimming] Aquatic Form; !Travel Form"
local function UpdateDruidMacro()
    if not GetMacroInfo("RandomSummonForm") then
        if CanFly() then
            CreateMacro("RandomSummonForm", "INV_MISC_QUESTIONMARK", macroFlyable, true)
        else
            CreateMacro("RandomSummonForm", "INV_MISC_QUESTIONMARK", macroUnflyable, true)
        end
    elseif CanFly() then
        EditMacro("RandomSummonForm", "RandomSummonForm", "INV_MISC_QUESTIONMARK", macroFlyable, true)
    else
        EditMacro("RandomSummonForm", "RandomSummonForm", "INV_MISC_QUESTIONMARK", macroUnflyable, true)
    end
end

local function RandomSummon_OnEvent(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local active = CheckActivePet()

        if select(1, ...) or select(2, ...) then
            -- Initialisation
            CheckMounts()
        end

        _, playerClass, _ = UnitClass("player")
        if playerClass == "DRUID" and not InCombatLockdown() then
            UpdateDruidMacro()
        end
        EnsureRandomCompanion()
    elseif event == "COMPANION_LEARNED" or event == "COMPANION_UNLEARNED" then
        -- rebuild metadata
        CheckMounts()
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
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        print(event, ...)
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
Addon:RegisterEvent("PLAYER_ALIVE")
Addon:RegisterEvent("PLAYER_UNGHOST")
Addon:RegisterEvent("COMPANION_UPDATE")
_, playerClass, _ = UnitClass("player")
if playerClass == "DRUID" then
    Addon:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    Addon:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
end
