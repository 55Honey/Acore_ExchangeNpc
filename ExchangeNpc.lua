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
Config.ItemGossipOptionTextA = {}
Config.ItemGossipOptionTextB = {}
Config.SendAsOneMail = {}

Config.TurnInHonorAmount = {}
Config.GainGoldAmount = {}

Config.TokenNpcMapId = {}
Config.TokenNpcX = {}
Config.TokenNpcY = {}
Config.TokenNpcZ = {}
Config.TokenNpcO = {}
Config.MarkEntry = {}
Config.MarkCount = {}
Config.GainTokenEntry = {}
Config.Requirement = {}
Config.TokenGossipOptionText = {}

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
Config.ItemGossipOptionTextA[1] = ' of my Large Brilliant Shards and ask Chromie to send me '
Config.ItemGossipOptionTextB[1] = ' of her Lesser Planar Essence by mail.'
Config.SendAsOneMail[1] = false -- Do all sent items fit into a single stack?

Config.TurnInItemEntry[2] = 12809 --Guardian Stone
Config.TurnInItemAmount[2] = 1
Config.GainItemEntry[2] = 22452 --Primal Earth
Config.GainItemAmount[2] = 1
Config.ItemGossipOptionTextA[2] = ' of my Guardian Stone and ask Chromie to send me '
Config.ItemGossipOptionTextB[2] = ' of her Primal Earth by mail.'
Config.SendAsOneMail[2] = true  -- Do all sent items fit into a single stack?

Config.TurnInItemEntry[3] = 13468 --Black Lotus
Config.TurnInItemAmount[3] = 1
Config.GainItemEntry[3] = 22794 --Fel Lotus
Config.GainItemAmount[3] = 1
Config.ItemGossipOptionTextA[3] = ' of my Black Lotus and ask Chromie to send me '
Config.ItemGossipOptionTextB[3] = ' of her Fel Lotus by mail.'
Config.SendAsOneMail[3] = true  -- Do all sent items fit into a single stack?

Config.TurnInItemEntry[4] = 7972 --Ichor of Undeath
Config.TurnInItemAmount[4] = 1
Config.GainItemEntry[4] = 22577 --Mote of Shadow
Config.GainItemAmount[4] = 1
Config.ItemGossipOptionTextA[4] = ' of my Ichor of Undeath and ask Chromie to send me '
Config.ItemGossipOptionTextB[4] = ' of her Mote of Shadow by mail.'
Config.SendAsOneMail[4] = false  -- Do all sent items fit into a single stack?

Config.TurnInItemEntry[5] = 7069 --Elemental Air
Config.TurnInItemAmount[5] = 1
Config.GainItemEntry[5] = 22572 --Mote of Air
Config.GainItemAmount[5] = 1
Config.ItemGossipOptionTextA[5] = ' of my Elemental Air and ask Chromie to send me '
Config.ItemGossipOptionTextB[5] = ' of her Mote of Air by mail.'
Config.SendAsOneMail[5] = false  -- Do all sent items fit into a single stack?

Config.TurnInItemEntry[6] = 18512 --Larval Acid
Config.TurnInItemAmount[6] = 1
Config.GainItemEntry[6] = 21886 --Primal Life
Config.GainItemAmount[6] = 1
Config.ItemGossipOptionTextA[6] = ' of my Larval Acid and ask Chromie to send me '
Config.ItemGossipOptionTextB[6] = ' of her Primal Life by mail.'
Config.SendAsOneMail[6] = true  -- Do all sent items fit into a single stack?

Config.TurnInItemEntry[7] = 20725 --Nexus Crystal
Config.TurnInItemAmount[7] = 1
Config.GainItemEntry[7] = 22448 --Small Prismatic Shard
Config.GainItemAmount[7] = 1
Config.ItemGossipOptionTextA[7] = ' of my Nexus Crystal and ask Chromie to send me '
Config.ItemGossipOptionTextB[7] = ' of her Small Prismatic Shard by mail.'
Config.SendAsOneMail[7] = true  -- Do all sent items fit into a single stack?

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
Config.TokenNpcEntry = 1116003      -- DB entry. Must match this script's SQL for the world DB
Config.ShowAllTokens = 0            -- If 1 all token gossips are shown regardless of pre-owned Config.Requirement
Config.TokenNpcInstanceId = 0
Config.TokenGossipText = 92105

Config.TokenNpcMapId[1] = 1         -- Map where to spawn the honor exchange NPC
Config.TokenNpcX[1] = 1649.44       -- x Pos where to spawn the honor exchange NPC
Config.TokenNpcY[1] = -4221.64      -- y Pos where to spawn the honor exchange NPC
Config.TokenNpcZ[1] = 56.38         -- z Pos where to spawn the honor exchange NPC
Config.TokenNpcO[1] = 1.16          -- orientation to spawn the honor exchange NPC

Config.TokenNpcMapId[2] = 0         -- Map where to spawn the honor exchange NPC
Config.TokenNpcX[2] = -8776.29      -- x Pos where to spawn the honor exchange NPC
Config.TokenNpcY[2] = 427.62        -- y Pos where to spawn the honor exchange NPC
Config.TokenNpcZ[2] = 105.23        -- z Pos where to spawn the honor exchange NPC
Config.TokenNpcO[2] = 4.57          -- orientation to spawn the honor exchange NPC

Config.MissingTokenConditionsMessage = 'You do not meet all conditions to obtain this.'
Config.TokenExchangeSuccessfulMessage = 'Thank you! The token was added to your inventory.'
Config.TokenGossipRefundText = 'I made a mistake and want to refund a token in my inventory. I\'m aware of the caps for marks and honor and the refund will not exceed them.'

-- 1:Feet 2:Hands 3:Legs 4:Chest 5:Head 6:Shoulders 7:Weapons2h 8:Weapons1h 9:Offhand
Config.HonorPrice = { 30000, 30000, 35000, 50000, 40000, 35000, 75000, 50000, 25000 }

-- 20558 = Warsong Marks, 20559 = Arathi Marks, 20560 = Alterac Valley Marks
Config.MarkEntry[1] = { 20558, 20559, 20560 }
Config.MarkCount[1] = { 10, 10, 5 }
Config.GainTokenEntry[1] = 34858
--put either item entry the player needs to own into this. If they own any of the listed items, they may buy the next.
--this array should list the token from the previous tier and ALL armor pieces, that a player could buy with the previous token.
--if value 0, the condition is always true.
Config.Requirement[1] = 0
Config.TokenGossipOptionText[1] = 'It costs 30000 honor, 10 Warsong marks, 10 Arathi marks and 5 Alterac marks to buy a token for Boots.'

Config.MarkEntry[2] = { 20558, 20559, 20560 }
Config.MarkCount[2] = { 10, 10, 5 }
Config.GainTokenEntry[2] = 31093
Config.Requirement[2] = 0
Config.TokenGossipOptionText[2] = 'It costs 30000 honor, 10 Warsong marks, 10 Arathi marks and 5 Alterac marks to buy a token for Gloves.'

Config.MarkEntry[3] = { 20558, 20559, 20560 }
Config.MarkCount[3] = { 15, 10, 10}
Config.GainTokenEntry[3] = 31099
Config.Requirement[3] = 0
Config.TokenGossipOptionText[3] = 'It costs 35000 honor, 15 Warsong marks, 10 Arathi marks and 10 Alterac marks to buy a token for Leg Armor.'

Config.MarkEntry[4] = { 20558, 20559, 20560 }
Config.MarkCount[4] = { 10, 15, 10 }
Config.GainTokenEntry[4] = 31090
Config.Requirement[4] = 0
Config.TokenGossipOptionText[4] = 'It costs 50000 honor, 10 Warsong marks, 15 Arathi marks and 10 Alterac marks to buy a token for Chest Armor.'

Config.MarkEntry[5] = { 20558, 20559, 20560 }
Config.MarkCount[5] = { 15, 15, 10 }
Config.GainTokenEntry[5] = 31096
Config.Requirement[5] = 0
Config.TokenGossipOptionText[5] = 'It costs 40000 honor, 15 Warsong marks, 15 Arathi marks and 10 Alterac marks to buy a token for Head Armor.'

Config.MarkEntry[6] = { 20558, 20559, 20560 }
Config.MarkCount[6] = { 15, 15, 15 }
Config.GainTokenEntry[6] = 31102
Config.Requirement[6] = 0
Config.TokenGossipOptionText[6] = 'It costs 35000 honor, 15 Warsong marks, 15 Arathi marks and 15 Alterac marks to buy a token for  Shoulderpads.'

Config.MarkEntry[7] = { 20558, 20559, 20560 }
Config.MarkCount[7] = { 40, 40, 20 }
Config.GainTokenEntry[7] = 34855
Config.Requirement[7] = 0
Config.TokenGossipOptionText[7] = 'It costs 75000 honor, 40 Warsong marks, 40 Arathi marks and 20 Alterac marks to buy a token for a two-handed Weapon.'

Config.MarkEntry[8] = { 20558, 20559, 20560 }
Config.MarkCount[8] = { 25, 25, 10 }
Config.GainTokenEntry[8] = 34852
Config.Requirement[8] = 0
Config.TokenGossipOptionText[8] = 'It costs 50000 honor, 25 Warsong marks, 25 Arathi marks and 10 Alterac marks to buy a token for a one-handed Weapon.'

Config.MarkEntry[9] = { 20558, 20559, 20560 }
Config.MarkCount[9] = { 15, 15, 10 }
Config.GainTokenEntry[9] = 34853
Config.Requirement[9] = 0
Config.TokenGossipOptionText[9] = 'It costs 25000 honor, 15 Warsong marks, 15 Arathi marks and 10 Alterac marks to buy a token for an Offhand Weapon.'

------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

-- Item NPC Logic:
local function eI_BuildExchangeString( id, amount )
    return 'Take ' .. Config.TurnInItemAmount[id] * amount .. Config.ItemGossipOptionTextA[id] .. Config.GainItemAmount[id] * amount .. Config.ItemGossipOptionTextB[id]
end

local function eI_ItemOnHello(event, player, creature)
    if player == nil then return end

    local n
    for n = 1,#Config.TurnInItemEntry do
        player:GossipMenuAddItem(OPTION_ICON_CHAT, eI_BuildExchangeString( n, 1) , Config.ItemNpcEntry, n-1)
    end

    player:GossipMenuAddItem(GOSSIP_ICON_VENDOR, 'Let\'s trade', Config.ItemNpcEntry, 10000)

    player:GossipSendMenu(Config.ItemGossipText, creature, 0)
end

local function eI_ItemOnGossipSelect(event, player, object, sender, intid, code, menu_id)

    if player == nil then return end
    local GiveAmount
    local Amount
    local ExchangeId

    if intid < 1000 then
        player:GossipComplete()
        local ExchangeId = intid + 1
        player:GossipMenuAddItem( OPTION_ICON_CHAT, eI_BuildExchangeString( ExchangeId, 1 ), Config.ItemNpcEntry, intid + 1000)
        player:GossipMenuAddItem( OPTION_ICON_CHAT, eI_BuildExchangeString( ExchangeId, 5 ), Config.ItemNpcEntry, intid + 2000)
        player:GossipMenuAddItem( OPTION_ICON_CHAT, eI_BuildExchangeString( ExchangeId, 10 ), Config.ItemNpcEntry, intid + 3000 )
        player:GossipMenuAddItem( OPTION_ICON_CHAT, eI_BuildExchangeString( ExchangeId, 20 ), Config.ItemNpcEntry, intid + 4000 )
        player:GossipSendMenu( Config.ItemGossipConfirmationText, object, 0 )
    elseif intid == 10000 then
        player:SendListInventory( object )
    else
        if intid >= 4000 then
            ExchangeId = intid - 3999
            Amount = 20
            GiveAmount = Config.TurnInItemAmount[ ExchangeId ] * Amount
        elseif intid >= 3000 then
            ExchangeId = intid - 2999
            Amount = 10
            GiveAmount = Config.TurnInItemAmount[ ExchangeId ] * Amount
        elseif intid >= 2000 then
            ExchangeId = intid - 1999
            Amount = 5
            GiveAmount = Config.TurnInItemAmount[ ExchangeId ] * Amount
        else
            ExchangeId = intid - 999
            Amount = 1
            GiveAmount = Config.TurnInItemAmount[ ExchangeId ]
        end

        local playerGuid = tonumber( tostring( player:GetGUID() ) )

        if player:HasItem( Config.TurnInItemEntry[ ExchangeId ], GiveAmount, false ) then
            player:RemoveItem( Config.TurnInItemEntry[ ExchangeId ], GiveAmount )

            if Config.SendAsOneMail[ ExchangeId ] == true then
                SendMail( Config.ItemMailSubject, Config.ItemMailMessage, playerGuid, 0, 61, 5, 0, 0, Config.GainItemEntry[ ExchangeId ], GiveAmount )
            else
                for n = 1, Amount do
                    SendMail( Config.ItemMailSubject, Config.ItemMailMessage, playerGuid, 0, 61, 5, 0, 0, Config.GainItemEntry[ ExchangeId ], Config.GainItemAmount[ ExchangeId ] )
                end
            end

            player:SendBroadcastMessage( Config.ItemExchangeSuccessfulMessage )
        else
            player:SendBroadcastMessage( Config.NotEnoughItemsMessage )
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
        local ExchangeId = intid + 1
        local newintid = intid + 1000
        local HonorGossipOptionText = 'Yes! Turn in '..Config.TurnInHonorAmount[ ExchangeId ]..' honor to gain '..Config.GainGoldAmount[ ExchangeId ]..' gold.'
        player:GossipMenuAddItem(OPTION_ICON_CHAT, HonorGossipOptionText, Config.HonorNpcEntry, newintid)
        player:GossipSendMenu(Config.HonorGossipConfirmationText, object, 0)
    else
        local playerGuid = tonumber(tostring(player:GetGUID()))
        local ExchangeId = intid - 999

        local playerHonor = player:GetHonorPoints()
        if playerHonor >= Config.TurnInHonorAmount[ ExchangeId ] then
            player:SetHonorPoints( playerHonor - Config.TurnInHonorAmount[ ExchangeId ] )
            player:ModifyMoney( Config.GainGoldAmount[ ExchangeId ] * 10000 )
            player:SendBroadcastMessage( Config.HonorExchangeSuccessfulMessage )
        else
            player:SendBroadcastMessage( Config.NotEnoughHonorMessage )
        end
        player:GossipComplete()
    end
end

-- Token NPC logic:
local function eI_HasPreviousToken( player, intid )
    if Config.Requirement[intid] == 0 then
        return true
    else
        for n = 1, #Config.Requirement[intid] do
            if player:HasItem( Config.Requirement[intid][n], 1, true ) then
                return true
            end
        end
        return false
    end
end

local function eI_HasHonorAndMarksAndRequiredItems( player, intid )

    if not Config.MarkEntry[intid] then
        PrintError( 'lua-exchange-npc: Config.MarkEntry[intid] invalid in eI_HasHonorAndMarksAndRequiredItems(). intid: ' .. intid )
        return false
    end

    -- check if player has the marks they need to turn in, do not search in bank.
    for n = 1, #Config.MarkEntry[intid] do
        if not player:HasItem( Config.MarkEntry[intid][n], Config.MarkCount[intid][n], false ) then
            return false
        end
    end

    -- check if the player has enough honor
    if player:GetHonorPoints() < Config.HonorPrice[intid] then
        return false
    end

    -- check if the player owns the previous set item or the token for it. Also search in bank.
    if eI_HasPreviousToken( player, intid ) == true then
        return true
    end

    return false
end

local function RemoveTheHonorAndMarks( player, intid )
    for n = 1, #Config.MarkEntry[intid] do
        player:RemoveItem( Config.MarkEntry[intid][n], Config.MarkCount[intid][n] )
    end
    player:ModifyHonorPoints( -1 * Config.HonorPrice[intid] )
end

local function GiveTheToken( player, intid )
    local item = player:AddItem( Config.GainTokenEntry[intid], 1 )
    if item then
        return true
    else
        return false
    end
end

local function eI_TokenOnHello(event, player, creature)
    if player == nil then return end

    player:GossipMenuAddItem(OPTION_ICON_CHAT, Config.TokenGossipRefundText, Config.TokenNpcEntry, 1000)

    if not player:HasAchieved( 452 ) and not player:HasAchieved( 440 ) then
        player:SendBroadcastMessage('You need at least 10k honorable kills to buy epic PvP items.')
        player:GossipSendMenu(Config.TokenGossipText, creature, 0)
        return
    end

    local n
    for n = 1,#Config.GainTokenEntry do
        if Config.ShowAllTokens == 1 or eI_HasPreviousToken( player, n ) == true then
            player:GossipMenuAddItem(OPTION_ICON_CHAT, Config.TokenGossipOptionText[n], Config.TokenNpcEntry, n)
        end
    end

    player:GossipSendMenu(Config.TokenGossipText, creature, 0)
end

local function eI_TokenOnGossipSelect( event, player, object, sender, intid, code, menu_id )

    if not player then
        PrintError('lua-exchange-npc: player object invalid in eI_TokenOnGossipSelect')
        return
    end

    if intid == 1000 then
        for n = 1,#Config.GainTokenEntry do
            if player:HasItem( Config.GainTokenEntry[n], 1, false ) then
                player:RemoveItem( Config.GainTokenEntry[n], 1 )
                player:ModifyHonorPoints( Config.HonorPrice[n] )
                for m = 1, #Config.MarkEntry[n] do
                    player:AddItem( Config.MarkEntry[n][m], Config.MarkCount[n][m] )
                end
                player:GossipComplete()
                return
            end
        end
        return
    end

    if intid > 6 and not player:HasAchieved( 439 ) and not player:HasAchieved( 451 ) then
        player:SendBroadcastMessage( 'You need at least 20k honorable kills to buy epic PvP weapons.' )
        return
    end

    if eI_HasHonorAndMarksAndRequiredItems( player, intid ) then
        if GiveTheToken( player, intid ) then
            RemoveTheHonorAndMarks( player, intid )
        else
            player:SendBroadcastMessage( 'You need at least one empty slot in your inventory.' )
        end
    else
        player:SendBroadcastMessage( Config.MissingTokenConditionsMessage )
    end
    player:GossipComplete()
end

------------------------------------------------------------------------------------------------

local function eI_CloseLua(eI_CloseLua)
    if npcItemObjectGuid ~= nil then
        local map
        map = GetMapById(Config.ItemNpcMapId)
        if map then
            local npcItemObject = map:GetWorldObject(npcItemObjectGuid)
            if npcItemObject ~= nil then
                npcItemObject:DespawnOrUnsummon(0)
            end
        end
    end

    if npcHonorObjectGuid ~= nil then
        local map
        map = GetMapById(Config.HonorNpcMapId)
        if map then
            local npcHonorObject = map:GetWorldObject(npcHonorObjectGuid)
            if npcHonorObject then
                npcHonorObject:DespawnOrUnsummon(0)
            end
        end
    end

    if npcTokenObjectGuid[1] ~= nil then
        for n = 1, #Config.TokenNpcMapId do
            map = GetMapById(Config.TokenNpcMapId[n])
            if map then
                local npcTokenObject = map:GetWorldObject(npcTokenObjectGuid[n])
                if npcTokenObject then
                    npcTokenObject:DespawnOrUnsummon(0)
                end
            end
        end
    end
end

--Startup:
npcItemObjectGuid = nil
npcHonorObjectGuid = nil
npcTokenObjectGuid = {}

if Config.ItemNpcOn == 1 then
    npcItemObject = PerformIngameSpawn(1, Config.ItemNpcEntry, Config.ItemNpcMapId, Config.ItemNpcInstanceId, Config.ItemNpcX, Config.ItemNpcY, Config.ItemNpcZ, Config.ItemNpcO)
    npcItemObjectGuid = npcItemObject:GetGUID()
    if npcItemObject then
        npcItemObject:CastSpell(npcItemObject,65712,true)
        npcItemObject:CastSpell(npcItemObject,48200,true)
    end


    RegisterCreatureGossipEvent(Config.ItemNpcEntry, GOSSIP_EVENT_ON_HELLO, eI_ItemOnHello)
    RegisterCreatureGossipEvent(Config.ItemNpcEntry, GOSSIP_EVENT_ON_SELECT, eI_ItemOnGossipSelect)
end

if Config.HonorNpcOn == 1 then
    npcHonorObject = PerformIngameSpawn(1, Config.HonorNpcEntry, Config.HonorNpcMapId, Config.HonorNpcInstanceId, Config.HonorNpcX, Config.HonorNpcY, Config.HonorNpcZ, Config.HonorNpcO)
    npcHonorObjectGuid = npcHonorObject:GetGUID()
    if npcHonorObject then
        npcHonorObject:CastSpell(npcItemObject,65712,true)
    end

    RegisterCreatureGossipEvent(Config.HonorNpcEntry, GOSSIP_EVENT_ON_HELLO, eI_HonorOnHello)
    RegisterCreatureGossipEvent(Config.HonorNpcEntry, GOSSIP_EVENT_ON_SELECT, eI_HonorOnGossipSelect)
end

if Config.TokenNpcOn == 1 then
    for n = 1, #Config.TokenNpcMapId do
        local npcTokenObject = PerformIngameSpawn(1, Config.TokenNpcEntry, Config.TokenNpcMapId[n], Config.TokenNpcInstanceId, Config.TokenNpcX[n], Config.TokenNpcY[n], Config.TokenNpcZ[n], Config.TokenNpcO[n])
        npcTokenObjectGuid[n] = npcTokenObject:GetGUID()
    end

    RegisterCreatureGossipEvent(Config.TokenNpcEntry, GOSSIP_EVENT_ON_HELLO, eI_TokenOnHello)
    RegisterCreatureGossipEvent(Config.TokenNpcEntry, GOSSIP_EVENT_ON_SELECT, eI_TokenOnGossipSelect)
end

if Config.HonorNpcOn == 1 or Config.ItemNpcOn == 1 or Config.TokenNpcOn == 1 then
    eventIdCloseEluna = RegisterServerEvent(ELUNA_EVENT_ON_LUA_STATE_CLOSE, eI_CloseLua, 0)
end
