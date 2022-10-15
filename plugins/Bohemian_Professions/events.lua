---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by brode.
--- DateTime: 07.02.2022 23:20
---

local _, E = ...
local A = E.EVENTS
local C = E.CORE

E.CORE:RegisterEvent('CRAFT_UPDATE')
E.CORE:RegisterEvent('TRADE_SKILL_UPDATE')
E.CORE:RegisterEvent('CHAT_MSG_WHISPER')

function A:CHAT_MSG_SKILL()
    if IsInGuild() then
        E:ShareProfessions()
    end
end

function A:READY()
    E:RequestProfessionInfo()
end

function A:PROFESSION_INFO_REQUEST(sender)
    E:ShareProfessions(sender)
end

function A:CRAFT2(profId, skillId, craftTypeId, numAvailable, cooldown, reagents, id, minMade, maxMade, icon, time, sender)
    if not reagents or not sender then
        return
    end
    local guildName = C:GetGuildName()
    local reagents_t = {}
    profId = tonumber(profId)

    local profName;
    for name, id in pairs(E.PROFESSION_IDS) do
        if profId == id then
            profName = name
            break
        end
    end
    if not profName then
        return
    end
    local hasProfession = false
    for _, profession in ipairs(E:GetPlayerProfessions(sender)) do
        if (profession.name == profName) then
            hasProfession = true
            break
        end
    end
    if not hasProfession then
        return
    end
    skillId = tonumber(skillId)
    craftTypeId = tonumber(craftTypeId)
    icon = tonumber(icon)
    time = tonumber(time)
    reagents = { strsplit("*", reagents) }
    for _, reagent in pairs(reagents) do
        local reagentCount, playerReagentCount, reagentId = strsplit("~", reagent)
        reagentId = tonumber(reagentId)
        if not reagentId then
            return
        end
        local item = Item:CreateFromItemID(reagentId)

        item:ContinueOnItemLoad(function()
            local icon = item:GetItemIcon()
            local link = item:GetItemLink()
            table.insert(reagents_t, {
                count = tonumber(reagentCount),
                playerCount = tonumber(playerReagentCount),
                id = tonumber(reagentId),
                link = link,
                texture = icon
            })
        end)

    end

    local spell = Spell:CreateFromSpellID(skillId)

    spell:ContinueOnSpellLoad(function()
        local name = spell:GetSpellName()
        local desc = spell:GetSpellDescription()
        local link = GetSpellLink(spell:GetSpellID())
        if not Crafts[guildName] then
            Crafts[guildName] = {}
        end
        if not Crafts[guildName][sender] then
            Crafts[guildName][sender] = {}
        end
        if not Crafts[guildName][sender][profName] then
            Crafts[guildName][sender][profName] = {}
        end
        Crafts[guildName][sender][profName][name] = {
            available = tonumber(numAvailable),
            profId = profId,
            skillId = skillId,
            icon = icon,
            desc = desc,
            type = craftTypeId,
            cooldown = tonumber(cooldown),
            reagents = reagents_t,
            link = link,
            id = tonumber(id),
            min = tonumber(minMade),
            max = tonumber(maxMade),
            time = time
        }

    end)


end

function A:PROFESSION_INFO(payload, sender)
    local spellIds = { strsplit(",", payload) }
    if sender then
        local tmp = {}
        for _, v in ipairs(spellIds) do
            local spellId, spellRank, spellMaxRank = strsplit("-", v)
            spellId = tonumber(spellId)
            spellRank = tonumber(spellRank)
            spellMaxRank = tonumber(spellMaxRank)
            local name, _, icon = GetSpellInfo(spellId)
            local order = E.PROFESSIONS[name]
            if order then
                table.insert(tmp, { name = name, order = order, id = spellId, icon = icon, rank = spellRank, maxRank = spellMaxRank })
            end
        end
        table.sort(tmp, function(a, b)
            return a.order < b.order
        end)
        Professions[sender] = tmp
        E:CheckPlayerProfessionHistoryValidity(sender)
    end
end

function A:CRAFT_UPDATE(...)
    local linked = IsTradeSkillLinked()
    if linked then
        return
    end
    E:ShareCraftsDelayed()
end

function A:TRADE_SKILL_UPDATE(...)
    local linked = IsTradeSkillLinked()
    if linked then
        return
    end
    E:ShareTradeSkillsDelayed()
end

function A:GUILD_FRAME_UPDATE()
    if FriendsFrame.playerStatusFrame then
        C:SwapColumnBetween("GuildFrameColumnHeader6", C.GuildStatusHeaderOrder, C.GuildHeaderOrder)
    else
        C:SwapColumnBetween("GuildFrameColumnHeader6", C.GuildHeaderOrder, C.GuildStatusHeaderOrder)
    end
    E:UpdateDetailFrame()
end

function A:UPDATE_GUILD_MEMBER(i, _, numMembers, fullName)
    local professions
    if i <= numMembers then
        professions = self:GetPlayerProfessions(fullName)
    else
        professions = {}
    end
    E:RenderProfessions("GuildFrameButton" .. i .. "ProfessionFrame%dProf", fullName, professions)
end

function A:GUILD_MEMBER_COUNT_CHANGED(_, online)
    if not E:CanSync() then
        return
    end
    for player, _ in pairs(online) do
        E:RequestProfessionInfoFrom(player)
    end
end

E.onlineSince = {}
function A:SYNC_DONE()
    E:RequestPlayersProfessionInfoHistory()
    --C:SendEvent("GUILD", "CRAFT_HISTORY_CHECK")
    --C_Timer.After(5, function()
    --    local players = C:ProcessPlayersForSync(E.onlineSince)
    --    E.onlineSince = {}
    --    table.sort(players, function(a, b)
    --        return a.onlineSince < b.onlineSince
    --    end)
    --    if #players > 0 then
    --        C:SendEventTo(players[1].name, "CRAFT_HISTORY_REQUEST")
    --    end
    --    --for _, player in ipairs(players) do
    --    --    -- TODO DATE
    --    --    C:SendEventTo(player.name, "CRAFT_HISTORY_REQUEST")
    --    --end
    --end)
end

function A:CRAFT_HISTORY_CHECK(sender)
    if sender == C:GetPlayerName(true) then
        return
    end
    if E:CanSync() then
        C:SendEventTo(sender, "CRAFT_HISTORY_CHECK_RESPONSE", C.onlineSince)
    end
end

function A:CRAFT_HISTORY_CHECK_RESPONSE(since, sender)
    E.onlineSince[sender] = { onlineSince = tonumber(since), name = sender }
end

--function A:PAYLOAD_PROCESSED(type, _, sender)
--    if type == "CRAFTS" then
--        local chunks = C:GetPlayerChunks(name, type)
--        if #chunks == 0 then
--            --E.waitingForPlayers[sender] = nil
--            --E:Debug("Synced crafts from", sender)
--            --Bohemian_LogConfig.playersSyncList[sender] = GetServerTime()
--            --if not E:IsWaitingForPlayers() and not E.initialized then
--            --    E:Debug("Log was synced to latest version")
--            --    E:FinishLogSync()
--            --end
--        end
--    end
--end

function A:CHAT_MSG_GUILD(message)
    local guildName = C:GetGuildName()
    --if C:GetPlayerName(true) == "Elerae-Golemagg" then
    --    local patterns = {
    --        "umi.*%[(.+)%]",
    --        "umí.*%[(.+)%]",
    --        "umi.* (%a+).*$",
    --        "umí.* (%a+).*$",
    --    }
    --    for _, pattern in ipairs(patterns) do
    --        local itemName = string.match(message, pattern)
    --        if itemName then
    --            local players = {}
    --            local playersOnline = {}
    --            for playerName, _ in pairs(E:FilterCraftPlayers(itemName)) do
    --                if not C:IsPlayerOnline(playerName) then
    --                    players[#players + 1] = strsplit("-", playerName)
    --                else
    --                    playersOnline[#playersOnline + 1] = strsplit("-", playerName)
    --                end
    --            end
    --            if #players + #playersOnline > 0 then
    --                local msg = "Joo."
    --                if #playersOnline == 0 then
    --                    msg = msg.." Bohužel nikdo z nich není online."
    --                else
    --                    msg = msg.." Z těch online třeba "..table.concat(table.slice(playersOnline, 1, 5), ", ").."."
    --                end
    --
    --                if #players > 0 then
    --                    if #playersOnline == 0 then
    --                        msg = msg.." Z těch offline třeba "..table.concat(table.slice(players, 1, 5), ", ").."."
    --                    else
    --                        msg = msg.." Jinak " .. table.concat(table.slice(players, 1, 5),", ") .. "."
    --                    end
    --                end
    --
    --                SendChatMessage(msg, "GUILD")
    --            end
    --            return
    --        end
    --    end
    --    if string.find(strlower(message), "kdo je aos") then
    --        SendChatMessage("Je to Borec!", "GUILD")
    --    end
    --    if string.find(strlower(message), "kdo je ixide") then
    --        SendChatMessage("Marek Sajrajt", "GUILD")
    --    end
    --    if strlower(message) == "!hack" then
    --        local tmp = {
    --            [3] = "Spouštím hackovací sekvenci...",
    --            [7] = "Detekuji OS...",
    --            [9] = "Detekováno: Windows",
    --            [10] = "Zahajuji přenos kódu mimo prostředí Wow.exe",
    --            [15] = "Přenos úspěšně dokončen.",
    --            [16] = "Procházím systémové soubory...",
    --            [26] = "Systémové klíče objeveny!",
    --            [26] = "Přístup odepřen.",
    --            [27] = "Opakuji...",
    --            [31] = "Přístup odepřen.",
    --            [32] = "Opakuji...",
    --            [46] = "Přístup povolen.",
    --            [48] = "Spouštím proces miner.exe",
    --        }
    --        for time, text in pairs(tmp) do
    --            C_Timer.After(time, function()
    --                SendChatMessage(text, "GUILD")
    --            end)
    --        end
    --    end
    --    if string.find(strlower(message), "kdo je niarkas") then
    --        SendChatMessage("Týpek, co neuměl točit, tak šel radši tankovat. KEKW", "GUILD")
    --    end
    --end
end

function A:PLAYER_ENTERING_WORLD(isLogin, isReload)
    E.isLogin = isLogin
    E.isReload = isReload
end

function A:CACHED_GUILD_DATA()

    if not E.onlyOnce then
        E.onlyOnce = true
        --E:CleanUpOldMembers(function(oldMember)
        --    E:GetGuildCrafts()[oldMember] = nil
        --end)
    end

end

function A:CRAFT_HISTORY_REQUEST(playerName, lastSync, sender)
    if sender == C:GetPlayerName(true) then
        return
    end
    lastSync = tonumber(lastSync)

    local unsyncCrafts = E:GetPlayerCraftsSince(playerName, lastSync)
    if #unsyncCrafts > 0 then
        E:SharePlayerCraftHistory(unsyncCrafts, sender)
    end

end

function A:CRAFT_HISTORY_SYNC_FINISHED(playerName, syncTime)
    syncTime = tonumber(syncTime)
    if not CraftsSyncTime[playerName] or CraftsSyncTime[playerName] < syncTime then
        CraftsSyncTime[playerName] = syncTime
    end
end