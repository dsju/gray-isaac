
local root = "unlockapi" -- Replace this with the path of the "unlockapi" folder in your mod
local modname = "GrayIsaac" --Replace with your mod name
local version = 0.35

if not UnlockAPI then
    UnlockAPI = {}
else
    UnlockAPI.ModRegistry[modname] = { Characters = {}, Challenges = {}, } --luamod shouldn't matter
    if UnlockAPI.Version > version then return end
    UnlockAPI.Callback:RemoveAllCallbacks()
end

Isaac.ConsoleOutput("TSC Unlock API v" .. version .. ": ")

UnlockAPI = { --Imitation is the sincerest form of flattery, dsju 2023
    Mod = RegisterMod("TSC Unlock API (" .. modname.. ")", 1),
    Helper = {},
    Library = {},
    Enums = {},
    Unlocks = UnlockAPI.Unlocks or {
        TaintedCharacters = {},
        Collectibles = {},
        Trinkets = {},
        Entities = {},
        Cards = {},
        CustomEntry = {},
    },
    Constants = {},
    Save = UnlockAPI.Save or { Loaded = false, Characters = {}, Challenges = {}, },
    Callback = {},
    Compatibility = {},
    Characters = UnlockAPI.Characters or {},
    Challenges = UnlockAPI.Challenges or {},
    DisplayNames = UnlockAPI.DisplayNames or {},
    AchievementPapers = {},
    ModRegistry = UnlockAPI.ModRegistry or { [modname] = { Characters = {}, Challenges = {}, } },
    Version = version,
}

local scripts = {
    "enums",

    "system.callback",
    "system.save",
    "system.papers",

    "compatibility.pause_screen_completion_marks_api",

    "system.unlock.beatBoss",
    "system.unlock.tainted",
    "system.unlock.beatRoom",
    "system.unlock.challenge",

    "system.lock.collectible",
    "system.lock.trinket",
    "system.lock.card",
    "system.lock.tainted",
    "system.lock.entity",

    "helper.fulfilledRequirements",
    "helper.getPlayerUnlockData",
    "helper.updateUnlocks",
    "helper.showUnlock",
    "helper.isRegisteredCharacter",
    "helper.getTaintedData",
    "helper.isTainted",
    "helper.trySpawnTaintedSlot",
    "helper.setRequirements",
    "helper.mergeTablesInside",

    "library.register",
    "library.isUnlocked",
    "library.saving",

    "commands.unlock",
    "commands.unlockall",
    "commands.blank",
}

for _, script in pairs(scripts) do include(root .. "." .. script) end

Isaac.ConsoleOutput('Loaded! Type "unlockapi" in the console to see valid commands.\n')
UnlockAPI.Enums = {
    ---@enum RequirementType
    RequirementType = {
        MOMSHEART = 2^1,
        ISAAC = 2^2,
        SATAN = 2^3,
        LAMB = 2^4,
        BLUEBABY = 2^5,
        BOSSRUSH = 2^6,
        HUSH = 2^7,
        MEGASATAN = 2^8,
        MOTHER = 2^9,
        WITNESS = 2^9, --Legacy
        BEAST = 2^10,
        DELIRIUM = 2^11,
        GREED = 2^12,
        MOMSFOOT = 2^13, --oops!

        TAINTED = 2^16,

        HARDMODE = 2^32,
    },

    ModCallbacksCustom = {
        MC_PRE_LOCKED_ENTITY_SPAWN = "UNLOCKAPI_PRE_LOCKED_ENTITY_SPAWN",
        MC_POST_LOCKED_ENTITY_INIT_LATE = "UNLOCKAPI_POST_LOCKED_ENTITY_INIT_LATE",

        MC_BEAT_REQUIREMENT = "UNLOCKAPI_BEAT_REQUIREMENT",

        MC_UNLOCK_COLLECTIBLE = "UNLOCKAPI_UNLOCK_COLLECTIBLE",
        MC_UNLOCK_TRINKET = "UNLOCKAPI_UNLOCK_TRINKET",
        MC_UNLOCK_CARD = "UNLOCKAPI_UNLOCK_CARD",
        MC_UNLOCK_ENTITY = "UNLOCKAPI_UNLOCK_ENTITY",
        MC_UNLOCK_CUSTOMENTRY = "UNLOCKAPI_UNLOCK_CUSTOMENTRY",
        MC_UNLOCK_TAINTED = "UNLOCKAPI_UNLOCK_TAINTED",

        MC_PRE_CHANGE_PICKUP_COLLECTIBLE = "UNLOCKAPI_PRE_CHANGE_PICKUP_COLLECTIBLE",
        MC_PRE_CHANGE_PICKUP_TRINKET = "UNLOCKAPI_PRE_CHANGE_PICKUP_TRINKET",
        MC_PRE_CHANGE_PICKUP_CARD = "UNLOCKAPI_PRE_CHANGE_PICKUP_CARD",

        MC_PRE_CHANGE_HELD_COLLECTIBLE = "UNLOCKAPI_PRE_CHANGE_HELD_COLLECTIBLE",
        MC_PRE_CHANGE_HELD_TRINKET = "UNLOCKAPI_PRE_CHANGE_HELD_TRINKET",
        MC_PRE_CHANGE_HELD_CARD = "UNLOCKAPI_PRE_CHANGE_HELD_CARD",
    },

    CallbackPriority = {
        LATEST = 2^30,
        BEFORE_LATEST = 2^30 - 1,
        EARLIEST = -2^30,
        AFTER_EARLIEST = -2^30 + 1,
    },

    RandomPopupPreventionAchievement = {{{
        UnlockRequirements = "So guys, we did it, we reached a quarter of a million subscribers, 250,000 subscribers and still growing. The fact that we've reached this number in such a short amount of time is just phenomenal, I'm- I'm just amazed. Thank you all so much for supporting this channel and helping it grow. I- I love you guys... You guys are just awesome.",
        AchievementGfx = nil,
    }}}
}
--Constants
UnlockAPI.Constants.PAUSE_SCREEN_COMPLETION_NUMBERS = {
    Locked = 0,
    Normal = 1,
    Hard = 2,
}

--Function (core)
function UnlockAPI.Compatibility.AddPauseScreenCompletionMarks(playerName)
    local playerType = UnlockAPI.Helper.GetPlayerTypeFromUnlockName(playerName)
    if not playerType then return end

    PauseScreenCompletionMarksAPI:AddModCharacterCallback(playerType, function()
        return UnlockAPI.Compatibility.GetPauseScreenCompletionMarksTable(playerName)
    end)
end

function UnlockAPI.Compatibility.GetPauseScreenCompletionMarksTable(playerName)
    local playerSave = UnlockAPI.Save.Characters[playerName]
    if not playerSave then return {} end

    local completionMarks = {}

    for markName, requirementType in pairs(UnlockAPI.Enums.RequirementType) do
        if UnlockAPI.Helper.FulfilledAllRequirements(requirementType, playerSave) then
            if UnlockAPI.Helper.FulfilledAllRequirements(requirementType | UnlockAPI.Enums.RequirementType.HARDMODE, playerSave) then
                completionMarks[markName] = UnlockAPI.Constants.PAUSE_SCREEN_COMPLETION_NUMBERS.Hard
            else
                completionMarks[markName] = UnlockAPI.Constants.PAUSE_SCREEN_COMPLETION_NUMBERS.Normal
            end
        else
            completionMarks[markName] = UnlockAPI.Constants.PAUSE_SCREEN_COMPLETION_NUMBERS.Locked
        end
    end

    return completionMarks
end

--Functions (helper)
function UnlockAPI.Helper.GetPlayerTypeFromUnlockName(playerName)
    local possibleTypes = {
        Isaac.GetPlayerTypeByName(playerName, false),
        Isaac.GetPlayerTypeByName(playerName, true),
        Isaac.GetPlayerTypeByName(playerName:gsub(UnlockAPI.Constants.TAINTED_PREFIX, ""), true)
    }

    for _, playerType in pairs(possibleTypes) do
        if playerType >= PlayerType.PLAYER_ISAAC then
            return playerType
        end
    end
end
--Classes
local game = Game()

--Constants
UnlockAPI.Constants.TAINTED_SLOT_VARIANT = 14

--Function (helper)
function UnlockAPI.Helper.TrySpawnTaintedSlot(player)
    if game:GetRoom():IsFirstVisit() then
        for _, entity in pairs({ table.unpack(Isaac.FindByType(EntityType.ENTITY_SHOPKEEPER)), table.unpack(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_INNER_CHILD)) }) do
            entity:Remove()
            entity.Visible = false
        end
    end

    local slot = Isaac.FindByType(EntityType.ENTITY_SLOT, UnlockAPI.Constants.TAINTED_SLOT_VARIANT)[1] or Isaac.Spawn(EntityType.ENTITY_SLOT, UnlockAPI.Constants.TAINTED_SLOT_VARIANT, 0, game:GetRoom():GetCenterPos(), Vector.Zero, nil)
    local slotSprite = slot:GetSprite()

    if not player then return slot end

    local taintedData = UnlockAPI.Helper.GetTaintedData(player:GetName())
    if taintedData.SlotSpritesheet then
        slotSprite:ReplaceSpritesheet(0, taintedData.SlotSpritesheet)
        slotSprite:LoadGraphics()
    end

    return slot
end
function UnlockAPI.Helper.GetTaintedData(playerName)
    local taintedType = Isaac.GetPlayerTypeByName(playerName, true)
    if UnlockAPI.Unlocks.TaintedCharacters[taintedType] then
        return UnlockAPI.Unlocks.TaintedCharacters[taintedType]
    else
        for taintedName, taintedData in pairs(UnlockAPI.Unlocks.TaintedCharacters) do
            if taintedData.NormalPlayerName == playerName then
                return taintedData
            end
        end
    end
end
UnlockAPI.Constants.VANILLA_TAINTED_PLAYERTYPE_MIN = PlayerType.PLAYER_ISAAC_B
UnlockAPI.Constants.VANILLA_TAINTED_PLAYERTYPE_MAX = PlayerType.PLAYER_THESOUL_B

function UnlockAPI.Helper.IsTainted(player)
    local playerType = player:GetPlayerType()
    return (UnlockAPI.Constants.VANILLA_TAINTED_PLAYERTYPE_MIN <= playerType and playerType <= UnlockAPI.Constants.VANILLA_TAINTED_PLAYERTYPE_MAX) or playerType == Isaac.GetPlayerTypeByName(player:GetName(), true)
end
--Classes
local game = Game()
local hud = game:GetHUD()
local sfx = SFXManager()

--Constants
UnlockAPI.Constants.PREFIX_DISABLE_ACHIEVEMENTPAPER = "!!NOPAPER!!"

--Function
function UnlockAPI.Helper.ShowUnlock(text)
    if not text then return end

    if text:find(UnlockAPI.Constants.PREFIX_DISABLE_ACHIEVEMENTPAPER) == 1 then
        hud:ShowItemText(text:gsub(UnlockAPI.Constants.PREFIX_DISABLE_ACHIEVEMENTPAPER, ""), nil)
        sfx:Play(SoundEffect.SOUND_PAPER_OUT)
    else
        table.insert(UnlockAPI.AchievementPapers, text)
    end
end
UnlockAPI.Constants.TAINTED_PREFIX = "t."

function UnlockAPI.Helper.GetPlayerUnlockData(player)
    local displayName
    if type(player) ~= "string" then
        local playerType = player:GetPlayerType()
        displayName = UnlockAPI.DisplayNames[playerType]
    else
        displayName = player
    end

    local playerName = displayName or player:GetName()

    local isTainted = not displayName and UnlockAPI.Helper.IsTainted(player)

    local playerSaveString = playerName
    if isTainted then
        playerSaveString = UnlockAPI.Constants.TAINTED_PREFIX .. playerSaveString
    end

    if not UnlockAPI.Save.Characters[playerSaveString] then
        UnlockAPI.Save.Characters[playerSaveString] = {}
    end

    return UnlockAPI.Save.Characters[playerSaveString], playerSaveString
end
function UnlockAPI.Helper.SetRequirements(requirementBitmask, playerName, bool)
    local extraMask = requirementBitmask & UnlockAPI.Enums.RequirementType.HARDMODE == UnlockAPI.Enums.RequirementType.HARDMODE and UnlockAPI.Enums.RequirementType.HARDMODE or 0
    for _, requirement in pairs(UnlockAPI.Constants.REQUIREMENTS_VALID_NONMASK) do
        if requirementBitmask | requirement | extraMask == requirementBitmask then
            UnlockAPI.Helper.GetPlayerUnlockData(playerName)[tostring(math.floor(requirement | extraMask))] = bool
        end
    end
end
--Function (helper ^ 2)
local function CloneTable(t)
    local table = {}
    for i, v in pairs(t) do
        table[i] = v
    end
    return table
end

--Function (helper)
function UnlockAPI.Helper.MergeTablesInside(...)
    local mergedTable = {}

    local currentId = 0

    for _, currentTable in pairs({...}) do
        for tableName, tableToMerge in pairs(currentTable) do
            for id, value in pairs(tableToMerge) do
                currentId = currentId + 1

                print(value)
                local newTable = CloneTable(value)
                newTable.ID = newTable.Type or id
                newTable.UnlockCallback = UnlockAPI.Constants.TABLE_NAME_TO_CALLBACK[tableName]
                newTable.AchievementID = currentId

                table.insert(mergedTable, newTable)
            end
        end
    end

    return mergedTable
end
--Classes
local game = Game()

--Constants
UnlockAPI.Constants.REQUIREMENTS_VALID_NONMASK = {}

for _, unlockType in pairs(UnlockAPI.Enums.RequirementType) do
    if unlockType ~= UnlockAPI.Enums.RequirementType.HARDMODE then
        table.insert(UnlockAPI.Constants.REQUIREMENTS_VALID_NONMASK, unlockType)
    end
end

local function CheckBitmask(requirementBitmask, saveTable)
    if not saveTable then return false end
    local extraMask = requirementBitmask & UnlockAPI.Enums.RequirementType.HARDMODE == UnlockAPI.Enums.RequirementType.HARDMODE and UnlockAPI.Enums.RequirementType.HARDMODE or 0

    for name, requirement in pairs(UnlockAPI.Constants.REQUIREMENTS_VALID_NONMASK) do
        if requirementBitmask | requirement | extraMask == requirementBitmask then
            if not saveTable[tostring(math.floor(requirement | extraMask))] then --Flooring to get rid of the annoying .0 at the end
                return false
            end
        end
    end
    return true
end

--Function (helper)
function UnlockAPI.Helper.FulfilledAllRequirements(requirementBitmask, saveTable)
    if type(requirementBitmask) == "string" then
        return UnlockAPI.Save.Challenges[requirementBitmask]
    else
        return CheckBitmask(requirementBitmask, saveTable)
    end
end
local game = Game()

--Constants
UnlockAPI.Constants.TABLE_NAME_TO_CALLBACK = {
    TaintedCharacters = UnlockAPI.Enums.ModCallbacksCustom.MC_UNLOCK_TAINTED,
    Collectibles = UnlockAPI.Enums.ModCallbacksCustom.MC_UNLOCK_COLLECTIBLE,
    Trinkets = UnlockAPI.Enums.ModCallbacksCustom.MC_UNLOCK_TRINKET,
    Entities = UnlockAPI.Enums.ModCallbacksCustom.MC_UNLOCK_ENTITY,
    Cards = UnlockAPI.Enums.ModCallbacksCustom.MC_UNLOCK_CARD,
    CustomEntry = UnlockAPI.Enums.ModCallbacksCustom.MC_UNLOCK_CUSTOMENTRY,
}

--Function (helper^2)
local function GetRequirementsToAdd(requirementType)
    local requirementsToAdd = {}
    table.insert(requirementsToAdd, requirementType)

    if requirementType ~= UnlockAPI.Enums.RequirementType.TAINTED and game.Difficulty == Difficulty.DIFFICULTY_HARD or game.Difficulty == Difficulty.DIFFICULTY_GREEDIER then
        table.insert(requirementsToAdd, requirementType | UnlockAPI.Enums.RequirementType.HARDMODE)
    end

    return requirementsToAdd
end

--Function (helper)
function UnlockAPI.Helper.UpdateUnlocks(requirementType, specifiedPlayer)
    local newRequirementsFulfiled = {}

    local requirementsToAdd = GetRequirementsToAdd(requirementType)
    for _, entityPlayer in pairs(Isaac.FindByType(EntityType.ENTITY_PLAYER)) do

        local playerUnlockData, playerName = UnlockAPI.Helper.GetPlayerUnlockData(specifiedPlayer or entityPlayer:ToPlayer())
        for _, requirementId in pairs(requirementsToAdd) do

            Isaac.RunCallbackWithParam(UnlockAPI.Enums.ModCallbacksCustom.MC_BEAT_REQUIREMENT, requirementId, entityPlayer:ToPlayer(), requirementId)

            local requirementIdString = tostring(math.floor(requirementId))

            if not playerUnlockData[requirementIdString] then
                table.insert(newRequirementsFulfiled, { UnlockData = playerUnlockData, Requirement = requirementId, PlayerName = playerName })
                playerUnlockData[requirementIdString] = true
            end
        end

        if specifiedPlayer then break end
    end

    local alreadyUnlockedData = {} --To fix "the callback runs twice" problem
    for _, tableName in pairs(UnlockAPI.Constants.TABLE_NAME_TO_CALLBACK) do alreadyUnlockedData[tableName] = {} end

    for _, fulfilledData in pairs(newRequirementsFulfiled) do
        for _, achievementData in pairs(UnlockAPI.Helper.MergeTablesInside(UnlockAPI.Unlocks, UnlockAPI.Enums.RandomPopupPreventionAchievement)) do

            if type(achievementData.UnlockRequirements) == "string" or (achievementData.UnlockRequirements or 0) & fulfilledData.Requirement ~= fulfilledData.Requirement then goto continue end
            if alreadyUnlockedData[achievementData.AchievementID] or not (fulfilledData.PlayerName == achievementData.PlayerName and UnlockAPI.Helper.FulfilledAllRequirements(achievementData.UnlockRequirements, fulfilledData.UnlockData)) then goto continue end

            UnlockAPI.Helper.ShowUnlock(achievementData.AchievementGfx)
            Isaac.RunCallbackWithParam(achievementData.UnlockCallback, achievementData.ID, achievementData)

            alreadyUnlockedData[achievementData.AchievementID] = true

            ::continue::
        end
    end
end
--Function (helper)
function UnlockAPI.Helper.IsRegisteredCharacter(player)
    local playerType = player:GetPlayerType()

    local displayName = UnlockAPI.DisplayNames[playerType]
    local playerName = displayName or player:GetName()

    local isTainted = not displayName and playerName == Isaac.GetPlayerTypeByName(playerName, true)

    local playerSaveString = playerName
    if isTainted then
        playerSaveString = UnlockAPI.Constants.TAINTED_PREFIX .. playerSaveString
    end

    return not not UnlockAPI.Characters[playerSaveString]
end
--Variable
local functionsAndCallbacks = {}

--Functions (mod)
function UnlockAPI.Mod:AddCallback(modCallback, callbackFunction, callbackArguments)
    Isaac.AddCallback(UnlockAPI.Mod, modCallback, callbackFunction, callbackArguments)
    table.insert(functionsAndCallbacks, {
        Callback = modCallback,
        Function = callbackFunction,
    })
end

function UnlockAPI.Mod:AddPriorityCallback(modCallback, callbackPriority, callbackFunction, callbackArguments)
    Isaac.AddPriorityCallback(UnlockAPI.Mod, modCallback, callbackPriority, callbackFunction, callbackArguments)
    table.insert(functionsAndCallbacks, {
        Callback = modCallback,
        Function = callbackFunction,
    })
end

--Function (core)
function UnlockAPI.Callback:RemoveAllCallbacks()
    for _, callbackData in pairs(functionsAndCallbacks) do
        Isaac.RemoveCallback(UnlockAPI.Mod, callbackData.Callback, callbackData.Function)
    end
end
--Classes
local sfx = SFXManager()

--Constants
UnlockAPI.Constants.ACHIEVEMENT_PAPER_APPEAR_ANIM = "Appear"
UnlockAPI.Constants.ACHIEVEMENT_PAPER_DISAPPEAR_ANIM = "Dissapear" --Fuck you nicalis
UnlockAPI.Constants.ACHIEVEMENT_PAPER_OVERLAY_SPRITESHEET_ID = 3
UnlockAPI.Constants.ACHIEVEMENT_PAPER_FRAME_START_DISAPPEAR = 200
UnlockAPI.Constants.ACHIEVEMENT_PAPER_FRAME_NEXT_UNLOCK = 220
UnlockAPI.Constants.ACHIEVEMENT_PAPER_FRAME_START = 0
UnlockAPI.Constants.ACHIEVEMENT_PAPER_UPDATE_MODULO = 2
UnlockAPI.Constants.ACHIEVEMENT_PAPER_SCREEN_DIV = 2

--Instances
local achievementSprite = Sprite()
achievementSprite:Load("gfx/ui/achievement/achievements.anm2", true)
achievementSprite:Play(achievementSprite:GetDefaultAnimation())

--Variables
local currentFrame = 0

--Function (callback)
function UnlockAPI.Callback:PostAchievementRender()
    if #UnlockAPI.AchievementPapers == 0 and currentFrame <= UnlockAPI.Constants.ACHIEVEMENT_PAPER_FRAME_START  then return end

    if currentFrame == UnlockAPI.Constants.ACHIEVEMENT_PAPER_FRAME_START then

        achievementSprite:ReplaceSpritesheet(UnlockAPI.Constants.ACHIEVEMENT_PAPER_OVERLAY_SPRITESHEET_ID, UnlockAPI.AchievementPapers[1])
        achievementSprite:LoadGraphics()
        achievementSprite:Play(UnlockAPI.Constants.ACHIEVEMENT_PAPER_APPEAR_ANIM, true)
        sfx:Play(SoundEffect.SOUND_BOOK_PAGE_TURN_12)

    elseif currentFrame == UnlockAPI.Constants.ACHIEVEMENT_PAPER_FRAME_START_DISAPPEAR then
        achievementSprite:Play(UnlockAPI.Constants.ACHIEVEMENT_PAPER_DISAPPEAR_ANIM, true)

    elseif currentFrame == UnlockAPI.Constants.ACHIEVEMENT_PAPER_FRAME_NEXT_UNLOCK then
        currentFrame = UnlockAPI.Constants.ACHIEVEMENT_PAPER_FRAME_START
        table.remove(UnlockAPI.AchievementPapers, 1)

        return
    end

    if currentFrame % UnlockAPI.Constants.ACHIEVEMENT_PAPER_UPDATE_MODULO == 0 then
        achievementSprite:Update()
    end
    achievementSprite:Render(Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())/UnlockAPI.Constants.ACHIEVEMENT_PAPER_SCREEN_DIV)

    currentFrame = currentFrame + 1

    if currentFrame % UnlockAPI.Constants.ACHIEVEMENT_PAPER_UPDATE_MODULO ~= 0 then return end

    for _, entityPlayer in pairs(Isaac.FindByType(EntityType.ENTITY_PLAYER)) do
        local player = entityPlayer:ToPlayer()
        player:SetMinDamageCooldown(player:GetDamageCooldown() + 1)
    end
end

--Init
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, UnlockAPI.Callback.PostAchievementRender)
function UnlockAPI.Callback:ClearSaveData()
    UnlockAPI.Save = { Characters = {}, Challenges = {} }
end

function UnlockAPI.Callback:SetSaveDataLoaded()
    UnlockAPI.Save.Loaded = false --Gets set by UnlockAPI.Library:LoadSaveData()
end

UnlockAPI.Mod:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, UnlockAPI.Enums.CallbackPriority.EARLIEST, UnlockAPI.Callback.ClearSaveData)
UnlockAPI.Mod:AddPriorityCallback(ModCallbacks.MC_PRE_GAME_EXIT, UnlockAPI.Enums.CallbackPriority.EARLIEST, UnlockAPI.Callback.SetSaveDataLoaded)
--Classes
local game = Game()
local itemPool = game:GetItemPool()
local itemConfig = Isaac.GetItemConfig()

--Constants
UnlockAPI.Constants.MAX_TRIES_GET_SAME_TYPE_COLLECTIBLE = 100

--Function (callback)
function UnlockAPI.Callback:PlayerCheckCollectiblesUpdate(player)
    if not UnlockAPI.Save.Loaded then return end

    for collectibleType in pairs(UnlockAPI.Unlocks.Collectibles) do
        if player:HasCollectible(collectibleType) and not UnlockAPI.Library:IsCollectibleUnlocked(collectibleType) then
            UnlockAPI.Helper.FullyReplaceCollectible(player, collectibleType)
        end
    end
end

function UnlockAPI.Callback:PostCollectibleInit(pickup)
    if not UnlockAPI.Save.Loaded or UnlockAPI.Library:IsCollectibleUnlocked(pickup.SubType) or Isaac.RunCallbackWithParam(UnlockAPI.Enums.ModCallbacksCustom.MC_PRE_CHANGE_PICKUP_COLLECTIBLE, pickup.SubType, pickup, pickup.SubType) then return end
    pickup:Morph(pickup.Type, pickup.Variant, 0, true, true)
end

--Functions (helper)
function UnlockAPI.Helper.FullyReplaceCollectible(player, collectibleType)
    if Isaac.RunCallbackWithParam(UnlockAPI.Enums.ModCallbacksCustom.MC_PRE_CHANGE_HELD_COLLECTIBLE, collectibleType, player, collectibleType) then return end

    for _ = 1, player:GetCollectibleNum(collectibleType) do
        local activeSlot = UnlockAPI.Helper.GetActiveItemSlot(player, collectibleType)
        player:RemoveCollectible(collectibleType)

        local collectibleConfig = UnlockAPI.Helper.GetItemConfigOfSameType(collectibleType)
        player:AddCollectible(collectibleConfig.ID, collectibleConfig.MaxCharges, true, activeSlot)
    end
end

function UnlockAPI.Helper.GetItemConfigOfSameType(collectibleType)
    local itemType = itemConfig:GetCollectible(collectibleType).Type

    local tries = 0
    while tries < UnlockAPI.Constants.MAX_TRIES_GET_SAME_TYPE_COLLECTIBLE do
        local chosenCollectible = itemPool:GetCollectible(ItemPoolType.POOL_TREASURE, false, Random(), CollectibleType.COLLECTIBLE_BREAKFAST)
        local collectibleConfig = itemConfig:GetCollectible(chosenCollectible)

        if collectibleConfig.Type == itemType then
            return collectibleConfig
        else
            tries = tries + 1
        end
    end

    return itemConfig:GetCollectible(CollectibleType.COLLECTIBLE_BREAKFAST)
end

function UnlockAPI.Helper.GetActiveItemSlot(player, collectibleType)
    for _, activeSlot in pairs(ActiveSlot) do
        if player:GetActiveItem(activeSlot) == collectibleType then
            return activeSlot
        end
    end

    return nil
end

--Init
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, UnlockAPI.Callback.PlayerCheckCollectiblesUpdate)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, UnlockAPI.Callback.PostCollectibleInit, PickupVariant.PICKUP_COLLECTIBLE)

--Variables
local spawningEntityData = {}

--Functions (callback)
function UnlockAPI.Callback:LockedPreEntitySpawn(type, variant, subtype, ...)
    if not UnlockAPI.Save.Loaded or UnlockAPI.Library:IsEntityUnlocked(type, variant, subtype) then return end

    local callbackData = Isaac.RunCallbackWithParam(UnlockAPI.Enums.ModCallbacksCustom.MC_PRE_LOCKED_ENTITY_SPAWN, type, type, variant, subtype, ...)
    if not callbackData then
        table.insert(spawningEntityData, { Type = type, Variant = variant, SubType = subtype })
    else
        return callbackData
    end
end

function UnlockAPI.Callback:LockedEntityPostRender()
    if not UnlockAPI.Save.Loaded then return end

    local checkedEntities = {}

    for _, entityData in pairs(spawningEntityData) do
        local foundEntities = Isaac.FindByType(entityData.Type, entityData.Variant, entityData.SubType)
        for entityIndex = 0, #foundEntities - 1 do
            local selectedEntity = foundEntities[#foundEntities - entityIndex]
            if not selectedEntity then goto continue end

            local entityPtr = GetPtrHash(selectedEntity)

            if selectedEntity.FrameCount ~= 0 or checkedEntities[entityPtr] then goto continue end

            Isaac.RunCallbackWithParam(UnlockAPI.Enums.ModCallbacksCustom.MC_POST_LOCKED_ENTITY_INIT_LATE, entityData.Type, selectedEntity)
            checkedEntities[entityPtr] = true

            ::continue::
        end
    end

    spawningEntityData = {}
end

--Init
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_PRE_ENTITY_SPAWN, UnlockAPI.Callback.LockedPreEntitySpawn)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, UnlockAPI.Callback.LockedEntityPostRender)
--Classes
local game = Game()
local level = game:GetLevel()
local SFX = SFXManager()
local HUD = game:GetHUD()

--Constants
UnlockAPI.Constants.TAINTED_PLUTO_WISP_NUM = 5
UnlockAPI.Constants.TAINTED_GOTO_COMMAND = "stage 13"
UnlockAPI.Constants.TAINTED_GRIDINDEX_BEFORE_CLOSET = 108
UnlockAPI.Constants.TAINTED_CLOSET_GRIDINDEX = 94
UnlockAPI.Constants.TAINTED_WISP_POSITION = Vector(5000, 5000)
UnlockAPI.Constants.MAX_SOUND_NUM = 2^16

--Variables
local playingWithLockedTainted

--Functions (callback)
function UnlockAPI.Callback:PostLockedTaintedPlayerInit(player)
    local playerName = player:GetName()
    if not (not playingWithLockedTainted and UnlockAPI.Helper.IsTainted(player) and not UnlockAPI.Library:IsTaintedUnlocked(playerName) and game:GetNumPlayers() > 1) then return end
    player:ChangePlayerType(UnlockAPI.Helper.GetTaintedData(playerName).NormalPlayerType)
end

function UnlockAPI.Callback:PostLockedTaintedPlayerUpdate(player)
	if not (playingWithLockedTainted and UnlockAPI.Helper.IsTainted(player) and not UnlockAPI.Library:IsTaintedUnlocked(player:GetName())) then return end
	for _, v in pairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR)) do v.Visible = false end
	player:GetSprite().PlaybackSpeed = 0
end

function UnlockAPI.Callback:PostLockedTaintedGameStarted(continued)
	local player = Isaac.GetPlayer(0)
	if not (UnlockAPI.Helper.IsTainted(player) and not UnlockAPI.Library:IsTaintedUnlocked(player:GetName())) then return end

    playingWithLockedTainted = true

    UnlockAPI.Helper.MakeSuperTinyAndInvisible(player)
    UnlockAPI.Helper.DisableContinuingRun(player)

	if game.Difficulty <= Difficulty.DIFFICULTY_HARD then
        UnlockAPI.Helper.GoToHomeCloset()
        UnlockAPI.Helper.MakeDoorInvisible()
	end

	HUD:SetVisible(false)
	player.MoveSpeed = 0
	player.FireDelay = 2^32-1
end

function UnlockAPI.Callback:PostLockedTaintedNewRoom(mod)
	if not (playingWithLockedTainted and level:GetCurrentRoomIndex() ~= UnlockAPI.ConstantsCLOSET_GRIDINDEX) then return end
	UnlockAPI.Helper.MakeDoorInvisible()
    UnlockAPI.Helper.TrySpawnTaintedSlot(Isaac.GetPlayer(0))
end

function UnlockAPI.Callback:PostLockedTaintedRender(mod)
	if not (playingWithLockedTainted and game.Difficulty <= Difficulty.DIFFICULTY_HARD and level:GetCurrentRoomIndex() ~= UnlockAPI.Constants.TAINTED_CLOSET_GRIDINDEX) then return end
	UnlockAPI.Helper.GoToHomeCloset()
end

function UnlockAPI.Callback:PreLockedTaintedGameExit(mod)
	playingWithLockedTainted = false
end

--Functions (helper)
function UnlockAPI.Helper.MakeSuperTinyAndInvisible(player)
	for i = 1, UnlockAPI.Constants.TAINTED_PLUTO_WISP_NUM do
		local wisp = Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.ITEM_WISP, CollectibleType.COLLECTIBLE_PLUTO, UnlockAPI.Constants.TAINTED_WISP_POSITION, Vector.Zero, player)
		wisp:ClearEntityFlags(EntityFlag.FLAG_APPEAR)
		wisp.Visible = false
	end
	player.Visible = false
end

function UnlockAPI.Helper.DisableContinuingRun(player)
	player:Die()
	local playerSprite = player:GetSprite()
	playerSprite.PlaybackSpeed = 0
    player:Update()

    UnlockAPI.Helper.StopAllSounds() --Thanks spoop for scaring me with the red isaac splat sound :)
end

function UnlockAPI.Helper.GoToHomeCloset()
	Isaac.ExecuteCommand(UnlockAPI.Constants.TAINTED_GOTO_COMMAND)
	level:MakeRedRoomDoor(UnlockAPI.Constants.TAINTED_GRIDINDEX_BEFORE_CLOSET, DoorSlot.LEFT0)
	level:ChangeRoom(UnlockAPI.Constants.TAINTED_CLOSET_GRIDINDEX)
	level:ChangeRoom(UnlockAPI.Constants.TAINTED_CLOSET_GRIDINDEX)
end

function UnlockAPI.Helper.MakeDoorInvisible()
	for _, doorSlot in pairs(DoorSlot) do
		local door = game:GetRoom():GetDoor(doorSlot)
		if door then
			door:GetSprite().Scale = Vector.Zero
			return
		end
	end
end

function UnlockAPI.Helper.StopAllSounds()
    for i = 0, UnlockAPI.Constants.MAX_SOUND_NUM do
        SFX:Stop(i)
    end
end

--Init
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, UnlockAPI.Callback.PostLockedTaintedPlayerInit)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, UnlockAPI.Callback.PostLockedTaintedPlayerUpdate)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, UnlockAPI.Callback.PostLockedTaintedNewRoom)
UnlockAPI.Mod:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, UnlockAPI.Enums.CallbackPriority.LATEST, UnlockAPI.Callback.PostLockedTaintedGameStarted)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, UnlockAPI.Callback.PreLockedTaintedGameExit)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_RENDER, UnlockAPI.Callback.PostLockedTaintedRender)
--Classes
local game = Game()
local itemPool = game:GetItemPool()

--Functions (callback)
function UnlockAPI.Callback:PlayerCheckTrinketsUpdate(player)
    if not UnlockAPI.Save.Loaded then return end

    for trinketType in pairs(UnlockAPI.Unlocks.Trinkets) do
        if player:HasTrinket(trinketType) and not UnlockAPI.Library:IsTrinketUnlocked(trinketType) then
            UnlockAPI.Helper.ReplaceTrinket(player, trinketType)
        end
    end
end

function UnlockAPI.Callback:PostTrinketInit(pickup)
    if not UnlockAPI.Save.Loaded or UnlockAPI.Library:IsTrinketUnlocked(pickup.SubType) or Isaac.RunCallbackWithParam(UnlockAPI.Enums.ModCallbacksCustom.MC_PRE_CHANGE_PICKUP_TRINKET, pickup.SubType, pickup, pickup.SubType)  then return end
    pickup:Morph(pickup.Type, pickup.Variant, 0, true, true)
end

--Function (helper)
function UnlockAPI.Helper.ReplaceTrinket(player, trinketType)
    if Isaac.RunCallbackWithParam(UnlockAPI.Enums.ModCallbacksCustom.MC_PRE_CHANGE_HELD_TRINKET, trinketType, player, trinketType) then return end
    if not player:TryRemoveTrinket(trinketType) then return end
    player:AddTrinket(itemPool:GetTrinket(false))
end

--Init
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, UnlockAPI.Callback.PlayerCheckTrinketsUpdate)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, UnlockAPI.Callback.PostTrinketInit, PickupVariant.PICKUP_TRINKET)
--Classes
local game = Game()
local itemPool = game:GetItemPool()

--Constants
UnlockAPI.Constants.MAX_TRIES_GET_SAME_TYPE_COLLECTIBLE = 100

--Function (callback)
function UnlockAPI.Callback:PlayerCheckCardUpdate(player)
    if not UnlockAPI.Save.Loaded then return end

    for card in pairs(UnlockAPI.Unlocks.Cards) do
        local cardSlot = UnlockAPI.Helper.GetCardSlot(player, card)
        if cardSlot and not UnlockAPI.Library:IsCardUnlocked(card) then
            if not Isaac.RunCallbackWithParam(UnlockAPI.Enums.ModCallbacksCustom.MC_PRE_CHANGE_HELD_CARD, card, player, card) then
                player:SetCard(cardSlot, itemPool:GetCard(Random(), false, false, false))
            end
        end
    end
end

function UnlockAPI.Callback:PostCardInit(pickup)
    if not UnlockAPI.Save.Loaded or UnlockAPI.Library:IsCardUnlocked(pickup.SubType) or Isaac.RunCallbackWithParam(UnlockAPI.Enums.ModCallbacksCustom.MC_PRE_CHANGE_PICKUP_CARD, pickup.SubType, pickup, pickup.SubType) then return end
    pickup:Morph(pickup.Type, pickup.Variant, 0, true, false)
end

--Functions (helper)
function UnlockAPI.Helper.GetCardSlot(player, card)
    for cardSlot = 0, player:GetMaxPocketItems() - 1 do
        if player:GetCard(cardSlot) == card then
            return cardSlot
        end
    end
end

--Init
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, UnlockAPI.Callback.PlayerCheckCardUpdate)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, UnlockAPI.Callback.PostCardInit, PickupVariant.PICKUP_TAROTCARD)

--Classes
local game = Game()
local level = game:GetLevel()

--Functions (callback)
function UnlockAPI.Callback:ChallengePreClearAward()
    local challengeData = UnlockAPI.Challenges[game.Challenge]
    print( UnlockAPI.Helper.CurrentRoomFulfillsUnfinishedChallengeRequirements(challengeData))
    if not (challengeData and UnlockAPI.Helper.CurrentRoomFulfillsUnfinishedChallengeRequirements(challengeData)) then return end
    UnlockAPI.Helper.FinishChallenge(challengeData)
end

--Functions (helper)
function UnlockAPI.Helper.CurrentRoomFulfillsUnfinishedChallengeRequirements(challengeData)
    print(not UnlockAPI.Save.Challenges[challengeData.Name],
    level:GetStage() >= challengeData.FinalFloor,
    game:GetRoom():GetType() == RoomType.ROOM_BOSS)
    return
    not UnlockAPI.Save.Challenges[challengeData.Name]
    and level:GetStage() >= challengeData.FinalFloor
    and game:GetRoom():GetType() == RoomType.ROOM_BOSS
end

function UnlockAPI.Helper.FinishChallenge(challengeData)
    UnlockAPI.Save.Challenges[challengeData.Name] = true
    UnlockAPI.Helper.ShowUnlock(challengeData.AchievementGfx)
end

--Init
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, UnlockAPI.Callback.ChallengePreClearAward)
--Classes
local game = Game()
local level = game:GetLevel()

--Function (callback)
function UnlockAPI.Callback:RoomPreSpawnCleanAward()
    if game.Challenge ~= Challenge.CHALLENGE_NULL then return end

    local roomType = game:GetRoom():GetType()
    if roomType == RoomType.ROOM_BOSSRUSH then
        UnlockAPI.Helper.UpdateUnlocks(UnlockAPI.Enums.RequirementType.BOSSRUSH)
    end

    if roomType == RoomType.ROOM_BOSS and level:GetStage() == LevelStage.STAGE7_GREED and game.Difficulty >= Difficulty.DIFFICULTY_GREED then
        UnlockAPI.Helper.UpdateUnlocks(UnlockAPI.Enums.RequirementType.GREED)
    end
end

--Init
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, UnlockAPI.Callback.RoomPreSpawnCleanAward)
--Classes
local game = Game()
local level = game:GetLevel()

--Constants
UnlockAPI.Constants.REQUIREMENT_TYPE_TO_BOSS_DATA = {
    [UnlockAPI.Enums.RequirementType.MOMSFOOT] = {
        Type = EntityType.ENTITY_MOM,
        Variant = { 0 },
        Stage = LevelStage.STAGE3_2,
    },

    [UnlockAPI.Enums.RequirementType.MOMSHEART] = {
        Type = EntityType.ENTITY_MOMS_HEART,
        Variant = { 0, 1 },
        Stage = LevelStage.STAGE4_2,
    },

    [UnlockAPI.Enums.RequirementType.ISAAC] = {
        Type = EntityType.ENTITY_ISAAC,
        Variant = { 0 },
        Stage = LevelStage.STAGE5,
    },

    [UnlockAPI.Enums.RequirementType.SATAN] = {
        Type = EntityType.ENTITY_SATAN,
        Variant = { 0, 10 },
        Stage = LevelStage.STAGE5,
    },

    [UnlockAPI.Enums.RequirementType.BLUEBABY] = {
        Type = EntityType.ENTITY_ISAAC,
        Variant = { 1 },
        Stage = LevelStage.STAGE6,
    },

    [UnlockAPI.Enums.RequirementType.LAMB] = {
        Type = EntityType.ENTITY_THE_LAMB,
        Variant = { 0, 10 },
        Stage = LevelStage.STAGE6,
    },

    [UnlockAPI.Enums.RequirementType.MEGASATAN] = {
        Type = EntityType.ENTITY_MEGA_SATAN_2,
        Variant = { 0 },
        Stage = LevelStage.STAGE6,
    },

    [UnlockAPI.Enums.RequirementType.DELIRIUM] = {
        Type = EntityType.ENTITY_DELIRIUM,
        Variant = { 0 },
        Stage = LevelStage.STAGE7,
    },

    [UnlockAPI.Enums.RequirementType.MOTHER] = {
        Type = EntityType.ENTITY_MOTHER,
        Variant = { 10 },
        Stage = LevelStage.STAGE4_2,
    },

    [UnlockAPI.Enums.RequirementType.BEAST] = {
        Type = EntityType.ENTITY_BEAST,
        Variant = { 0 },
        Stage = LevelStage.STAGE8,
    },

    [UnlockAPI.Enums.RequirementType.HUSH] = {
        Type = EntityType.ENTITY_HUSH,
        Variant = { 0 },
        Stage = LevelStage.STAGE4_3,
    },
}

--Variables
local queuedUnlocks = {}

--Function (callback)
function UnlockAPI.Callback:MarkBossDeath(npc)
    if game.Challenge ~= Challenge.CHALLENGE_NULL or game:GetVictoryLap() > 0 then return end

    local requirementType = UnlockAPI.Helper.GetCurrentBossRequirementType(npc)
    if not requirementType then return end

    queuedUnlocks[requirementType] = true
end

function UnlockAPI.Callback:MarkBossPostUpdate()
    if not UnlockAPI.Helper.ShouldTriggerUnlocks() then return end
    UnlockAPI.Helper.TriggerQueuedUnlocks()
end

function UnlockAPI.Callback:MarkBossPreGameExit()
    queuedUnlocks = {}
end

--Functions (helper)
function UnlockAPI.Helper.GetCurrentBossRequirementType(npc)
    local stageNum = level:GetStage()
    for requirementType, bossData in pairs(UnlockAPI.Constants.REQUIREMENT_TYPE_TO_BOSS_DATA) do
        if bossData.Stage == stageNum and UnlockAPI.Helper.IsEntityOfTable(npc, bossData) then
            return requirementType
        end
    end
end

function UnlockAPI.Helper.IsEntityOfTable(npc, data)
    if npc.Type ~= data.Type then return false end

    local wasInTable
    for _, v in pairs(data.Variant) do
        wasInTable = wasInTable or v == npc.Variant
    end

    return wasInTable
end

function UnlockAPI.Helper.ShouldTriggerUnlocks()
    local room = game:GetRoom()
    return (room:IsClear() and room:GetType() == RoomType.ROOM_BOSS) or level:GetStage() == LevelStage.STAGE8
end

function UnlockAPI.Helper.TriggerQueuedUnlocks()
    for requirementType in pairs(queuedUnlocks) do
        UnlockAPI.Helper.UpdateUnlocks(requirementType)
        queuedUnlocks[requirementType] = nil
    end
end

for _, bossData in pairs(UnlockAPI.Constants.REQUIREMENT_TYPE_TO_BOSS_DATA) do
    UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, UnlockAPI.Callback.MarkBossDeath, bossData.Type)
end
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, UnlockAPI.Callback.MarkBossPostUpdate)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, UnlockAPI.Callback.MarkBossPreGameExit)

--Classes
local game = Game()
local level = game:GetLevel()

--Variables
local taintedSlot

--Functions (callback)
function UnlockAPI.Callback:UnlockingTaintedPostNewRoom()
    taintedSlot = nil
    if not (level:GetCurrentRoomIndex() == UnlockAPI.Constants.TAINTED_CLOSET_GRIDINDEX and level:GetStage() == LevelStage.STAGE8 and not game:GetRoom():IsSacrificeDone()) then return end

    for _, entityPlayer in pairs(Isaac.FindByType(EntityType.ENTITY_PLAYER)) do
        local player = entityPlayer:ToPlayer()
        if not UnlockAPI.Library:IsTaintedUnlocked(player:GetName()) then
            taintedSlot = UnlockAPI.Helper.TrySpawnTaintedSlot(player)
            return
        end
    end
end

function UnlockAPI.Callback:PostUnlockingTaintedUpdate()
    if not taintedSlot then return end

    local slotSprite = taintedSlot:GetSprite()
    if not slotSprite:IsFinished() then return end

    for _, entityPlayer in pairs(Isaac.FindByType(EntityType.ENTITY_PLAYER)) do
        local player = entityPlayer:ToPlayer()
        if not UnlockAPI.Helper.IsTainted(player) and not UnlockAPI.Library:IsTaintedUnlocked(player:GetName()) then
            UnlockAPI.Helper.UpdateUnlocks(UnlockAPI.Enums.RequirementType.TAINTED, player)

            local taintedData = UnlockAPI.Helper.GetTaintedData(player:GetName())
            UnlockAPI.Helper.ShowUnlock(taintedData.AchievementGfx)

            game:GetRoom():SetSacrificeDone(true)
            break
        end
    end

    taintedSlot = nil
end

--Init
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, UnlockAPI.Callback.UnlockingTaintedPostNewRoom)
UnlockAPI.Mod:AddCallback(ModCallbacks.MC_POST_UPDATE, UnlockAPI.Callback.PostUnlockingTaintedUpdate)
---Registers a tainted character that will show a "locked" screen when selected and get unlocked through the vanilla method (Red Key room in Home)
---@param playerName                string  Name of the character that will unlock the tainted
---@param taintedPlayerName         string  Name of the tainted character (will be locked). DO NOT put "t." at the front!
---@param taintedPlayerSpritesheet  any     Path to the spritesheet of the tainted character (eg. /gfx/characters/character_001_isaac.png)
---@param achievementGfx            any     Path to the spritesheet of the unlock paper that appears when the player unlocks the tainted character. Leave nil to use the players'ars when the player unlocks the tainted character, start with !!NOPAPER!! to show text instead (ex. !!NOPAPER!!Cool Item appears!!, this will show "Cool Item appears!!")
function UnlockAPI.Library:RegisterTaintedCharacter(playerName, taintedPlayerName, taintedPlayerSpritesheet, achievementGfx)
    local normalPlayerType = Isaac.GetPlayerTypeByName(playerName, false)
    local taintedPlayerType = Isaac.GetPlayerTypeByName(taintedPlayerName, true)

    UnlockAPI.Unlocks.TaintedCharacters[taintedPlayerType] = {
        NormalPlayerType = normalPlayerType,
        NormalPlayerName = playerName,
        SlotSpritesheet = taintedPlayerSpritesheet,
        AchievementGfx = achievementGfx,
        UnlockRequirements = UnlockAPI.Enums.RequirementType.TAINTED,
    }
end

---Registers a collectible that will be locked until a player beats fulfils the requirements to unlock it
---@param playerUnlockName      string?                 Name of the character that unlocks the collectible, add "t." to the start if it is a tainted character, can be ommited for challenge unlocks
---@param collectibleType       number                  Id of collectible that will be locked
---@param unlockRequirements    RequirementType|string  Bitmask of bosses needed to be beaten for the unlock to be done, or the name of the challenge that unlocks this collectible
---@param achievementGfx        string?                 Path to the spritesheet of the unlock paper that appears when the player unlocks the collectible, start with !!NOPAPER!! to show text instead (ex. !!NOPAPER!!Cool Item appears!!, this will show "Cool Item appears!!"), make nil/false to not show anything (should be ommited for challenge unlocks) 
function UnlockAPI.Library:RegisterCollectible(playerUnlockName, collectibleType, unlockRequirements, achievementGfx)
    UnlockAPI.Unlocks.Collectibles[collectibleType] = {
        PlayerName = playerUnlockName,
        UnlockRequirements = unlockRequirements,
        AchievementGfx = achievementGfx
    }
end

---Registers a trinket that will be locked until a player beats fulfils the requirements to unlock it
---@param playerUnlockName      string?                 Name of the character that unlocks the trinket, add "t." to the start if it is a tainted character, can be ommited for challenge unlocks
---@param trinketType           number                  Id of trinket that will be locked
---@param unlockRequirements    RequirementType|string  Bitmask of bosses needed to be beaten for the unlock to be done, or the name of the challenge that unlocks this trinket
---@param achievementGfx        string?                 Path to the spritesheet of the unlock paper that appears when the player unlocks the trinket, start with !!NOPAPER!! to show text instead (ex. !!NOPAPER!!Cool Item appears!!, this will show "Cool Item appears!!"), make nil/false to not show anything (should be ommited for challenge unlocks)
function UnlockAPI.Library:RegisterTrinket(playerUnlockName, trinketType, unlockRequirements, achievementGfx)
    UnlockAPI.Unlocks.Trinkets[trinketType] = {
        PlayerName = playerUnlockName,
        UnlockRequirements = unlockRequirements,
        AchievementGfx = achievementGfx
    }
end

---Registers a card that will be locked until a player beats fulfils the requirements to unlock it
---@param playerUnlockName      string?                 Name of the character that unlocks the trinket, add "t." to the start if it is a tainted character, can be ommited for challenge unlocks
---@param cardId                number                  Id of card (not the hud one!!) that will be locked
---@param unlockRequirements    RequirementType|string  Bitmask of bosses needed to be beaten for the unlock to be done, or the name of the challenge that unlocks this card
---@param achievementGfx        string?                 Path to the spritesheet of the unlock paper that appears when the player unlocks the card, start with !!NOPAPER!! to show text instead (ex. !!NOPAPER!!Cool Item appears!!, this will show "Cool Item appears!!"), make nil/false to not show anything (should be ommited for challenge unlocks)
function UnlockAPI.Library:RegisterCard(playerUnlockName, cardId, unlockRequirements, achievementGfx)
    UnlockAPI.Unlocks.Cards[cardId] = {
        PlayerName = playerUnlockName,
        UnlockRequirements = unlockRequirements,
        AchievementGfx = achievementGfx
    }
end

---Registers an entity that will be "locked" until a player beats fulfils the requirements to unlock it
---@param playerUnlockName      string?                 Name of the character that unlocks the entity, add "t." to the start if it is a tainted character, can be ommited for challenge unlocks
---@param entityType            number                  Type of the entity to lock
---@param entityVariant         number                  Variant of the entity to lock, leave nil to lock all entities of the same variant
---@param entitySubType         number                  SubType of the entity to lock, leave nil to lock all entities of the same subtype
---@param unlockRequirements    RequirementType|string  Bitmask of requirements that are needed to be fulfiled for the unlock to be done, or the name of the challenge that unlocks this pocket item
---@param achievementGfx        string?                 Path to the spritesheet of the unlock paper that appears when the player unlocks the card, start with !!NOPAPER!! to show text instead (ex. !!NOPAPER!!Cool Item appears!!, this will show "Cool Item appears!!"), make nil/false to not show anything (should be ommited for challenge unlocks)
function UnlockAPI.Library:RegisterEntity(playerUnlockName, entityType, entityVariant, entitySubType, unlockRequirements, achievementGfx)
    table.insert(UnlockAPI.Unlocks.Entities,
    {
        Type = entityType,
        Variant = entityVariant,
        SubType = entitySubType,
        PlayerName = playerUnlockName,
        UnlockRequirements = unlockRequirements,
        AchievementGfx = achievementGfx
    })
end

---Registers a custom entry that will be locked until a player beats fulfils the requirements to unlock it
---@param playerUnlockName      string?                 Name of the character that unlocks the entity, add "t." to the start if it is a tainted character, can be ommited for challenge unlocks
---@param entryName             string                  Name of entry
---@param unlockRequirements    RequirementType|string  Bitmask of bosses needed to be beaten for the unlock to be done, or the name of the challenge that unlocks this custom entry
---@param achievementGfx        string?                 Path to the spritesheet of the unlock paper that appears when the player unlocks the entry, start with !!NOPAPER!! to show text instead (ex. !!NOPAPER!!Cool Item appears!!, this will show "Cool Item appears!!"), make nil/false to not show anything (should be ommited for challenge unlocks)
function UnlockAPI.Library:RegisterCustomEntry(playerUnlockName, entryName, unlockRequirements, achievementGfx)
    UnlockAPI.Unlocks.CustomEntry[entryName] = {
        PlayerName = playerUnlockName,
        UnlockRequirements = unlockRequirements,
        AchievementGfx = achievementGfx
    }
end

---Registers a display name for a player of a specific type. This is for characters that have the same names as others (for example Tarnished Isaac's name is still "Isaac", with this you can use "trIsaac" as the name and have seperate unlocks for him)
---@param playerName            string  Name of the character that unlocks the entity, add "t." to the start if it is a tainted character
---@param playerType            number  Type of the player
function UnlockAPI.Library:RegisterDisplayName(playerName, playerType)
    UnlockAPI.DisplayNames[playerType] = playerName
    UnlockAPI.Characters[playerName] = true
end

---Enables the tracking (and saving) of a certain player's achievements
---@param modName               string      Name of the mod (used in saving)
---@param playerName            string      Name of the character that unlocks the entity, add "t." to the start if it is a tainted character
function UnlockAPI.Library:RegisterPlayer(modName, playerName)
    UnlockAPI.Characters[playerName] = true
    UnlockAPI.ModRegistry[modName].Characters[playerName] = true

    if not PauseScreenCompletionMarksAPI then return end
    UnlockAPI.Compatibility.AddPauseScreenCompletionMarks(playerName)
end

---Registers a challenge and allows its completion to be tracked and for achievements to be locked behind it
---@param modName               string      Name of the mod (used in saving)
---@param challengeName         string      Name of the challenge (used in Isaac.GetChallengeIdByName)
---@param challengeFinalFloor   number      Final stage of the challenge, leave nil to disable
---@param achievementGfx        string?     Path to the spritesheet of the unlock paper that appears when the player finishes the challenge, start with !!NOPAPER!! to show text instead (ex. !!NOPAPER!!Cool Item appears!!, this will show "Cool Item appears!!"), make nil/false to not show anything
function UnlockAPI.Library:RegisterChallenge(modName, challengeName, challengeFinalFloor, achievementGfx)
    local challengeId = Isaac.GetChallengeIdByName(challengeName)

    UnlockAPI.Challenges[challengeId] = {
        FinalFloor = challengeFinalFloor,
        Name = challengeName,
        AchievementGfx = achievementGfx,
    }
    UnlockAPI.ModRegistry[modName].Challenges[challengeName] = true
end
local json = require("json")

---Call this before saving your own data.
---Needed to keep track of finished unlocks after quitting a run.
---Returns a table that contains all the beaten characters/challenges
function UnlockAPI.Library:GetSaveData(modName)
    local unlockData = {}

    for tableName, unlockTable in pairs(UnlockAPI.ModRegistry[modName]) do
        unlockData[tableName] = {}
        for unlockName in pairs(unlockTable) do
            unlockData[tableName][unlockName] = UnlockAPI.Save[tableName][unlockName]
        end
    end

    return unlockData
end

---Call this after loading your data (preferrably on MC_POST_GAME_STARTED). 
---Needed to keep track of finished unlocks after quitting a run.
---Loads existing unlock data
---@param saveData table UnlockAPI save Data
function UnlockAPI.Library:LoadSaveData(saveData)
    UnlockAPI.Save.Loaded = true

    if not saveData then return end

    for tableIndex, unlockTable in pairs(saveData) do
        if not UnlockAPI.Save[tableIndex] then
            UnlockAPI.Save[tableIndex] = {}
        end

        for index, value in pairs(unlockTable) do
            UnlockAPI.Save[tableIndex][index] = UnlockAPI.Save[tableIndex][index] or value
        end
    end
end
---Checks if a player has unlocked a character's tainted version or not
---@param playerName string Name of the character that the tainted version is tied to or the name of the tainted
function UnlockAPI.Library:IsTaintedUnlocked(playerName)
    local taintedData = UnlockAPI.Helper.GetTaintedData(playerName)
    return not taintedData or UnlockAPI.Helper.FulfilledAllRequirements(UnlockAPI.Enums.RequirementType.TAINTED, (UnlockAPI.Save.Characters[taintedData.NormalPlayerName] or {}))
end

---Checks if a collectible has been unlocked or not
---@param collectibleType number ID of the collectible
function UnlockAPI.Library:IsCollectibleUnlocked(collectibleType)
    local unlockData = UnlockAPI.Unlocks.Collectibles[collectibleType]
    return not unlockData or UnlockAPI.Helper.FulfilledAllRequirements(unlockData.UnlockRequirements, (UnlockAPI.Save.Characters[unlockData.PlayerName] or {}))
end

---Checks if a trinket has been unlocked or not
---@param trinketId number ID of the trinketId
function UnlockAPI.Library:IsTrinketUnlocked(trinketId)
    local unlockData = UnlockAPI.Unlocks.Trinkets[trinketId]
    return not unlockData or UnlockAPI.Helper.FulfilledAllRequirements(unlockData.UnlockRequirements, (UnlockAPI.Save.Characters[unlockData.PlayerName] or {}))
end

---Checks if a card has been unlocked or not
---@param card number ID of the card
function UnlockAPI.Library:IsCardUnlocked(card)
    local unlockData = UnlockAPI.Unlocks.Cards[card]
    return not unlockData or UnlockAPI.Helper.FulfilledAllRequirements(unlockData.UnlockRequirements, (UnlockAPI.Save.Characters[unlockData.PlayerName] or {}))
end

---Checks if an entity has been unlocked or not
---@param type number Type of the entity
---@param variant? number Variant of the entity, nil to ignore
---@param subtype? number SubType of the entity, nil to ignore
function UnlockAPI.Library:IsEntityUnlocked(type, variant, subtype)
    for _, unlockData in pairs(UnlockAPI.Unlocks.Entities) do
        if type == unlockData.Type and variant == (unlockData.Variant or variant) and subtype == (unlockData.SubType or subtype) then
            return UnlockAPI.Helper.FulfilledAllRequirements(unlockData.UnlockRequirements, (UnlockAPI.Save.Characters[unlockData.PlayerName] or {}))
        end
    end
    return true
end

---Checks if a custom entry has been unlocked or not
---@param name string Name of the custom entry
function UnlockAPI.Library:IsCustomEntryUnlocked(name)
    local unlockData = UnlockAPI.Unlocks.CustomEntry[name]
    return not not unlockData and UnlockAPI.Helper.FulfilledAllRequirements(unlockData.UnlockRequirements, (UnlockAPI.Save.Characters[unlockData.PlayerName] or {}))
end
--Function (callback)
function UnlockAPI.Callback:ExecuteUnlockAllCommand(start, cmd)
    if start ~= "unlockapi" then return end

    local unlocking, mod = UnlockAPI.Helper.GetStringAndIfUnlockingAll(cmd)
    if not mod then return end

    local consoleText = unlocking and "Unlocking" or "Locking"

    if UnlockAPI.ModRegistry[mod] then
        print(consoleText .. " all achievements of the " .. mod .. " mod.")
    elseif mod == "" then
        print(consoleText .. " all achievements of every registered mod.")
    else
        print(mod .. [[ isn't a valid mod. Please use a valid name. Names are case-sensitive. Registered mod names: ]]) 
        print(UnlockAPI.Helper.GetRegisteredModNames())
        return true
    end

    UnlockAPI.Helper.SetAllModUnlocks(UnlockAPI.ModRegistry[mod] and mod, unlocking)

    print("Done!")
    return true
end

--Function (helper)
function UnlockAPI.Helper.GetStringAndIfUnlockingAll(cmd)
    local subbedStringUnlock = cmd:gsub("unlockall", "")
    local subbedStringLock = cmd:gsub("lockall", "")

    if subbedStringUnlock ~= cmd then
        return true, subbedStringUnlock:gsub(" ", "")
    elseif subbedStringLock ~= cmd then
        return false, subbedStringLock:gsub(" ", "")
    end
end

function UnlockAPI.Helper.SetAllModUnlocks(mod, isUnlocking)
    for _, unlockData in pairs(UnlockAPI.Helper.MergeTablesInside(UnlockAPI.Unlocks, UnlockAPI.Enums.RandomPopupPreventionAchievement)) do
        local playerName = unlockData.PlayerName or unlockData.NormalPlayerName
        if not (not mod or UnlockAPI.ModRegistry[mod].Characters[playerName]) then goto continue end

        if type(unlockData.UnlockRequirements) ~= "string" then
            UnlockAPI.Helper.SetRequirements(unlockData.UnlockRequirements, playerName, isUnlocking)
        else --It's a challenge
            UnlockAPI.Save.Challenges[unlockData.UnlockRequirements] = true
        end

        ::continue::
    end
end

function UnlockAPI.Helper.GetRegisteredModNames()
    local modNames = {}
    for modName in pairs(UnlockAPI.ModRegistry) do table.insert(modNames, modName) end

    return '"' .. table.concat(modNames, ",") .. '"'
end

UnlockAPI.Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, UnlockAPI.Callback.ExecuteUnlockAllCommand)
UnlockAPI.Constants.STRING_TO_UNLOCK_TABLE = {
    collectible = "Collectibles",
    trinket = "Trinkets",
    entity = "Entities",
    card = "Cards",
    customentry = "CustomEntry",
    tainted = "TaintedCharacters",
}

--Function (callback)
function UnlockAPI.Callback:ExecuteUnlockCommand(start, cmd)
    if start ~= "unlockapi" then return end

    local unlocking, string = UnlockAPI.Helper.GetStringAndIfUnlocking(cmd)
    if not string then return end

    local unlockData = UnlockAPI.Helper.GetUnlockDataFromCommandString(string)
    if not unlockData then print("This isn't a registered achievement!") return end

    local playerName = unlockData.PlayerName or unlockData.NormalPlayerName
    local isUnlocked = UnlockAPI.Helper.FulfilledAllRequirements(unlockData.UnlockRequirements, UnlockAPI.Helper.GetPlayerUnlockData(playerName))

    if unlocking then
        if isUnlocked then print("Achievement already unlocked!") return end
        UnlockAPI.Helper.SetRequirements(unlockData.UnlockRequirements, playerName, true)
        UnlockAPI.Helper.ShowUnlock(unlockData.AchievementGfx)
    else
        if not isUnlocked then print("Achievement already locked!") return end
        UnlockAPI.Helper.SetRequirements(unlockData.UnlockRequirements, playerName, nil)
    end

    print("Done!")
    return true
end

--Function (helper)
function UnlockAPI.Helper.GetStringAndIfUnlocking(cmd)
    if cmd:find("lockall") then return end

    local subbedStringUnlock = cmd:gsub("unlock", "")
    local subbedStringLock = cmd:gsub("lock", "")

    if subbedStringUnlock ~= cmd then
        return true, subbedStringUnlock
    elseif subbedStringLock ~= cmd then
        return false, subbedStringLock
    end
end

function UnlockAPI.Helper.GetUnlockDataFromCommandString(cmdString)
    for unlockName, unlockTableName in pairs(UnlockAPI.Constants.STRING_TO_UNLOCK_TABLE) do
        local subbedString = cmdString:gsub(" " .. unlockName .. " ", "")
        if subbedString ~= cmdString then
            local unlockId = tonumber(subbedString) or subbedString
            return UnlockAPI.Unlocks[unlockTableName][unlockId]
        end
    end
end

UnlockAPI.Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, UnlockAPI.Callback.ExecuteUnlockCommand)
UnlockAPI.Constants.VALID_COMMAND_DESCS = {
    "unlock [collectible/trinket/entity/card/customentry/tainted] [id]",
    "lock [collectible/trinket/entity/card/customentry/tainted] [id]",

    "lockall [mod name, optional]",
    "unlockall [mod name, optional]",
}

--Function (callback)
function UnlockAPI.Callback:AfterInvalidCommandExecution(start, cmd)
    if not (start == "unlockapi" and cmd:gsub(" ", "") == "") then return end

    print("UnlockAPI Version: " .. UnlockAPI.Version)
    print("Commands:")

    for _, commandDesc in pairs(UnlockAPI.Constants.VALID_COMMAND_DESCS) do
        print("unlockapi", commandDesc)
    end

    return true
end

UnlockAPI.Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, UnlockAPI.Callback.AfterInvalidCommandExecution)