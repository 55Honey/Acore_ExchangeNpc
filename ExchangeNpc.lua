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

local GOSSIP_EVENT_ON_HELLO = 1             -- (event, player, object) - Object is the Creature/GameObject/Item. Can return false to do default action. For item gossip can return false to stop spell casting.
local GOSSIP_EVENT_ON_SELECT = 2            -- (event, player, object, sender, intid, code, menu_id)
local OPTION_ICON_CHAT = 0

local ELUNA_EVENT_ON_LUA_STATE_CLOSE = 16

local eventIdCloseEluna

local npcItemObject
local npcItemObjectGuid
local npcHonorObject
local npcHonorObjectGuid

Config.ItemNpcOn = 1            -- spawns an NPC to turn in items for other items
Config.HonorNpcOn = 1           -- spawns an NPC to trade honor vs gold

------------------------------------------------------------------------------------------------
-- Item Exchange NPC
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

Config.TurnInItemEntry[1] = 20725 --Nexus Crystal
Config.TurnInItemAmount[1] = 1
Config.GainItemEntry[1] = 22448 --Small Prismatic Shard
Config.GainItemAmount[1] = 1
Config.ItemGossipOptionText[1] = 'Take 1 of my Nexus Crystal and ask Chromie to send me 1 of her Small Prismatic Shard by mail.'

Config.TurnInItemEntry[2] = 14344 --Large Brilliant Shard
Config.TurnInItemAmount[2] = 1
Config.GainItemEntry[2] = 22447 --Lesser Planar Essence
Config.GainItemAmount[2] = 1
Config.ItemGossipOptionText[2] = 'Take 1 of my Large Brilliant Shards and ask Chromie to send me 1 of her Lesser Planar Essence by mail.'

Config.TurnInItemEntry[3] = 12809 --Guardian Stone
Config.TurnInItemAmount[3] = 1
Config.GainItemEntry[3] = 22452 --Primal Earth
Config.GainItemAmount[3] = 1
Config.ItemGossipOptionText[3] = 'Take 1 of my Guardian Stone and ask Chromie to send me 1 of her Primal Earth by mail.'

Config.TurnInItemEntry[4] = 13468 --Black Lotus
Config.TurnInItemAmount[4] = 1
Config.GainItemEntry[4] = 22794 --Fel Lotus
Config.GainItemAmount[4] = 1
Config.ItemGossipOptionText[4] = 'Take 1 of my Black Lotus and ask Chromie to send me 1 of her Fel Lotus by mail.'

Config.TurnInItemEntry[5] = 7972 --Ichor of Undeath
Config.TurnInItemAmount[5] = 1
Config.GainItemEntry[5] = 22577 --Mote of Shadow
Config.GainItemAmount[5] = 1
Config.ItemGossipOptionText[5] = 'Take 1 of my Ichor of Undeath and ask Chromie to send me 1 of her Mote of Shadow by mail.'

Config.TurnInItemEntry[6] = 7069 --Elemental Air
Config.TurnInItemAmount[6] = 1
Config.GainItemEntry[6] = 22572 --Mote of Air
Config.GainItemAmount[6] = 1
Config.ItemGossipOptionText[6] = 'Take 1 of my Elemental Air and ask Chromie to send me 1 of her Mote of Air by mail.'

Config.TurnInItemEntry[7] = 18512 --Larval Acid
Config.TurnInItemAmount[7] = 1
Config.GainItemEntry[7] = 21886 --Primal Life
Config.GainItemAmount[7] = 1
Config.ItemGossipOptionText[7] = 'Take 1 of my Larval Acid and ask Chromie to send me 1 of her Primal Life by mail.'

------------------------------------------------------------------------------------------------
-- Honor Exchange NPC
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

------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

--Item NPC Logic:
local function eI_ItemOnHello(event, player, creature)
    if player == nil then return end

    local n
    for n = 1,#Config.TurnInItemEntry do
        player:GossipMenuAddItem(OPTION_ICON_CHAT, Config.ItemGossipOptionText[n], Config.ItemNpcEntry, n-1)
    end

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

local function eI_CloseLua(eI_CloseLua)
    if npcItemObjectGuid ~= nil then
        local map
        map = GetMapById(Config.ItemNpcMapId)
        npcItemObject = map:GetWorldObject(npcItemObjectGuid):ToCreature()
        npcItemObject:DespawnOrUnsummon(0)
    end
    if npcHonorObjectGuid ~= nil then
        local map
        map = GetMapById(Config.HonorNpcMapId)
        npcHonorObject = map:GetWorldObject(npcHonorObjectGuid):ToCreature()
        npcHonorObject:DespawnOrUnsummon(0)
    end
end

--Startup:
npcItemObjectGuid = nil
npcHonorObjectGuid = nil
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

if Config.HonorNpcOn == 1 or Config.ItemNpcOn == 1 then
    eventIdCloseEluna = RegisterServerEvent(ELUNA_EVENT_ON_LUA_STATE_CLOSE, eI_CloseLua, 0)
end
