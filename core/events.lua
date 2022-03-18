---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by brode.
--- DateTime: 07.02.2022 17:39
---
---
local _, E = ...
local A = E.EVENTS
E.IsInitialized = false
E.QUEUE = {}
E.INIT_DELAY = 1

function A:ADDON_LOADED(name)
    if not self.IsInitialized then
        local requiredAddon = self.REQUIRED_ADDONS[name]
        if requiredAddon ~= nil then
            self:Debug('Required addon', name, 'loaded')
            self.REQUIRED_ADDONS[name] = true
        end
        local requiredAddonsLoaded = true
        for _, v in pairs(self.REQUIRED_ADDONS) do
            if not v then
                requiredAddonsLoaded = false
            end
        end
        if requiredAddonsLoaded then
            self.IsInitialized = true
            self:Debug("All dependencies loaded. Initializing...");
            local success = C_ChatInfo.RegisterAddonMessagePrefix(self.NAME)
            if success then
                self:Load()
            else
                self:Error("Failed to register messaging event!")
            end
        end
    end
end

function A:READY()
    E:UpdateModuleControlItems()
    local gum = E:GetGuildMaster()[1]
    if E:IsPlayerOnline(gum) then
        E:SendPriorityEventTo(gum, "REQUIRED_MODULES_REQUEST")
    else
        E:SendPriorityEvent("GUILD", "REQUIRED_MODULES_REQUEST")
    end
    C_Timer.After(E.INIT_DELAY, function()
        E:Init()
    end)
end

function A:ONLINE_CHECK(sender)
    if sender == E:GetPlayerName(true) then
        return
    end
    E:SendEventTo(sender, E.EVENT.ONLINE_CHECK_RESPONSE, E.onlineSince, BohemianConfig.lastTimeOnline or 0)
end

function A:ONLINE_CHECK_RESPONSE(time, lastTimeOnline, sender)
    if sender == E:GetPlayerName(true) then
        return
    end
    E.onlineChecks[sender] = { name = sender, onlineSince = tonumber(time), lastTimeOnline = tonumber(lastTimeOnline) or 0 }
end

function A:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix ~= E.NAME then
        return
    end
    local event, args
    if message:sub(1, 1) == E.COMPRESSED_SEPARATOR then
        event = E.EVENT.STREAM_DATA
        args = { message, channel, sender }
    else
        event, args = E:ProcessEvent(message, channel, sender)
    end
    if event and args then
        E:OnEvent(event, unpack(args))
    end
end

function A:GUILD_ROSTER_UPDATE(...)
    local members, onlineMembers, _ = GetNumGuildMembers();
    if members > 0 and E.firstLoad then
        E:CacheGuildRoster()
        E:GuildStatus_UpdateHook()
    end
    BohemianConfig.showOffline = GetGuildRosterShowOffline();
    E.lastOnlineMembers = onlineMembers
end

function A:GUILD_MEMBER_COUNT_CHANGED(offline, online)
    for player, _ in pairs(online) do
        E:SendEventTo(player.name, E.EVENT.ONLINE_CHECK)
        E:RequestVersionInfoFrom(player.name)
    end
    for player, _ in pairs(offline) do
        E.onlineChecks[player] = nil
    end
end

function A:PLAYER_ENTERING_WORLD(isLogin, isReload)
    E:Debug("PLAYER_ENTERING_WORLD", isLogin, isReload)
    if not isLogin and not isReload then
        return
    end
    GuildRoster()
    if IsInGuild() then
        E:LoadDataWhenReady()
    end
end

function A:PLAYER_LOGOUT()
    BohemianConfig.lastTimeOnline = GetServerTime()
end

function A:WHISPER(event, target, ...)
    if target ~= E:GetPlayerName(true) then
        return
    end
    E:OnEvent(event, ...)
end

function A:VERSION_INFO(version, sender)
    BohemianConfig.versions[sender] = version
    E:Debug(sender, "has version", version)
    E:VersionCheck()
    if E.syncDone then
        E:UpdateVersions()
    end
end

function A:STREAM_DATA(message, channel, sender)
    local _, name = strsplit(E.EVENT_SEPARATOR, message:sub(2), 3)
    local id, order, msg
    if name == E:GetPlayerName(true) then
        id, name, order, msg = strsplit(E.EVENT_SEPARATOR, message:sub(2), 4)
    else
        id, order, msg = strsplit(E.EVENT_SEPARATOR, message:sub(2), 3)
    end
    local chunks = E.chunks[id]
    if not chunks then
        return
    end
    chunks.received = chunks.received + 1
    order = tonumber(order)
    if not order then
        return
    end
    chunks.data[order] = msg
    -- E:Debug("Saved chunk", order, id, chunks.type, chunks.received.."/"..chunks.size, sender)
    if chunks.size == chunks.received then
        E.chunks[id] = nil
        E:Debug("Processing chunks", id, chunks.type, sender)
        if not chunks.data then
            return
        end
        local payload = table.concat(table.removeNil(chunks.data))
        local data = E:ProcessPayload(payload)
        E:Debug("Processed chunks", id, chunks.type, sender)
        if not data then
            return
        end

        data = E:split(data, "\n")
        E:Debug("Executing chunks", id, chunks.type, sender)
        for _, itemStr in ipairs(data) do
            local event, args = E:ProcessEvent(itemStr, channel, sender)
            E:OnEvent(event, unpack(args))
        end
        E:OnEvent("PAYLOAD_PROCESSED", chunks.type, id, sender)
    end
end

function A:PAYLOAD_START(payloadType, chunkAmount, remoteId, sender)
    local id = E:uuid()
    E:CreatePayload(payloadType, chunkAmount, id, sender)
    E:Debug("Prepared chunked payload with id", id, "|| size:", chunkAmount)
    E:SendEventTo(sender, E.EVENT.PAYLOAD_START_CONFIRM, remoteId, id)
end

function A:BROADCAST_START(payloadType, chunkAmount, remoteId, sender)
    E:CreatePayload(payloadType, chunkAmount, remoteId, sender)
    E:Debug("Prepared broadcast with id", remoteId, "|| size:", chunkAmount)
end

function A:PAYLOAD_START_CONFIRM(id, remoteId, sender)
    local chunks = E.chunksToSend[id]
    if not chunks then
        return
    end
    local sep = E.COMPRESSED_SEPARATOR .. remoteId .. E.EVENT_SEPARATOR .. sender

    for i, chunk in ipairs(chunks) do
        local sep2 = E.EVENT_SEPARATOR .. i
        E:SendAddonMessage(sep .. sep2 .. E.EVENT_SEPARATOR .. chunk, "GUILD")
    end
    E.chunksToSend[id] = nil
end

function A:GUILD_FRAME_UPDATE()
    E:UpdateColumnAfterUpdate()
    E:RenderLFGButtons()
    E:UpdateGMOTDState()
end

function A:GUILD_FRAME_AFTER_UPDATE()
    --print(GuildFrameColumnHeader2:GetWidth())

    E:SetGuildStatusColumnWidth()
    E:RenderGuildColumnHeadersAll()
    E:RenderGuildFrame()
    E:FixToggleButton()
    E:UpdateDetailFrame()
    --print(GuildFrame:GetWidth())
end

function A:VERSION_INFO_REQUEST(sender)
    if sender == E:GetPlayerName(true) then
        return
    end
    E:ShareVersionInfoTo(sender)
end

function A:SYNC_DONE()
    E:RequestVersionInfo()
    E:ShareVersionInfo()
    C_Timer.After(5, function()
        E:UpdateVersions()
    end)
    E.syncDone = true
end

function A:MODULE_LOADED(module)
    local _, name = strsplit("_", module.NAME)
    E:AddModuleControlItem(module.NAME, name or _)
end

function A:REQUIRED_MODULES_REQUEST(sender)
    E:SendRequiredModules(sender)
end

E.missingModules = {}
function A:REQUIRED_MODULES(modules, lastUpdate, sender)
    if sender == E:GetPlayerName(true) then
        return
    end
    lastUpdate = tonumber(lastUpdate)
    if BohemianConfig.requiredModulesLastUpdate and BohemianConfig.requiredModulesLastUpdate > lastUpdate then
        return
    end
    modules = { strsplit(",", modules) }
    if #modules > 0 then
        BohemianConfig.requiredModulesLastUpdate = lastUpdate
    end
    for _, module in ipairs(modules) do
        if not E:GetModule(module) and not E.missingModules[module] then
            E:Print(E:colorize("Missing required module ", E.COLOR.RED)..module)
            E.missingModules[module] = true
            BohemianConfig.requiredModules[module] = true
        end
    end
    for _, _ in pairs(E.missingModules) do
        E.disabled = true
        E:Print("You have to enable all required modules in order to use this addon!")
        break
    end
    E:UpdateModuleControlItems()
    E:Init()
end

function A:UPDATE_GUILD_MEMBER(row, _, _, fullName)
    if not E.guildRosterVersions then
        return
    end
    local version = _G["GuildFrameGuildStatusButton" .. row .. "Version"]
    local versionText = _G["GuildFrameGuildStatusButton" .. row .. "VersionText"]
    if E.guildRosterVersions.missing[fullName] then
        versionText:SetTextColor(1.0, 0.0, 0.0)
        version:Show()
        version.tooltip = nil
    elseif E.guildRosterVersions.old[fullName] then
        versionText:SetTextColor(1, 0.82, 0)
        version:Show()
        version.tooltip = E.guildRosterVersions.old[fullName]
    elseif E.guildRosterVersions.current[fullName] then
        versionText:SetTextColor(0, 1, 0)
        version:Show()
        version.tooltip = E.guildRosterVersions.current[fullName]
    else
        version:Hide()
        version.tooltip = nil
    end

end
