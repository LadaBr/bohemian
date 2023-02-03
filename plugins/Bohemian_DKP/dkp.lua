---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by brode.
--- DateTime: 07.02.2022 19:11
---

local AddonName, E = ...

Bohemian.RegisterModule(AddonName, E, function()
    E:LoadDefaults()
    E:CreateGuildFrameEditModeButtons()
    E:CreateGuildFrameDKPButton()
    E:CreateGuildFrameGuildStatusNoteColumnHeader()
    E:ReplaceGuildFrameGuildStatusNoteHeaderWithDKP()
    E:AddLFGFrameButton()
    E:AddGuildMemberColumns()
    E:AdjustDetailFrame()
    E:AdjustRaidFrame()

    E:AddConfigFrames(E.CORE:CreateModuleInterfaceConfig("DKP"))
end)
local C = E.CORE
local A = E.EVENTS

E.editModeSelected = {}
E.roster = {}
E.QUEUE = {}
E.inProcess = {}
E.blockedForDKPChange = {}

E.EVENT = {
    DKP_CHANGED = "DKP_CHANGED"
}

function E:LoadDefaults()
    if not Bohemian_DKPConfig then
        Bohemian_DKPConfig = {}
    end
    Bohemian_DKPConfig.showDKP = Bohemian_DKPConfig.showDKP == nil and true or Bohemian_DKPConfig.showDKP
    Bohemian_DKPConfig.bossRewards = Bohemian_DKPConfig.bossRewards or {}
    Bohemian_DKPConfig.selectedDifficulty = Bohemian_DKPConfig.selectedDifficulty or 1
    Bohemian_DKPConfig.startingDKP = Bohemian_DKPConfig.startingDKP or 100
end

function E:AddDKPSelected(value, channel, reason, percent)
    local names = ""
    for name, state in pairs(self.editModeSelected) do
        if state then
            names = names .. name .. ", "
            self:AddDKP(C.rosterIndex[name], value, channel, reason, percent)
        end
    end

    SendChatMessage(format("DKP added to players: %s for reason: %s", names, reason), "GUILD")
end
function E:SubtractDKPSelected(value, channel, reason, percent)
    local names = ""
    for name, state in pairs(self.editModeSelected) do
        if state then
            names = names .. name .. ", "
            self:SubtractDKP(C.rosterIndex[name], value, channel, reason, percent)
        end
    end
    SendChatMessage(format("DKP subtracted to players: %s for reason: %s", names, reason), "GUILD")
end
function E:SubtractDKP(index, value, channel, reason, percent)
    local currentValue = self:NoteDKPToNumber(select(7, GetGuildRosterInfo(index))) or 0
    self:SaveDKP(index, percent and currentValue - (currentValue * value / 100) or currentValue - value, channel, reason)
end
function E:SetDKP(index, value, channel, reason, percent)
    local currentValue = self:NoteDKPToNumber(select(7, GetGuildRosterInfo(index))) or 0
    self:SaveDKP(index, percent and currentValue * value / 100 or value, channel, reason)
end
function E:AddDKP(index, value, channel, reason, percent)
    local currentValue = self:NoteDKPToNumber(select(7, GetGuildRosterInfo(index))) or 0
    self:SaveDKP(index, percent and currentValue + (currentValue * value / 100) or currentValue + value, channel, reason)
end

function E:SetInitialDKP(playerName)
    self:SaveDKP(C.rosterIndex[playerName], Bohemian_DKPConfig.startingDKP, nil, "Initial DKP", false)
end

function E:AwardDKPRaid(value, reason)
    local members = GetNumGroupMembers();
    local realmName = GetNormalizedRealmName()
    for i = 1, members do
        local name = GetRaidRosterInfo(i)
        name, realm = UnitFullName(name)
        if not realm or #realm <= 0 then
            realm = realmName
        end
        local fullName = name .. "-" .. realm
        local guildIndex = C.rosterIndex[fullName]
        if guildIndex then
            local newValue = (self:GetCurrentDKP(fullName) or 0) + value
            self:SaveDKP(guildIndex, newValue, nil, reason)
        end
    end
    if reason then
        SendChatMessage(format("Raid received %d DKP for %s.", value, reason), "RAID")
    else
        SendChatMessage(format("Raid received %d DKP.", value), "RAID")
    end

end
function E:SaveDKP(index, value, announceChannel, reason, isLocal)
    if not CanEditPublicNote() then
        return
    end

    local fullName = GetGuildRosterInfo(index)
    local prevValue = self.roster[fullName] or 0
    if value == nil then
        GuildRosterSetPublicNote(index, "")
        return
    end
    value = C:roundWhole(value, 1)
    E:SetDKPSilent(fullName, index, value)
    if announceChannel then
        local diff = value - prevValue
        local sign = ""
        if diff > 0 then
            sign = "+"
        end
        SendChatMessage(format("%s's DKP changed to %d (%s%d) for %s", strsplit("-", fullName), value, sign, diff, reason or "no reason"), announceChannel)
    end
    E.QUEUE[#E.QUEUE + 1] = function()
        if not isLocal then
            C:OnEvent(E.EVENT.DKP_CHANGED, GetServerTime(), fullName, prevValue, value, reason or "", C:GetPlayerName(true), 0)
        end
    end
end
function E:SetDKPSilent(fullName, index, value)
    local valueStr = string.format("%05d", value)
    local note = C:GetGuildMemberNote(fullName)
    valueStr = string.find(note, "^0*%d+") and note:gsub("^0*%d+", valueStr) or valueStr
    GuildRosterSetPublicNote(index, valueStr)
    self.roster[fullName] = value
end
function E:GetCurrentDKP(fullName)
    return self.roster[fullName or C:GetPlayerName(true)] or (C.rosterIndex[fullName] and E:NoteDKPToNumber(select(7, GetGuildRosterInfo(C.rosterIndex[fullName]))) or nil)
end
function E:NoteDKPToNumber(note)
    if note == nil or note == '' then
        return
    end
    local value = tonumber(note:match("0+(%d+)"))
    if note:sub(1, 1) == "-" then
        value = value * -1
    end
    return value
end

function E:GetDKPFromEditBox(editBox)
    local text = editBox:GetText()
    local dkp, reason = strsplit(" ", text, 2)
    local percent = false
    if dkp:sub(-1) == "%" then
        dkp = dkp:sub(1, -2)
        percent = true
    end
    return tonumber(dkp), reason, percent
end

function E:SetDKPFromEditBox(editBox)
    local dkp, reason, percent = self:GetDKPFromEditBox(editBox)
    self:SetDKP(GetGuildRosterSelection(), dkp, "GUILD", reason, percent)
end
function E:AddDKPFromEditBox(editBox)
    local dkp, reason, percent = self:GetDKPFromEditBox(editBox)
    self:AddDKP(GetGuildRosterSelection(), dkp, "GUILD", reason, percent)
end
function E:SubtractDKPFromEditBox(editBox)
    local dkp, reason, percent = self:GetDKPFromEditBox(editBox)
    self:SubtractDKP(GetGuildRosterSelection(), dkp, "GUILD", reason, percent)
end

function E:AdjustRaidFrame()
    if not E.raidUILoaded or E.raidFrameAdjusted then
        return
    end
    E.raidFrameAdjusted = true
    local awardRaid = C:CreateFrame("Button", "ButtonAwardRaidDKP", RaidFrame, "UIPanelButtonTemplate")
    awardRaid:SetPoint("RIGHT", RaidFrameReadyCheckButton, "LEFT", -2, 0)
    awardRaid:SetSize(90, 21)
    awardRaid:SetText("Award DKP")
    awardRaid:SetNormalFontObject("GameFontNormalSmall")
    awardRaid:SetHighlightFontObject("GameFontHighlightSmall")
    awardRaid:SetDisabledFontObject("GameFontDisableSmall")
    awardRaid:RegisterForClicks("AnyUp")
    awardRaid:SetScript("OnClick", function()
        StaticPopup_Show("AWARD_GUILDPLAYERDKP_RAID")
    end)

    E.allAssistPoint = { RaidFrameAllAssistCheckButton:GetPoint() }

    E:UpdateAwardDKPButton()
end

function E:ProcessQueue()
    local i = #E.QUEUE
    while #E.QUEUE > 0 do
        table.remove(E.QUEUE, i)()
        i = i - 1
    end
    E:Debug("Queue processed")
end

function E:CanEditDKP()
    return CanEditPublicNote() and CanEditOfficerNote()
end

function E:SetInitialDKPDelayed(fullName)
    if not E.roster[fullName] then
        E:SetInitialDKP(fullName)
    end
end

function E:GetDifficultyBossRewards(difficulty)
    return Bohemian_DKPConfig.bossRewards[difficulty] or {}
end

function E:SetDifficultyBossRewards(difficulty, value)
    Bohemian_DKPConfig.bossRewards[difficulty] = value
end

function E:GetSelectedDifficultyBossRewards()
    return Bohemian_DKPConfig.bossRewards[Bohemian_DKPConfig.selectedDifficulty]
end

function E:SetSelectedDifficultyBossRewards(value)
    Bohemian_DKPConfig.bossRewards[Bohemian_DKPConfig.selectedDifficulty] = value
end

function E:GetCurrentBossRewards(bossName, difficulty)
    local instanceName = GetInstanceInfo()
    local config = E:GetDifficultyBossRewards(difficulty) or {}
    local defaultConfig = E:GetDifficultyBossRewards(0) or {}
    local reward = (config and config[bossName]) or (defaultConfig and defaultConfig[bossName]) or (config and config[instanceName]) or (defaultConfig and defaultConfig[instanceName])
    return reward
end