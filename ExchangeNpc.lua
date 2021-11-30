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
--               -  adjust the Config.NpcEntry in case of conflicts and run the associated SQL to add the required NPC
------------------------------------------------------------------------------------------------
-- GM GUIDE:     -  nothing to do
------------------------------------------------------------------------------------------------
local Config = {}                       --general config flags

Config.TurnInItemEntry = {}
Config.TurnInItemAmount = {}
Config.GainItemEntry = {}
Config.GainItemAmount = {}
Config.GossipOptionText = {}

local GOSSIP_EVENT_ON_HELLO = 1             -- (event, player, object) - Object is the Creature/GameObject/Item. Can return false to do default action. For item gossip can return false to stop spell casting.
local GOSSIP_EVENT_ON_SELECT = 2            -- (event, player, object, sender, intid, code, menu_id)
local OPTION_ICON_CHAT = 0

local ELUNA_EVENT_ON_LUA_STATE_CLOSE = 16

local eventIdCloseEluna
local eventIdHello
local eventIdStart

------------------------------------------------------------------------------------------------

Config.NpcEntry = 1116001    -- DB entry. Must match this script's SQL for the world DB
Config.InstanceId = 0
Config.MapId = 1             --
Config.NpcX = 22
Config.NpcY = 33
Config.NpcZ = 44
Config.NpcO = 55

Config.GossipText = 'Hello Time Traveler! Chromie has ordered me to provide you with proper tools on your journey, if you can show evidence of being worthy.'
Config.NotEnoughItemsMessage = 'You do not have the required items at hand.'
Config.ExchangeSuccessfulMessage = 'Thank you! The exchange will be sent to you in a mail by my assistans as soon as possible.'
Config.mailSubject = 'Item Exchange'
Config.mailMessage = 'Greetings, Time Traveler! Here you are the requested substitutes for the provided items.'

Config.TurnInItemEntry[1] = 20725 --Nexus Crystal
Config.TurnInItemAmount[1] = 4
Config.GainItemEntry[1] = 22448 --Small Prismatic Shard
Config.GainItemAmount[1] = 3
Config.GossipOptionText[1] = 'Exchange 4 of item 20725 against 3 of item 22448'

Config.TurnInItemEntry[2] = 16203 --Greater Eternal Essence
Config.TurnInItemAmount[2] = 5
Config.GainItemEntry[2] = 20731 --Greater Planar Essence
Config.GainItemAmount[2] = 1
Config.GossipOptionText[2] = 'Exchange 5 of item 16203 against 1 of item 20731.'

Config.TurnInItemEntry[3] = 7082 --Essence of Air
Config.TurnInItemAmount[3] = 1
Config.GainItemEntry[3] = 22451 --Primal Air
Config.GainItemAmount[3] = 5
Config.GossipOptionText[3] = 'Exchange 1 of item 7082 against 5 of item 22451.'

Config.TurnInItemEntry[4] = 7076 --Essence of Earth
Config.TurnInItemAmount[4] = 1
Config.GainItemEntry[4] = 22452 --Primal Earth
Config.GainItemAmount[4] = 1
Config.GossipOptionText[4] = 'Exchange 1 of item 7076 against 1 of item 22452.'

Config.TurnInItemEntry[5] = 13468 --Black Lotus
Config.TurnInItemAmount[5] = 1
Config.GainItemEntry[5] = 22794 --Fel Lotus
Config.GainItemAmount[5] = 1
Config.GossipOptionText[5] = 'Exchange 1 of item 13468 against 1 of item 22794.'


------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

local function eI_onHello(event, player, creature)
    if player == nil then return end

    local n
    for n = 1,#TurnInItemEntry do
        player:GossipMenuAddItem(OPTION_ICON_CHAT, "Config.GossipOptionText[n]", Config.NpcEntry, n-1)
    end

    player:GossipSendMenu(Config.GossipText, creature, 0)
end

local function eI_onGossipSelect(event, player, object, sender, intid, code, menu_id)
    if player == nil then return end

    local exchangeId = intid - 1
    local playerGuid = player:GetGuidLow()
    if player:HasItem(Config.TurnInItemEntry[exchangeId], Config.TurnInItemAmount[exchangeId], false) then
        player:RemoveItem(Config.TurnInItemEntry[exchangeId], Config.TurnInItemAmount[exchangeId])
	SendMail(Config.mailSubject, Config.mailMessage, playerGuid, 0, 61, 5, 0, 0, Config.GainItemEntry[exchangeId], Config.GainItemAmount[exchangeId])
        player:SendBroadcastMessage(Config.ExchangeSuccessfulMessage)
    else
        player:SendBroadcastMessage(Config.NotEnoughItemsMessage)
    end
    player:GossipComplete()
end

local function eI_CloseLua(eI_CloseLua)
    print('(eI_CloseLua) has fired.')
    NpcObject:DespawnOrUnsummon(0)
end

--Startup:
local NpcObject
NpcObject = PerformIngameSpawn(1, Config.NpcEntry, Config.MapId, Config.InstanceId, Config.NpcX, Config.NpcY, Config.NpcZ, Config.NpcO)

eventIdCloseEluna = RegisterServerEventELUNA_EVENT_ON_LUA_STATE_CLOSE, eI_CloseLua, 0)
eventIdHello = RegisterCreatureGossipEvent(Config.NpcEntry, GOSSIP_EVENT_ON_HELLO, eI_onHello)
eventIdStart = RegisterCreatureGossipEvent(Config.NpcEntry, GOSSIP_EVENT_ON_SELECT, eI_onGossipSelect)
