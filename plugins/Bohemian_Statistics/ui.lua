---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by brode.
--- DateTime: 09.02.2022 15:52
---
local _, E = ...

local C = E.CORE


function E:CreateStatisticsFrame()
    local statisticsFrame = C:CreateFrame("Frame", "$parentStatisticsFrame", GuildFrame)
    statisticsFrame:SetSize(300, 200)
    statisticsFrame:SetPoint("TOPLEFT", 0, 0)
    local sortFn = function(self)
        Bohemian_Statistics.desc = Bohemian_Statistics.sortType == self.sortType and (not Bohemian_Statistics.desc) or false
        Bohemian_Statistics.sortType = self.sortType
        E:SortMembers()
        E:UpdateStatisticRows()
    end
    local nameHeader = C:CreateFrame("BUTTON", "$parentNameHeader", statisticsFrame, "GuildFrameColumnHeaderTemplate")
    nameHeader:SetPoint("TOPLEFT", statisticsFrame, 7, -57)
    nameHeader:SetText("Name")
    nameHeader:SetScript("OnClick", sortFn)
    WhoFrameColumn_SetWidth(nameHeader, 83);
    nameHeader.sortType = "name";

    local achievementHeader = C:CreateFrame("BUTTON", "$parentAchievementHeader", statisticsFrame, "GuildFrameColumnHeaderTemplate")
    achievementHeader:SetPoint("LEFT", nameHeader, "RIGHT", -2, 0)
    achievementHeader:SetScript("OnClick", sortFn)
    WhoFrameColumn_SetWidth(achievementHeader, 60);
    local achievementHeaderTexture = achievementHeader:CreateTexture("$parentTexture", "ARTWORK")
    achievementHeaderTexture:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Progressive-Shield-NoPoints")
    achievementHeaderTexture:SetPoint("CENTER", 8, -6)
    achievementHeaderTexture:SetSize(40, 40)
    achievementHeader.sortType = "achievement";

    local hkHeader = C:CreateFrame("BUTTON", "$parentHkHeader", statisticsFrame, "GuildFrameColumnHeaderTemplate")
    hkHeader:SetPoint("LEFT", achievementHeader, "RIGHT", -2, 0)
    hkHeader:SetText("HK")
    hkHeader:SetScript("OnClick", sortFn)
    local hkHeaderTexture = hkHeader:CreateTexture("$parentIconTexture", "BACKGROUND")
    local faction = UnitFactionGroup("player")
    hkHeaderTexture:SetTexture("Interface\\PVPFrame\\PVP-Currency-" .. faction)
    hkHeaderTexture:SetPoint("RIGHT", hkHeader, -5, -2)
    hkHeaderTexture:SetSize(20,20)
    WhoFrameColumn_SetWidth(hkHeader, 60);
    hkHeader.sortType = "hk";

    local arena2v2Header = C:CreateFrame("BUTTON", "$parentArena2v2Header", statisticsFrame, "GuildFrameColumnHeaderTemplate")
    arena2v2Header:SetPoint("LEFT", hkHeader, "RIGHT", -2, 0)
    arena2v2Header:SetText("2v2")
    WhoFrameColumn_SetWidth(arena2v2Header, 60);
    arena2v2Header.sortType = "arena2v2";
    arena2v2Header:SetScript("OnClick", sortFn)
    local arena2v2HeaderTexture = arena2v2Header:CreateTexture("$parentIconTexture", "BACKGROUND")
    arena2v2HeaderTexture:SetTexture("Interface\\PVPFrame\\Icon-Combat")
    arena2v2HeaderTexture:SetPoint("RIGHT", arena2v2Header, -5, 0)


    local arena3v3Header = C:CreateFrame("BUTTON", "$parentArena3v3Header", statisticsFrame, "GuildFrameColumnHeaderTemplate")
    arena3v3Header:SetPoint("LEFT", arena2v2Header, "RIGHT", -2, 0)
    arena3v3Header:SetText("3v3")
    arena3v3Header:SetScript("OnClick", sortFn)
    local arena3v3HeaderTexture = arena3v3Header:CreateTexture("$parentTexture", "BACKGROUND")
    arena3v3HeaderTexture:SetTexture("Interface\\PVPFrame\\Icon-Combat")
    arena3v3HeaderTexture:SetPoint("RIGHT", -5, 0)
    WhoFrameColumn_SetWidth(arena3v3Header, 60);
    arena3v3Header.sortType = "arena3v3";

    local arena5v5Header = C:CreateFrame("BUTTON", "$parentArena5v5Header", statisticsFrame, "GuildFrameColumnHeaderTemplate")
    arena5v5Header:SetPoint("LEFT", arena3v3Header, "RIGHT", -2, 0)
    arena5v5Header:SetText("5v5")
    arena5v5Header:SetScript("OnClick", sortFn)
    local arena5v5HeaderTexture = arena5v5Header:CreateTexture("$parentTexture", "BACKGROUND")
    arena5v5HeaderTexture:SetTexture("Interface\\PVPFrame\\Icon-Combat")
    arena5v5HeaderTexture:SetPoint("RIGHT", -5, 0)
    WhoFrameColumn_SetWidth(arena5v5Header, 60);
    arena5v5Header.sortType = "arena5v5";

    local module = C:GetModule("Bohemian_Reputation")
    if module then
        local repHeader = C:CreateFrame("BUTTON", "$parentRepHeader", statisticsFrame, "GuildFrameColumnHeaderTemplate")
        repHeader:SetPoint("LEFT", arena5v5Header, "RIGHT", -2, 0)
        repHeader:SetScript("OnClick", sortFn)
        local repHeaderTexture = repHeader:CreateTexture("$parentTexture", "BORDER")
        repHeaderTexture:SetTexture("Interface\\ICONS\\achievement_reputation_01")
        repHeaderTexture:SetPoint("CENTER", 0, -2)
        repHeaderTexture:SetScale(0.25);
        WhoFrameColumn_SetWidth(repHeader, 30);
        repHeader.sortType = "rep";
    end


    for i = 1, GUILDMEMBERS_TO_DISPLAY do
        local statisticsRow = C:CreateFrame("BUTTON", "$parentRow"..i, statisticsFrame)
        statisticsRow:SetSize(406, 16)
        local highlight = statisticsRow:CreateTexture("$parentHighlight", "ARTWORK")
        highlight:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
        highlight:SetPoint("TOPLEFT", 5, -2)
        highlight:SetSize(406,16)
        statisticsRow:SetHighlightTexture(highlight)
        if i == 1 then
            statisticsRow:SetPoint("TOPLEFT", GuildFrame, 3, -82)
        else
            statisticsRow:SetPoint("TOPLEFT", _G["GuildFrameStatisticsFrameRow"..(i - 1)], "BOTTOMLEFT", 0, 0)
        end
        statisticsRow.id = i

        local nameCol = statisticsRow:CreateFontString("$parentName", "BORDER", "GameFontNormalSmall")
        nameCol:SetJustifyH("LEFT")
        nameCol:SetSize(60, 14)
        nameCol:SetPoint("TOPLEFT", 12, -3)

        local achievementCol = statisticsRow:CreateFontString("$parentAchievement", "BORDER", "GameFontHighlightSmall")
        achievementCol:SetJustifyH("RIGHT")
        achievementCol:SetSize(60, 14)
        achievementCol:SetPoint("LEFT", nameCol, "RIGHT", 0, 0)

        local hkCol = statisticsRow:CreateFontString("$parentHk", "BORDER", "GameFontHighlightSmall")
        hkCol:SetJustifyH("RIGHT")
        hkCol:SetSize(60, 14)
        hkCol:SetPoint("LEFT", achievementCol, "RIGHT", 0, 0)

        local arena2v2Col = statisticsRow:CreateFontString("$parentArena2v2", "BORDER", "GameFontHighlightSmall")
        arena2v2Col:SetJustifyH("RIGHT")
        arena2v2Col:SetSize(60, 14)
        arena2v2Col:SetPoint("LEFT", hkCol, "RIGHT", 0, 0)

        local arena3v3Col = statisticsRow:CreateFontString("$parentArena3v3", "BORDER", "GameFontHighlightSmall")
        arena3v3Col:SetJustifyH("RIGHT")
        arena3v3Col:SetSize(60, 14)
        arena3v3Col:SetPoint("LEFT", arena2v2Col, "RIGHT", 0, 0)

        local arena5v5Col = statisticsRow:CreateFontString("$parentArena5v5", "BORDER", "GameFontHighlightSmall")
        arena5v5Col:SetJustifyH("RIGHT")
        arena5v5Col:SetSize(60, 14)
        arena5v5Col:SetPoint("LEFT", arena3v3Col, "RIGHT", 0, 0)

        local repCol = statisticsRow:CreateFontString("$parentRep", "BORDER", "GameFontHighlightSmall")
        repCol:SetJustifyH("RIGHT")
        repCol:SetSize(26, 14)
        repCol:SetPoint("LEFT", arena5v5Col, "RIGHT", 0, 0)
    end
end


if not E.selectedList then
    E.selectedList = 1
end

function E:AddToggleButton()
    GuildFrameGuildListToggleButton:Hide()
    local dropdown = C:CreateFrame("Frame", "$parentListDropdown", GuildFrame, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, 95)
    dropdown:SetPoint("RIGHT", GuildFrameGuildListToggleButton, "RIGHT", 10, -2)
    dropdown.value = E.selectedList
    local lists = { "Player status", "Guild status", "Statistics"}
    local initMenu = function()
        local selectedValue = UIDropDownMenu_GetSelectedValue(dropdown);
        local info = UIDropDownMenu_CreateInfo();

        for index, list in ipairs(lists) do
            info.text = list;
            info.func = function(self)
                dropdown:SetValue(self.value)
            end;
            info.value = index
            if (info.value == selectedValue) then
                info.checked = 1;
            else
                info.checked = nil;
            end
            UIDropDownMenu_AddButton(info);
        end

    end

    UIDropDownMenu_Initialize(dropdown, initMenu);
    UIDropDownMenu_SetSelectedValue(dropdown, dropdown.value);

    dropdown.SetValue = function(self, value)
        self.value = value;
        E.selectedList = value
        UIDropDownMenu_SetSelectedValue(self, value);
        C:GuildStatus_UpdateHook()
    end
    dropdown.GetValue = function(self)
        return UIDropDownMenu_GetSelectedValue(self);
    end
    dropdown.RefreshValue = function(self)
        UIDropDownMenu_Initialize(self, initMenu)
        UIDropDownMenu_SetSelectedValue(self, self.value);
    end
end

function E:UpdateSelectedListFrame()
    if E.selectedList == 1 then
        GuildFrameStatisticsFrame:Hide()
        if not FriendsFrame.playerStatusFrame or E.customListActive then
            E.customListActive = false
            GuildFrameGuildListToggleButton_OnClick()
        end
    elseif E.selectedList == 2 then
        GuildFrameStatisticsFrame:Hide()
        if FriendsFrame.playerStatusFrame or E.customListActive then
            E.customListActive = false
            GuildFrameGuildListToggleButton_OnClick()
        end
    else
        GuildPlayerStatusFrame:Hide()
        GuildStatusFrame:Hide()
        GuildFrameStatisticsFrame:Show()
        C:RenderGuildFrame(GuildFrameStatisticsFrame)
        E.customListActive = true
        C:AddToUpdateQueue(function(id)
            C:RemoveFromUpdateQueue(id)
            GuildPlayerStatusFrame:Hide()
            GuildStatusFrame:Hide()
            GuildFrameStatisticsFrame:Show()


        end)
    end
end


function E:UpdateStatisticRows()
    local guildOffset = FauxScrollFrame_GetOffset(GuildListScrollFrame)
    for i = 1, GUILDMEMBERS_TO_DISPLAY do
        local index = i + guildOffset
        local member = E.members[index]
        local row = _G["GuildFrameStatisticsFrameRow"..i]
        if member then

            local nameCol = _G["GuildFrameStatisticsFrameRow"..i.."Name"]
            local achievementCol = _G["GuildFrameStatisticsFrameRow"..i.."Achievement"]
            local hkCol = _G["GuildFrameStatisticsFrameRow"..i.."Hk"]
            local arena2v2 = _G["GuildFrameStatisticsFrameRow"..i.."Arena2v2"]
            local arena3v3 = _G["GuildFrameStatisticsFrameRow"..i.."Arena3v3"]
            local arena5v5 = _G["GuildFrameStatisticsFrameRow"..i.."Arena5v5"]
            local rep = _G["GuildFrameStatisticsFrameRow"..i.."Rep"]
            row:Show()
            nameCol:SetText(C:AddClassColorToName(member.name))
            achievementCol:SetText(member.achievement == 0 and "-" or member.achievement)
            hkCol:SetText(member.hk == 0 and "-" or member.hk)
            arena2v2:SetText(member.arena2v2 == 0 and "-" or member.arena2v2)
            arena3v3:SetText(member.arena3v3 == 0 and "-" or member.arena3v3)
            arena5v5:SetText(member.arena5v5 == 0 and "-" or member.arena5v5)
            rep:SetText(member.rep == 0 and "-" or member.rep)
            if member.online then
                nameCol:SetAlpha(1)
            else
                nameCol:SetAlpha(0.4)
            end
        else
            row:Hide()
        end

    end

end
