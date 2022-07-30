--
--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 22/11/2021
-- Time: 08:50
-- To change this template use File | Settings | File Templates.
-- Originally created by Honey for Azerothcore
-- requires ElunaLua module


-- This script spawns a NPC which allows for custom item exchanges.
------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with ElunaLua module
--               -  adjust config in this file
--               -  add this script to ../lua_scripts/
--               -  adjust the Config.ItemNpcEntry in case of conflicts and run the associated SQL to add the required NPC
------------------------------------------------------------------------------------------------
-- GM GUIDE:     -  nothing to do
------------------------------------------------------------------------------------------------
local Config = {}                       --general config flags

Config.TurnInItemEntry = {}
Config.TurnInItemAmount = {}
Config.GainItemEntry = {}
Config.GainItemAmount = {}
Config.ItemGossipOptionText = {}

Config.TurnInHonorAmount = {}
Config.GainGoldAmount = {}

Config.MarkEntry = {}
Config.MarkCount = {}
Config.GainTokenEntry = {}
Config.Requirement = {}

local GOSSIP_EVENT_ON_HELLO = 1             -- (event, player, object) - Object is the Creature/GameObject/Item. Can return false to do default action. For item gossip can return false to stop spell casting.
local GOSSIP_EVENT_ON_SELECT = 2            -- (event, player, object, sender, intid, code, menu_id)
local OPTION_ICON_CHAT = 0
local GOSSIP_ICON_VENDOR = 1

local ELUNA_EVENT_ON_LUA_STATE_CLOSE = 16

local eventIdCloseEluna

local npcItemObject
local npcItemObjectGuid
local npcHonorObjectGuid
local npcTokenObjectGuid

Config.ItemNpcOn = 1            -- spawns an NPC to turn in items for other items
Config.HonorNpcOn = 1           -- spawns an NPC to trade honor vs gold
Config.TokenNpcOn = 1           -- spawns an NPC to trade multiple items for tokens

------------------------------------------------------------------------------------------------
-- Item Exchange NPC
------------------------------------------------------------------------------------------------
Config.ItemNpcEntry = 1116001   -- DB entry. Must match this script's SQL for the world DB
Config.ItemNpcInstanceId = 0
Config.ItemNpcMapId = 1         -- Map where to spawn the item exchange NPC
Config.ItemNpcX = -7153         -- x Pos where to spawn the item exchange NPC
Config.ItemNpcY = -3740         -- y Pos where to spawn the item exchange NPC
Config.ItemNpcZ = 8.4           -- z Pos where to spawn the item exchange NPC
Config.ItemNpcO = 5.06          -- orientation to spawn the item exchange NPC

Config.ItemGossipText = 92101
Config.ItemGossipConfirmationText = 92102
Config.NotEnoughItemsMessage = 'You do not have the required items at hand.'
Config.ItemExchangeSuccessfulMessage = 'Thank you! The exchange will be sent to you in a mail by my assistants as soon as possible.'
Config.ItemMailSubject = 'Item Exchange'
Config.ItemMailMessage = 'Greetings, Time Traveler! Here you are the requested substitutes for the provided items.'

Config.TurnInItemEntry[1] = 14344 --Large Brilliant Shard
Config.TurnInItemAmount[1] = 1
Config.GainItemEntry[1] = 22447 --Lesser Planar Essence
Config.GainItemAmount[1] = 1
Config.ItemGossipOptionText[1] = 'Take 1 of my Large Brilliant Shards and ask Chromie to send me 1 of her Lesser Planar Essence by mail.'

Config.TurnInItemEntry[2] = 12809 --Guardian Stone
Config.TurnInItemAmount[2] = 1
Config.GainItemEntry[2] = 22452 --Primal Earth
Config.GainItemAmount[2] = 1
Config.ItemGossipOptionText[2] = 'Take 1 of my Guardian Stone and ask Chromie to send me 1 of her Primal Earth by mail.'

Config.TurnInItemEntry[3] = 13468 --Black Lotus
Config.TurnInItemAmount[3] = 1
Config.GainItemEntry[3] = 22794 --Fel Lotus
Config.GainItemAmount[3] = 1
Config.ItemGossipOptionText[3] = 'Take 1 of my Black Lotus and ask Chromie to send me 1 of her Fel Lotus by mail.'

Config.TurnInItemEntry[4] = 7972 --Ichor of Undeath
Config.TurnInItemAmount[4] = 1
Config.GainItemEntry[4] = 22577 --Mote of Shadow
Config.GainItemAmount[4] = 1
Config.ItemGossipOptionText[4] = 'Take 1 of my Ichor of Undeath and ask Chromie to send me 1 of her Mote of Shadow by mail.'

Config.TurnInItemEntry[5] = 7069 --Elemental Air
Config.TurnInItemAmount[5] = 1
Config.GainItemEntry[5] = 22572 --Mote of Air
Config.GainItemAmount[5] = 1
Config.ItemGossipOptionText[5] = 'Take 1 of my Elemental Air and ask Chromie to send me 1 of her Mote of Air by mail.'

Config.TurnInItemEntry[6] = 18512 --Larval Acid
Config.TurnInItemAmount[6] = 1
Config.GainItemEntry[6] = 21886 --Primal Life
Config.GainItemAmount[6] = 1
Config.ItemGossipOptionText[6] = 'Take 1 of my Larval Acid and ask Chromie to send me 1 of her Primal Life by mail.'

-- Config.TurnInItemEntry[7] = 20725 --Nexus Crystal
-- Config.TurnInItemAmount[7] = 1
-- Config.GainItemEntry[7] = 22448 --Small Prismatic Shard
-- Config.GainItemAmount[7] = 1
-- Config.ItemGossipOptionText[7] = 'Take 1 of my Nexus Crystal and ask Chromie to send me 1 of her Small Prismatic Shard by mail.'

------------------------------------------------------------------------------------------------
-- Honor Exchange NPC
------------------------------------------------------------------------------------------------
Config.HonorNpcEntry = 1116002   -- DB entry. Must match this script's SQL for the world DB
Config.HonorNpcInstanceId = 0
Config.HonorNpcMapId = 0         -- Map where to spawn the honor exchange NPC
Config.HonorNpcX = -14288.9      -- x Pos where to spawn the honor exchange NPC
Config.HonorNpcY = 533.9         -- y Pos where to spawn the honor exchange NPC
Config.HonorNpcZ = 8.8           -- z Pos where to spawn the honor exchange NPC
Config.HonorNpcO = 3.64          -- orientation to spawn the honor exchange NPC

Config.HonorGossipText = 92103
Config.HonorGossipConfirmationText = 92104
Config.NotEnoughHonorMessage = 'You do not have the required amount of Honor.'
Config.HonorExchangeSuccessfulMessage = 'Thank you! Your Honor was converted to Gold.'

Config.TurnInHonorAmount[1] = 1000      -- Amount of Honor per turn in
Config.GainGoldAmount[1] = 1            -- Gain Gold amount per turn in
Config.TurnInHonorAmount[2] = 5000      -- Amount of Honor per turn in
Config.GainGoldAmount[2] = 5            -- Gain Gold amount per turn in
Config.TurnInHonorAmount[3] = 10000     -- Amount of Honor per turn in
Config.GainGoldAmount[3] = 10           -- Gain Gold amount per turn in
Config.TurnInHonorAmount[4] = 50000     -- Amount of Honor per turn in
Config.GainGoldAmount[4] = 50           -- Gain Gold amount per turn in

------------------------------------------------------------------------------------------------
-- Token Exchange NPC
------------------------------------------------------------------------------------------------
Config.TokenNpcEntry = 1116003   -- DB entry. Must match this script's SQL for the world DB
Config.TokenNpcInstanceId = 0
-- todo: needs new position
Config.TokenNpcMapId = 0         -- Map where to spawn the honor exchange NPC
Config.TokenNpcX = -14288.9      -- x Pos where to spawn the honor exchange NPC
Config.TokenNpcY = 531.9         -- y Pos where to spawn the honor exchange NPC
Config.TokenNpcZ = 8.8           -- z Pos where to spawn the honor exchange NPC
Config.TokenNpcO = 3.64          -- orientation to spawn the honor exchange NPC

Config.MissingTokenConditionsMessage = 'You do not meet all conditions to obtain this.'
Config.TokenExchangeSuccessfulMessage = 'Thank you! The token was added to your inventory.'

-- 1: Gloves 2:Boots 3:Shoulders 4:Pants 5:Helmet 6:Chest 7:Weapons2h 8:Weapons1h 9:Offhand
Config.HonorPrice = { 30000, 30000, 35000, 35000, 40000, 50000, 75000, 50000, 25000 }

-- 20558 = Warsong Marks, 20559 = Arathi Marks, 20560 = Alterac Valley Marks
Config.MarkEntry[1] = { 20558, 20559, 20560 }
Config.MarkCount[1] = { 10, 3, 1 }
Config.GainTokenEntry[1] = 31093
--put either item entry the player needs to own into this. If they own any of the listed items, they may buy the next. Empty for [1] cause no prerequesites.
--this array should list the token from the previous tier and ALL armor pieces, that a player could buy with the previous token
Config.Requirement[1] = {}

--todo: Config.Requirement[n] needs lists of ALL items per slot

Config.MarkEntry[2] = { 20558, 20559, 20560 }
Config.MarkCount[2] = { 10, 3, 1 }
Config.GainTokenEntry[2] = 34858
Config.Requirement[2] = {31093}

Config.MarkEntry[3] = { 20558, 20559, 20560 }
Config.MarkCount[3] = { 10, 3, 1 }
Config.GainTokenEntry[3] = 31102
Config.Requirement[3] = {34858}

Config.MarkEntry[4] = { 20558, 20559, 20560 }
Config.MarkCount[4] = { 10, 3, 1 }
Config.GainTokenEntry[4] = 31099
Config.Requirement[4] = {31102}

Config.MarkEntry[5] = { 20558, 20559, 20560 }
Config.MarkCount[5] = { 10, 3, 1 }
Config.GainTokenEntry[5] = 31096
Config.Requirement[5] = {31099}

Config.MarkEntry[6] = { 20558, 20559, 20560 }
Config.MarkCount[6] = { 10, 3, 1 }
Config.GainTokenEntry[6] = 31090
Config.Requirement[6] = {31096}

Config.MarkEntry[7] = { 20558, 20559, 20560 }
Config.MarkCount[7] = { 10, 3, 1 }
Config.GainTokenEntry[7] = 34855
Config.Requirement[7] = {31090}

Config.MarkEntry[8] = { 20558, 20559, 20560 }
Config.MarkCount[8] = { 10, 3, 1 }
Config.GainTokenEntry[8] = 34852
Config.Requirement[8] = {31090}

Config.MarkEntry[9] = { 20558, 20559, 20560 }
Config.MarkCount[9] = { 10, 3, 1 }
Config.GainTokenEntry[9] = 34853
Config.Requirement[9] = {31090}

------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

-- Item NPC Logic:
local function eI_ItemOnHello(event, player, creature)
    if player == nil then return end

    local n
    for n = 1,#Config.TurnInItemEntry do
        player:GossipMenuAddItem(OPTION_ICON_CHAT, Config.ItemGossipOptionText[n], Config.ItemNpcEntry, n-1)
    end

    player:GossipMenuAddItem(GOSSIP_ICON_VENDOR, 'Let\'s trade', Config.ItemNpcEntry, 10000)

    player:GossipSendMenu(Config.ItemGossipText, creature, 0)
end

local function eI_ItemOnGossipSelect(event, player, object, sender, intid, code, menu_id)

    if player == nil then return end

    if intid < 1000 then
        player:GossipComplete()
        local exchangeId = intid + 1
        local newintid = intid + 1000
        player:GossipMenuAddItem(OPTION_ICON_CHAT, 'Yes! '..Config.ItemGossipOptionText[exchangeId], Config.ItemNpcEntry, newintid)
        player:GossipSendMenu(Config.ItemGossipConfirmationText, object, 0)
    elseif intid == 10000 then
        player:SendListInventory(object)
    else
        local playerGuid = tonumber(tostring(player:GetGUID()))
        local exchangeId = intid - 999
        if player:HasItem(Config.TurnInItemEntry[exchangeId], Config.TurnInItemAmount[exchangeId], false) then
            player:RemoveItem(Config.TurnInItemEntry[exchangeId], Config.TurnInItemAmount[exchangeId])
            SendMail(Config.ItemMailSubject, Config.ItemMailMessage, playerGuid, 0, 61, 5, 0, 0, Config.GainItemEntry[exchangeId], Config.GainItemAmount[exchangeId])
            player:SendBroadcastMessage(Config.ItemExchangeSuccessfulMessage)
        else
            player:SendBroadcastMessage(Config.NotEnoughItemsMessage)
        end
        player:GossipComplete()
    end
end

-- Honor NPC Logic:
local function eI_HonorOnHello(event, player, creature)
    if player == nil then return end

    local n
    for n = 1,#Config.TurnInHonorAmount do
        local HonorGossipOptionText = 'Turn in '..Config.TurnInHonorAmount[n]..' honor to gain '..Config.GainGoldAmount[n]..' gold.'
        player:GossipMenuAddItem(OPTION_ICON_CHAT, HonorGossipOptionText, Config.HonorNpcEntry, n-1)
    end

    player:GossipSendMenu(Config.HonorGossipText, creature, 0)
end

local function eI_HonorOnGossipSelect(event, player, object, sender, intid, code, menu_id)

    if player == nil then return end

    if intid < 1000 then
        player:GossipComplete()
        local exchangeId = intid + 1
        local newintid = intid + 1000
        local HonorGossipOptionText = 'Yes! Turn in '..Config.TurnInHonorAmount[exchangeId]..' honor to gain '..Config.GainGoldAmount[exchangeId]..' gold.'
        player:GossipMenuAddItem(OPTION_ICON_CHAT, HonorGossipOptionText, Config.HonorNpcEntry, newintid)
        player:GossipSendMenu(Config.HonorGossipConfirmationText, object, 0)
    else
        local playerGuid = tonumber(tostring(player:GetGUID()))
        local exchangeId = intid - 999

        local playerHonor = player:GetHonorPoints()
        if playerHonor >= Config.TurnInHonorAmount[exchangeId] then
            player:SetHonorPoints(playerHonor - Config.TurnInHonorAmount[exchangeId])
            player:ModifyMoney(Config.GainGoldAmount[exchangeId] * 10000)
            player:SendBroadcastMessage(Config.HonorExchangeSuccessfulMessage)
        else
            player:SendBroadcastMessage(Config.NotEnoughHonorMessage)
        end
        player:GossipComplete()
    end
end

-- Token NPC logic:
local function eI_HasHonorAndMarksAndRequiredItems( player, intid )

    -- check if player has the marks they need to turn in, do not seach in bank.
    for n = 1, #Config.MarkEntry[intid] do
        if not player:HasItem( Config.MarkEntry[intid][n], Config.MarkCount[intid][n], false ) then
            return false
        end
    end

    -- check if the player has enough honor
    if not player:GetHonorPoints() >= Config.HonorPrice[intid] then
        return false
    end

    -- check if the player owns the previous set item or the token for it. Also search in bank.
    for n = 1, #Config.Requirement[intid] do
        if player:HasItem( Config.Requirement[intid][n], 1, true ) then
            return true
        end
    end

    return false
end

local function RemoveTheHonorAndMarks( player, intid )
    for n = 1, #Config.MarkEntry do
        player:RemoveItem( Config.MarkEntry[intid][n], itemCount )
    end
    player:ModifyHonorPoints( Config.HonorPrice[intid] )
end

local function GiveTheToken( player, intid )
    player:AddItem( Config.GainTokenEntry[intid], 1 )
end

local function eI_TokenOnGossipSelect( event, player, object, sender, intid, code, menu_id )
    if HasHonorAndMarksAndRequiredItems( player, intid ) then
        RemoveTheHonorAndMarks( intid )
        GiveTheToken( intid )
    else
        player:SendBroadcastMessage(Config.MissingTokenConditionsMessage)
    end
end

------------------------------------------------------------------------------------------------

local function eI_CloseLua(eI_CloseLua)
    if npcItemObjectGuid ~= nil then
        local map
        map = GetMapById(Config.ItemNpcMapId)
        local npcItemObject = map:GetWorldObject(npcItemObjectGuid)
        npcItemObject:DespawnOrUnsummon(0)
    end

    if npcHonorObjectGuid ~= nil then
        local map
        map = GetMapById(Config.HonorNpcMapId)
        local npcHonorObject = map:GetWorldObject(npcHonorObjectGuid)
        npcHonorObject:DespawnOrUnsummon(0)
    end

    if npcTokenObjectGuid ~= nil then
        map = GetMapById(Config.TokenNpcMapId)
        local npcTokenObject = map:GetWorldObject(npcTokenObjectGuid)
        npcTokenObject:DespawnOrUnsummon(0)
    end
end

--Startup:
npcItemObjectGuid = nil
npcHonorObjectGuid = nil
npcTokenObjectGuid = nil

if Config.ItemNpcOn == 1 then
    npcItemObject = PerformIngameSpawn(1, Config.ItemNpcEntry, Config.ItemNpcMapId, Config.ItemNpcInstanceId, Config.ItemNpcX, Config.ItemNpcY, Config.ItemNpcZ, Config.ItemNpcO)
    npcItemObjectGuid = npcItemObject:GetGUID()

    RegisterCreatureGossipEvent(Config.ItemNpcEntry, GOSSIP_EVENT_ON_HELLO, eI_ItemOnHello)
    RegisterCreatureGossipEvent(Config.ItemNpcEntry, GOSSIP_EVENT_ON_SELECT, eI_ItemOnGossipSelect)
end

if Config.HonorNpcOn == 1 then
    npcHonorObject = PerformIngameSpawn(1, Config.HonorNpcEntry, Config.HonorNpcMapId, Config.HonorNpcInstanceId, Config.HonorNpcX, Config.HonorNpcY, Config.HonorNpcZ, Config.HonorNpcO)
    npcHonorObjectGuid = npcHonorObject:GetGUID()
    npcHonorObject:CastSpell(npcItemObject,15473,true)

    RegisterCreatureGossipEvent(Config.HonorNpcEntry, GOSSIP_EVENT_ON_HELLO, eI_HonorOnHello)
    RegisterCreatureGossipEvent(Config.HonorNpcEntry, GOSSIP_EVENT_ON_SELECT, eI_HonorOnGossipSelect)
end

if Config.TokenNpcOn == 1 then
    npcTokenObject = PerformIngameSpawn(1, Config.TokenNpcEntry, Config.TokenNpcMapId, Config.TokenNpcInstanceId, Config.TokenNpcX, Config.TokenNpcY, Config.TokenNpcZ, Config.TokenNpcO)
    npcTokenObjectGuid = npcTokenObject:GetGUID()
    npcTokenObject:CastSpell(npcItemObject,15473,true)

    RegisterCreatureGossipEvent(Config.TokenNpcEntry, GOSSIP_EVENT_ON_SELECT, eI_TokenOnGossipSelect)
end

if Config.HonorNpcOn == 1 or Config.ItemNpcOn == 1 or Config.TokenNpcOn == 1 then
    eventIdCloseEluna = RegisterServerEvent(ELUNA_EVENT_ON_LUA_STATE_CLOSE, eI_CloseLua, 0)
end
