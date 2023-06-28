local mod = RegisterMod("Gray Isaac", 1)
local json = require("json")

--Some constants
local GRAYISAAC_A_PLAYERTYPE = Isaac.GetPlayerTypeByName("Gray Isaac", false)
local GRAYISAAC_B_PLAYERTYPE = Isaac.GetPlayerTypeByName("Gray Isaac", true)

local GRAY_BREAKFAST_ITEMID = Isaac.GetItemIdByName("Gray Breakfast")
local GRAY_D6_ITEMID = Isaac.GetItemIdByName("Gray D6")
local GRAY_YUMHEART_ITEMID = Isaac.GetItemIdByName("Gray Yum Heart")

local COINS_BEAT_MOMSHEART = 99

local GRAY_REDEMPTION_CHALLENGEID = Isaac.GetChallengeIdByName("Gray Redemption")

include("unlockapi")

--I'd be nice if you put all these in a different file, just for organisation's sake
UnlockAPI.Library:RegisterPlayer("GrayIsaac", "Gray Isaac")
UnlockAPI.Library:RegisterPlayer("GrayIsaac", "t.Gray Isaac") --The mod will now keep track of the character's completion marks

UnlockAPI.Library:RegisterTaintedCharacter("Gray Isaac", "Gray Isaac", "gfx/characters/costumes/character_001b_isaac_grey.png", "!!NOPAPER!!Unlocked tainted Gray Isaac") --I don't have an achievement paper I'm sorry

UnlockAPI.Library:RegisterChallenge("GrayIsaac", "Gray Redemption", LevelStage.STAGE3_2, "!!NOPAPER!!Unlocked Gray Yum Heart")

UnlockAPI.Library:RegisterCollectible("Gray Isaac", GRAY_D6_ITEMID, UnlockAPI.Enums.RequirementType.MOMSFOOT, "!!NOPAPER!!Unlocked Gray D6")  --Locks it only behind Mom
UnlockAPI.Library:RegisterCollectible("t.Gray Isaac", GRAY_BREAKFAST_ITEMID, UnlockAPI.Enums.RequirementType.MOMSFOOT | UnlockAPI.Enums.RequirementType.HUSH, "!!NOPAPER!!Unlocked Gray Breakfast") --Locks it behind Hush & Mom
UnlockAPI.Library:RegisterCollectible("Challenge", GRAY_YUMHEART_ITEMID, "Gray Redemption")

--Let's assume normal code starts here
--Gray Isaac code
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
    if player:HasCurseMistEffect() or player.FrameCount > 0 then return end

    local playerType = player:GetPlayerType()
    if playerType == GRAYISAAC_A_PLAYERTYPE and UnlockAPI.Library:IsCollectibleUnlocked(GRAY_D6_ITEMID) and not player:HasCollectible(GRAY_D6_ITEMID) then
        player:SetPocketActiveItem(GRAY_D6_ITEMID, ActiveSlot.SLOT_POCKET, true)
    elseif playerType == GRAYISAAC_B_PLAYERTYPE and UnlockAPI.Library:IsCollectibleUnlocked(GRAY_BREAKFAST_ITEMID) and not player:HasCollectible(GRAY_BREAKFAST_ITEMID) then
        player:AddCollectible(GRAY_BREAKFAST_ITEMID)
    end
end)

mod:AddCallback(UnlockAPI.Enums.ModCallbacksCustom.MC_BEAT_REQUIREMENT, function(_, player, requirementType)
    local playerType = player:GetPlayerType()
    if playerType ~= GRAYISAAC_A_PLAYERTYPE and playerType ~= GRAYISAAC_B_PLAYERTYPE then return end

    player:AddCoins(COINS_BEAT_MOMSHEART)
end, UnlockAPI.Enums.RequirementType.MOMSHEART)

--Gray Redemption code
mod:AddCallback(UnlockAPI.Enums.ModCallbacksCustom.MC_PRE_CHANGE_HELD_COLLECTIBLE, function()
    return Isaac.GetChallenge() == GRAY_REDEMPTION_CHALLENGEID
end, GRAY_YUMHEART_ITEMID) --This makes it so gray yum heart doesn't get rerolled in the challenge

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
    if isContinued or Isaac.GetChallenge() ~= GRAY_REDEMPTION_CHALLENGEID then return end

    for _, entityPlayer in pairs(Isaac.FindByType(EntityType.ENTITY_PLAYER)) do
        local player = entityPlayer:ToPlayer()
        player:ChangePlayerType(GRAYISAAC_A_PLAYERTYPE)
        player:SetPocketActiveItem(GRAY_YUMHEART_ITEMID, ActiveSlot.SLOT_POCKET, true)
    end
end)

--Save manager (This is important, TRY TO UNDERSTAND HOW IT WORKS WITH UNLOCKAPI, NOT COPY IT)
local function LoadData(_, isContinue)
    local savedata = {}
    if mod:HasData() then
        savedata = json.decode(mod:LoadData())
    else
        savedata = {}
    end

    if not isContinue then
        mod.Save = {}
    else
        mod.Save = savedata.Save
    end
    UnlockAPI.Library:LoadSaveData(savedata.UnlockData)
end

local function SaveData()
    if Isaac.GetPlayer().FrameCount == 0 then return end
    local savedata = {}
    savedata.Save = mod.Save
    savedata.UnlockData = UnlockAPI.Library:GetSaveData("GrayIsaac")
    mod:SaveData(json.encode(savedata))
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, LoadData)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SaveData)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, SaveData)