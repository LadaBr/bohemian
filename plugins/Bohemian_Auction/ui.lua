---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by brode.
--- DateTime: 10.02.2022 9:45
---

local _, E = ...
local C = E.CORE

BIDDER_TABLE_SIZE = 7

function E:RefreshTotalDKP()
    local currentDKP = E:GetCurrentDKP()
    if not currentDKP then
        return
    end
    self.frames.auction.totalDKPValue:SetText(currentDKP)
    if self.currentItem and self.currentItem.price then
        self:SetCurrentDKPValue(currentDKP - self.currentItem.price)
    end
end

function E:SetCurrentDKPValue(value)
    if value <= 0 then
        value = C:colorize(value, C.COLOR.RED)
    end
    self.frames.auction.currentDKPValue:SetText(value)
end

function E:EnableBidding(toggle)
    self.isBiddingEnabled = toggle
    if toggle then
        self.frames.auction.bid:Enable()
    else
        self.frames.auction.bid:Disable()
    end
end

function E:SetHighestBidder(name, value)
    if E.isRollMode then
        E:SetHighestRoller(name, value)
    else
        E:SetHighestDKPBidder(name, value)
    end
end

function E:SetHighestDKPBidder(name, value)
    if name then
        local tooltip
        local nameStr
        if self.bidInfo.value == value then
            self.conflicts[name] = value
            self.conflicts[self.bidInfo.name] = E.bidInfo.value
            nameStr = C:colorize("Conflict", C.COLOR.DARKRED)
            local tmp =  {}
            for k, _ in pairs(self.conflicts) do
                table.insert(tmp, C:AddClassColorToName(k))
            end
            tooltip = table.concat(tmp, "\n")
        else
            nameStr = C:AddClassColorToName(name)
            self.conflicts = {}
        end
        self.frames.auction.highestBidder:SetText("Highest bid: "..nameStr)
        self.frames.auction.highestBidder:Show()
        self.frames.auction.highestBidder.frame.tooltip = tooltip
    else
        self.frames.auction.highestBidder:Hide()
    end
    self.bidInfo.value = value
    self.bidInfo.name = name
end

function E:SetHighestRoller(name, value)
    if name then
        local tooltip
        local nameStr
        if self.rollInfo.value == value then
            self.rollConflicts[name] = value
            self.rollConflicts[self.rollInfo.name] = E.rollInfo.value
            nameStr = C:colorize("Conflict", C.COLOR.DARKRED)
            local tmp =  {}
            for k, _ in pairs(self.rollConflicts) do
                table.insert(tmp, C:AddClassColorToName(k))
            end
            tooltip = table.concat(tmp, "\n")
        else
            nameStr = C:AddClassColorToName(name)
            self.rollConflicts = {}
        end
        self.frames.auction.highestBidder:SetText("Highest roll: "..nameStr)
        self.frames.auction.highestBidder:Show()
        self.frames.auction.highestBidder.frame.tooltip = tooltip
    else
        self.frames.auction.highestBidder:Hide()
    end
    self.rollInfo.value = value
    self.rollInfo.name = name
end

function E:GetTimerColor(value, maxValue)
    local prc = (100 / maxValue) * value
    for _, c in pairs(Bohemian_AuctionConfig.timerColors) do
        if prc >= c[1] then
            return c[2]
        end
    end
end
function E:UpdateBidderTable()
    if E.isRollMode then
        E:UpdateRollTable()
    else
        E:UpdateDKPBidderTable()
    end

end

function E:GetFontFromRollValue(roll)
    local font
    if roll == 100 then
        font = "QuestDifficulty_VeryDifficult"
    elseif roll >= 75 then
        font = "GameFontGreenSmall"
    elseif roll < 75 and roll >= 25 then
        font = "GameFontNormalSmall"
    else
        font = "GameFontNormalGraySmall"
    end
    return font
end

function E:UpdateRollTable()
    if not self.rollHistory  then
        return
    end
    self.sortedHistory = {}
    for name, roll in pairs(self.rollHistory) do
        if roll ~= nil then
            table.insert(self.sortedHistory, {name=name, roll=roll})
        end
    end
    table.sort(self.sortedHistory, function(a,b) return a.roll > b.roll end)
    for i = 1, BIDDER_TABLE_SIZE do
        local btn = _G["LootMasterFrameBidder"..i]
        local bidder = self.sortedHistory[i]
        if not bidder then
            btn:Reset()
        else
            local name = C:AddClassColorToName(bidder.name)
            btn.name:SetText(strsplit("-", name))
            btn.value:SetText( "")
            local font = E:GetFontFromRollValue(bidder.roll)

            btn.dkp:SetFontObject(font)
            btn.dkp:SetText(bidder.roll)
            btn:Show()
        end
    end
end

function E:UpdateDKPBidderTable()
    if not self.bidHistory  then
        return
    end
    self.sortedHistory = {}
    for name, bid in pairs(self.bidHistory) do
        if bid ~= nil then
            table.insert(self.sortedHistory, {name=name, bid=bid})
        end
    end
    table.sort(self.sortedHistory, function(a,b) return a.bid > b.bid end)
    for i = 1, BIDDER_TABLE_SIZE do
        local btn = _G["LootMasterFrameBidder"..i]
        local bidder = self.sortedHistory[i]
        if not bidder then
            btn:Reset()
        else
            local name = C:AddClassColorToName(bidder.name)
            btn.name:SetText(strsplit("-", name))
            btn.value:SetText( bidder.bid)
            local delta = self:GetCurrentDKP(bidder.name) - self.currentItem.price
            local font
            if delta == 0 then
                font = "GameFontRedSmall"
            elseif delta < 0 then
                font = "GameFontNormalGraySmall"
            else
                font = "GameFontHighlightSmall"
            end
            btn.dkp:SetFontObject(font)
            btn.dkp:SetText(delta)
            btn:Show()
        end
    end
end

function E:UpdateWinner()
    local isSelected = 0
    for i = 1, BIDDER_TABLE_SIZE do
        local frame = _G["LootMasterFrameBidder"..i]
        if frame.selected then
            isSelected = i
            break
        end
    end
    if isSelected > 0 then
        self.frames.auction.lootMasterFrame.award:Enable()
        self.currentItemWinner = self.sortedHistory[isSelected]
    else
        self.frames.auction.lootMasterFrame.award:Disable()
        self.currentItemWinner = nil
    end
end

function E:UpdateBidButtonState()
    if not self.currentItem then
        return
    end
    if self.passed then
        self:EnableBidding(false)
        return
    end
    local playerName = C:GetPlayerName(true)
    local hasEnoughDKP = self.currentItem.price <= self:GetCurrentDKP(playerName)
    if self.bidInfo.name ~= playerName then
        self:EnableBidding(hasEnoughDKP)
    else
        self:EnableBidding(false)
    end
end
function E:UpdatePassButtonState()
    local button = self.frames.auction.pass
    if not self.currentItem then
        return
    end
    if C:GetPlayerName(true) == self.bidInfo.name or self.passed or self.conflicts[C:GetPlayerName(true)] then
        button:Disable()
    else
        button:Enable()
    end
end

function E:CreateAuctionFrame()
    local containerWidth = 210
    local container =  C:CreateFrame("Frame", "BohemkaDKPAuctionFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    local pos = Bohemian_AuctionConfig.position or {}
    container:SetPoint(pos.point or "CENTER", pos.x, pos.y)
    container:SetWidth(containerWidth)
    container:SetHeight(219)
    container:SetBackdrop(BACKDROP_DIALOG_32_32)
    container:SetMovable(true)
    container:EnableMouse(true)
    container:SetUserPlaced(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", container.StartMoving)
    container:SetScript("OnDragStop", function()
        local point, _, _, xOfs, yOfs = container:GetPoint()
        Bohemian_AuctionConfig.position = {
            x = xOfs,
            y = yOfs,
            point = point
        }
        container:StopMovingOrSizing()
    end)
    container:Hide()
    self.frames.auction = container


    local f2 = C:CreateFrame("BUTTON", "AuctionDKPClose", container, "UIPanelCloseButton");
    f2:SetPoint("TOPRIGHT", container, "TOPRIGHT", -4, -4)
    f2:HookScript("OnClick", function()
        E:Pass()
    end)

    local frameHeader = container:CreateTexture("$parentHeader", "OVERLAY")
    frameHeader:SetPoint("TOP", 0, 12)
    frameHeader:SetTexture(131080) -- "Interface\\DialogFrame\\UI-DialogBox-Header"
    frameHeader:SetSize(290, 64)

    local frameHeaderText = container:CreateFontString("$parentHeaderText", "OVERLAY", "GameFontNormal")
    frameHeaderText:SetPoint("TOP", frameHeader, 0, -14)
    frameHeaderText:SetText("Auction")

    container.paper = container:CreateTexture(nil, "ARTWORK")
    container.paper:SetPoint("TOPLEFT", 11, -11)
    container.paper:SetWidth(257)
    container.paper:SetHeight(138)
    container.paper:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Reputation-DetailBackground")
    -- container.paper:SetColorTexture(0, 0, 0, 1)

    container.divider = container:CreateTexture(nil, "OVERLAY")
    container.divider:SetPoint("TOPLEFT", 9, -139)
    container.divider:SetWidth(256)
    container.divider:SetHeight(32)
    container.divider:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Divider")



    local a = C:CreateFrame("Frame", "$parentStatusBarContainer", container, BackdropTemplateMixin and "BackdropTemplate" or nil)
    a:SetSize(137, 21)
    a:SetPoint("TOP", 0, -25)
    a:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3, },
    })
    a:SetBackdropColor(0, 0, 0, 0.7)
    a:SetBackdropBorderColor(0.2, 0.2, 0.2)
    a:Hide()

    container.statusBar = C:CreateFrame("StatusBar", "$parentStatusBar", a)
    container.statusBar:SetPoint("TOPLEFT", 4, -4)
    container.statusBar:SetPoint("TOPRIGHT", -4, 6)
    container.statusBar:SetWidth(137)
    -- container.statusBar:SetFrameStrata("HIGH")
    container.statusBar:SetHeight(13)
    container.statusBar:SetMinMaxValues(0, E.currentTime)
    container.statusBar:SetValue(E.currentTime)
    container.statusBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    container.statusBar.parent = a

    font = container.statusBar:CreateFontString(nil,"ARTWORK", "GameFontHighlightSmall")
    font:SetJustifyH("CENTER")
    font:SetPoint("CENTER")
    font:SetText("60")
    font:SetTextColor(1, 0.82, 0)

    container.item =  C:CreateFrame("BUTTON", "AuctionFrameItem", container, "LootButtonTemplate")
    container.item:SetPoint("TOPLEFT", a, "BOTTOMLEFT", -7, -5)
    container.item:SetHitRectInsets(0, -107, 0, 0)
    container.item:SetScript("OnClick", nil)
    container.item:SetScript("OnUpdate", nil)
    container.item:SetScript("OnEnter", function(self)
        if not E.currentItem then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        itemName, itemLink = GetItemInfo(E.currentItem.id)
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Show();
    end)

    container.statusBar.font = font

    local price = container.item:CreateFontString("$parentPrice","ARTWORK", "GameFontHighlightLarge")
    price:SetJustifyH("CENTER")
    price:SetPoint("TOPLEFT", container.item, "BOTTOMLEFT", 0, -13)
    price:SetText("Price:")
    price:SetTextColor(1, 0.82, 0)

    local priceValue = container.item:CreateFontString("AuctionItemPriceValue","ARTWORK", "GameFontHighlightLarge")
    priceValue:SetJustifyH("LEFT")
    priceValue:SetPoint("LEFT", price, "RIGHT", 5, 0)
    priceValue:SetText("100")
    priceValue:SetWidth(100)
    priceValue:SetTextColor(1, 0.82, 0)
    container.item.priceValue = priceValue

    local e = C:CreateFrame("EditBox", "BidValue", container, "InputBoxTemplate")
    e:SetWidth(70)
    e:SetHeight(33)
    e:SetPoint("BOTTOM", 2, 7)
    e:SetFontObject("GameFontHighlight")
    e:SetTextInsets(5,8,0,0)
    e:SetMultiLine(false)
    e:SetAutoFocus(false)
    e:SetNumeric(true)
    e:SetJustifyH("CENTER")
    e:SetScript( "OnEscapePressed", function( )
        e:ClearFocus()
    end )
    e:SetText("10")
    e:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        E:Bid(tonumber(self:GetText()))
    end)
    e:SetScript("OnChar", function(self)
        self.isChanged = true
    end)


    local btn = C:CreateFrame("Button", "BidButton", container, "UIPanelButtonTemplate")
    btn:SetPoint("BOTTOMRIGHT", container, -10, 10)
    btn:SetSize(56, 28)
    btn:SetText("Bid")
    btn:RegisterForClicks("AnyUp")
    btn:SetScript("OnClick", function()
        E:Bid(e:GetNumber())
        e:ClearFocus()
        e.isChanged = false
    end)

    container.bid = btn

    local pass = C:CreateFrame("Button", "ButtonPass", container, "UIPanelButtonTemplate")
    pass:SetPoint("BOTTOMLEFT", 10, 10)
    pass:SetSize(56, 28)
    pass:SetText("Pass")
    pass:RegisterForClicks("AnyUp")
    pass:SetScript("OnClick", function()
        e:ClearFocus()
        E:Pass()
    end)

    container.pass = pass
    local highestBidderFrame = C:CreateFrame("Frame", "$parentHighestBidderFrame", container)
    highestBidderFrame:SetPoint("TOPLEFT", price, "BOTTOMLEFT", 0, -3)
    highestBidderFrame:SetSize(container:GetWidth() - 45, 15)
    highestBidderFrame:SetScript("OnEnter", function(self)
        if self.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP");
            GameTooltip:SetText(self.tooltip);
            GameTooltip:Show();
        end
    end)
    highestBidderFrame:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end)
    local highestBidder = highestBidderFrame:CreateFontString(nil,"ARTWORK", "GameFontHighlight")
    highestBidder:SetJustifyH("LEFT")
    highestBidder:SetAllPoints(highestBidderFrame)
    highestBidder:SetText("Highest bid:")
    highestBidder:SetTextColor(1, 0.82, 0)
    highestBidder:Hide()
    highestBidder.frame = highestBidderFrame
    container.highestBidder = highestBidder

    local currentDKP = container:CreateFontString(nil,"ARTWORK", "GameFontNormal")
    currentDKP:SetJustifyH("RIGHT")
    currentDKP:SetPoint("BOTTOMRIGHT", btn, "TOPRIGHT", -13, 6)
    currentDKP:SetText("")

    local arrow = container:CreateTexture("$parentArrow", "ARTWORK")
    arrow:SetPoint("BOTTOM", 0, 44)
    arrow:SetTexture("Interface\\Glues\\Common\\Glue-RightArrow-Button-Up") -- "Interface\\DialogFrame\\UI-DialogBox-Header"
    arrow:SetSize(24, 24)

    local currentDKPValue = container:CreateFontString(nil,"ARTWORK", "GameFontHighlight")
    currentDKPValue:SetJustifyH("LEFT")
    currentDKPValue:SetPoint("LEFT", arrow, "RIGHT", 5, 0)
    currentDKPValue:SetText("0")
    container.currentDKPValue = currentDKPValue

    local b = container:CreateFontString(nil,"ARTWORK", "GameFontNormal")
    b:SetJustifyH("CENTER")
    b:SetPoint("RIGHT", arrow, "LEFT", -5, 0)
    b:SetText("0")
    container.totalDKPValue = b

    local divider2 = container:CreateTexture(nil, "OVERLAY")
    divider2:SetPoint("TOPLEFT", 9, -169)
    divider2:SetWidth(256)
    divider2:SetHeight(32)
    divider2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Divider")

    local marble = container:CreateTexture(nil, "BACKGROUND")
    marble:SetPoint("TOPLEFT", container.divider, "TOPLEFT", 0, -5)
    marble:SetWidth(containerWidth - 20)
    marble:SetHeight(70)
    marble:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")

    local lootMasterFrameWidth = 213
    local lootMasterFrame = C:CreateFrame("Frame", "LootMasterFrame", container, BackdropTemplateMixin and "BackdropTemplate" or nil)
    lootMasterFrame:SetPoint("TOPLEFT", container, "TOPRIGHT", -12, 0)
    lootMasterFrame:SetWidth(lootMasterFrameWidth)
    lootMasterFrame:SetHeight(219)
    lootMasterFrame:SetBackdrop(BACKDROP_DIALOG_32_32)
    lootMasterFrame:Hide()

    container.lootMasterFrame = lootMasterFrame

    local bg = lootMasterFrame:CreateTexture(nil, "ARTWORK")
    bg:SetPoint("TOPLEFT", 12, -12)
    bg:SetPoint("BOTTOMRIGHT", -12, 12)
    bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")

    local f = C:CreateFrame("BUTTON", "BidderNameHeader1", lootMasterFrame, "GuildFrameColumnHeaderTemplate");
    f:SetPoint("TOPLEFT", 10, -10)
    f:SetText("Name")
    WhoFrameColumn_SetWidth(f, 107)

    f2 = C:CreateFrame("BUTTON", "BidderNameHeader2", lootMasterFrame, "GuildFrameColumnHeaderTemplate");
    f2:SetPoint("LEFT", f, "RIGHT", 0, 0)
    f2:SetText("Bid")
    WhoFrameColumn_SetWidth(f2, 43)

    local f3 = C:CreateFrame("BUTTON", "BidderNameHeader3", lootMasterFrame, "GuildFrameColumnHeaderTemplate");
    f3:SetPoint("LEFT", f2, "RIGHT", 0, 0)
    f3:SetText("DKP")
    WhoFrameColumn_SetWidth(f3, 43)

    local lootMasterFrameBg = C:CreateFrame("Frame", "LootMasterFrameBG", lootMasterFrame, "InsetFrameTemplate")
    lootMasterFrameBg:SetPoint("TOPLEFT", 10, -33)
    lootMasterFrameBg:SetPoint("BOTTOMRIGHT", -10, 10)

    local award = C:CreateFrame("Button", "ButtonLMAward", lootMasterFrame, "UIPanelButtonTemplate")
    award:SetPoint("BOTTOMRIGHT", -15, 16)
    award:SetSize(56, 28)
    award:SetText("Award")
    award:Disable()
    award:RegisterForClicks("AnyUp")
    award:SetScript("OnClick", function()
        E:EndAuction()
    end)
    lootMasterFrame.award = award

    local prevFrame
    for i = 1, BIDDER_TABLE_SIZE do
        local frameName = "LootMasterFrameBidder"..i
        local bidder = C:CreateFrame("Button", frameName, lootMasterFrame)
        bidder:SetNormalTexture("Interface\\GuildFrame\\GuildFrame")
        bidder:GetNormalTexture():SetTexCoord(0.36230469, 0.38183594, 0.95898438, 0.99804688)
        bidder:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
        bidder.Reset = function(self)
            self:Hide()
            self:UnlockHighlight()
            self.selected = false
        end
        bidder:SetSize(lootMasterFrameWidth - 31, 18)
        bidder:SetScript("OnClick", function(self)
            for j = 1, BIDDER_TABLE_SIZE do
                local frame = _G["LootMasterFrameBidder"..j]
                if frame ~= bidder then
                    frame:UnlockHighlight()
                    frame.selected = false
                end
            end
            if not self.selected then
                self:LockHighlight()
                self.selected = true
            else
                self:UnlockHighlight()
                self.selected = false
            end
            E:UpdateWinner()
        end)
        local bidderName = bidder:CreateFontString(frameName.."Name","ARTWORK", "GameFontNormalSmall")
        bidderName:SetJustifyH("LEFT")
        bidderName:SetPoint("LEFT", 5, 0)
        bidderName:SetText("")
        local bidderDKP = bidder:CreateFontString(frameName.."DKP","ARTWORK", "GameFontNormalGraySmall")
        bidderDKP:SetJustifyH("RIGHT")
        bidderDKP:SetPoint("RIGHT", -5, 0)
        bidderDKP:SetText("1850")
        bidderDKP:SetWidth(38)
        local bidderValue = bidder:CreateFontString(frameName.."Value","ARTWORK", "GameFontNormalSmall")
        bidderValue:SetJustifyH("RIGHT")
        bidderValue:SetPoint("RIGHT", bidderDKP, "LEFT", 0, 0)
        bidderValue:SetText()

        if prevFrame then
            bidder:SetPoint("TOP", prevFrame, "BOTTOM", 0, 0)
        else
            bidder:SetPoint("TOP", lootMasterFrameBg, "TOP", 0, -4)
        end
        prevFrame = bidder
        bidder.name = bidderName
        bidder.value = bidderValue
        bidder.dkp = bidderDKP
        bidder:Hide()
    end

    local divider3 = lootMasterFrameBg:CreateTexture(nil, "OVERLAY")
    divider3:SetPoint("TOPLEFT", prevFrame, "BOTTOMLEFT", -3, 4)
    divider3:SetWidth(250)
    divider3:SetHeight(32)
    divider3:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Divider")

    local cancel = C:CreateFrame("Button", "ButtonLMCancel", lootMasterFrame, "UIPanelButtonTemplate")
    cancel:SetPoint("BOTTOMLEFT", 15, 16)
    cancel:SetSize(56, 28)
    cancel:SetText("Cancel")
    cancel:RegisterForClicks("AnyUp")
    cancel:SetScript("OnClick", function()
        if E.countdownActive then
            E:CancelAuctionCountdown()
            return
        end
        E.currentItemWinner = nil
        E:EndAuction()

    end)

    local mode = C:CreateFrame("Button", "ButtonAuctionMode", lootMasterFrame, "SecureHandlerClickTemplate")
    mode:SetPoint("BOTTOM", 0, 16)
    mode:SetSize(28, 28)
    mode:SetText("Cancel")
    mode:RegisterForClicks("AnyUp")
    mode:SetAlpha(0.5)
    mode:SetScript("OnClick", function()
        E:ToggleRollMode()
    end)
    mode:SetScript("OnEnter", function()
        if not E:IsPlayerAuctionOwner() or E.isRollMode then
            return
        end
        mode:SetAlpha(0.75)
    end)
    mode:SetScript("OnLeave", function()
        if not E:IsPlayerAuctionOwner() or E.isRollMode then
            return
        end
        mode:SetAlpha(0.3)
    end)


    local modeTexture = mode:CreateTexture(nil, "OVERLAY")
    modeTexture:SetAllPoints(true)
    modeTexture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
    --modeTexture:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")

    local rollBtn = C:CreateFrame("Button", "RollButton", container, "UIPanelButtonTemplate")
    rollBtn:SetPoint("CENTER", BidValue, 0, 0)
    rollBtn:SetSize(120, 28)
    rollBtn:SetText("Roll")
    rollBtn:Hide()
    rollBtn:Disable()
    rollBtn:RegisterForClicks("AnyUp")
    rollBtn:SetScript("OnClick", function()
        RandomRoll(1, 100)
    end)
end

function E:ToggleRollMode()
    if not E:IsPlayerAuctionOwner() then
        return
    end
    local itemName, itemLink, itemRarity, _, _, _, _, _, _, itemTexture, _ = GetItemInfo(E.currentItem.id)
    if not E.isRollMode then
        C:SendEvent(self:GetBroadcastChannel(), "ROLL_MODE_START")
        SendChatMessage(format("You can now roll for %s", itemLink), self:GetBroadcastChannel())
    else
        C:SendEvent(self:GetBroadcastChannel(), "ROLL_MODE_END")
        SendChatMessage(format("You can no longer roll for %s", itemLink), self:GetBroadcastChannel())
    end
end

function E:AddConfigFrames(f)
    local title, _ = C:AddConfigEditBox(f, {"TOPLEFT", f, "TOPLEFT", 30, -26}, "MinimalBid", "Minimal Bid", Bohemian_AuctionConfig.minBid, "DKP")
    title, _ = C:AddConfigEditBox(f, {"TOPLEFT", title, "BOTTOMLEFT", 0, -10}, "MinItemPrice", "Minimal Item Price", Bohemian_AuctionConfig.minItemPrice, "DKP")
    title, _ = C:AddConfigEditBox(f, {"TOPLEFT", title, "BOTTOMLEFT", 0, -10}, "AuctionCountdown", "Auction Countdown", Bohemian_AuctionConfig.timerMax, "second(s)")
    local dkp, _ = C:AddConfigEditBox(f, {"TOPLEFT", title, "BOTTOMLEFT", 0, -10}, "StartingDKP", "Initial DKP", Bohemian_AuctionConfig.startingDKP)
    title, _ = C:AddConfigEditBox(f, {"TOPLEFT", dkp, "BOTTOMLEFT", 0, -10}, "BidCooldown", "Bid Cooldown", Bohemian_AuctionConfig.bidCooldown, "second(s)")



    local auctionStartKeyBind = C:CreateFrame("Frame", "$parentAuctionKeyBind", f, "UIDropDownMenuTemplate")
    auctionStartKeyBind:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -17, -30)
    auctionStartKeyBind.value = Bohemian_AuctionConfig.startAuctionModifier

    local initMenu = function()
        local selectedValue = UIDropDownMenu_GetSelectedValue(auctionStartKeyBind);
        local info = UIDropDownMenu_CreateInfo();

        for _, key in ipairs({"ALT", "SHIFT", "SHIFT+ALT"}) do
            info.text = key;
            info.func = function(self)
                auctionStartKeyBind:SetValue(self.value)
            end;
            info.value = key
            if ( info.value == selectedValue ) then
                info.checked = 1;
            else
                info.checked = nil;
            end
            UIDropDownMenu_AddButton(info);
        end

    end

    UIDropDownMenu_Initialize(auctionStartKeyBind, initMenu);
    UIDropDownMenu_SetSelectedValue(auctionStartKeyBind, auctionStartKeyBind.value);

    auctionStartKeyBind.SetValue = function (self, value)
        self.value = value;
        Bohemian_AuctionConfig.startAuctionModifier = value
        UIDropDownMenu_SetSelectedValue(self, value);
    end
    auctionStartKeyBind.GetValue = function (self)
        return UIDropDownMenu_GetSelectedValue(self);
    end
    auctionStartKeyBind.RefreshValue = function (self)
        UIDropDownMenu_Initialize(self, initMenu)
        UIDropDownMenu_SetSelectedValue(self, self.value);
    end


    font = auctionStartKeyBind:CreateFontString("$parentText","ARTWORK", "GameFontNormal")
    font:SetJustifyH("LEFT")
    -- font:SetSize(150, 14)
    font:SetPoint("BOTTOMLEFT", auctionStartKeyBind, "TOPLEFT", 16, 3)
    font:SetText("Auction Start Modifier")

    local bidInfoChatButton = C:CreateFrame("CheckButton", "$parentShowBidInfoInChat", f, "UICheckButtonTemplate");
    bidInfoChatButton:SetSize(22,22)
    bidInfoChatButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -26, -22)
    bidInfoChatButton:SetChecked(Bohemian_AuctionConfig.showBidInfoInChat)

    font = bidInfoChatButton:CreateFontString("$parentText","ARTWORK", "GameFontNormal")
    font:SetJustifyH("LEFT")
    font:SetSize(150, 14)
    font:SetPoint("RIGHT", bidInfoChatButton, "LEFT", 0, 0)
    font:SetText("Show bid info in chat")
    local toggleAuctionMode = C:CreateFrame("CheckButton", "$parentToggleAuctionMode", f, "UICheckButtonTemplate");
    toggleAuctionMode:SetSize(22,22)
    toggleAuctionMode:SetPoint("TOPLEFT", bidInfoChatButton, "BOTTOMLEFT", 0, -10)
    toggleAuctionMode:SetChecked(Bohemian_AuctionConfig.addToCurrentAmount)

    font = toggleAuctionMode:CreateFontString("$parentText","ARTWORK", "GameFontNormal")
    font:SetJustifyH("LEFT")
    font:SetSize(200, 14)
    font:SetPoint("RIGHT", toggleAuctionMode, "LEFT", 0, 0)
    font:SetText("Add bid value to current price")

    local l = f:CreateLine()
    l:SetColorTexture(0.3,0.3,0.3)
    l:SetStartPoint("TOPLEFT", f, 30, -220)
    l:SetEndPoint("TOPRIGHT", f, -30, -220)
    l:SetThickness(1)

    font = f:CreateFontString("$parentTextItemPrice","ARTWORK", "GameFontNormal")
    font:SetJustifyH("CENTER")
    font:SetSize(400, 14)
    font:SetPoint("TOP", l, "BOTTOM", 0, -10)
    font:SetText("Custom Minimal Item Price")

    local editBoxHeight = 265
    editboxBg = C:CreateFrame("Frame", "$parentEditBoxItemPrice", f, "TooltipBackdropTemplate")
    editboxBg:SetSize(font:GetWidth(), editBoxHeight)
    editboxBg:SetPoint("TOP", font, "BOTTOM", 0, -5)

    local itemPriceConfig = C:TableToConfigText(Bohemian_AuctionConfig.itemPrices)
    editbox = C:CreateFrame("EditBox", "$parentItemPrice", editboxBg)
    editbox:SetAllPoints(editboxBg)
    editbox:SetWidth(editboxBg:GetWidth() - 30)
    editbox:SetHeight(editboxBg:GetHeight())
    editbox:SetFontObject("GameFontHighlight")
    editbox:SetAutoFocus(false)
    editbox:SetMultiLine(true)
    editbox:SetTextInsets(8,8,8,8)
    editbox:SetText(itemPriceConfig)
    editbox:SetJustifyH("LEFT")
    editbox:SetScript( "OnEscapePressed", function( self )
        self:ClearFocus()
    end )

    Scroll = C:CreateFrame('ScrollFrame', '$parentEditBoxItemPriceScroll', f, 'UIPanelScrollFrameTemplate')
    Scroll:SetPoint('TOPLEFT', editboxBg, 'TOPLEFT', 8, -4)
    Scroll:SetPoint('BOTTOMRIGHT', editboxBg, 'BOTTOMRIGHT', -26, 3)
    Scroll:SetScrollChild(editbox)

    font = f:CreateFontString("$parentTextItemPrice","ARTWORK", "GameFontNormalSmall")
    font:SetJustifyH("LEFT")
    font:SetWidth(editbox:GetWidth())
    font:SetPoint("TOPLEFT", editboxBg, "BOTTOMLEFT", 10, -3)
    font:SetText("Example:")

    local font2 = f:CreateFontString("$parentTextItemPrice","ARTWORK", "GameFontHighlightSmall")
    font2:SetJustifyH("LEFT")
    font2:SetSize(editbox:GetWidth(), 40)
    font2:SetPoint("TOPLEFT", font, "BOTTOMLEFT", 0, 5)
    font2:SetText("Item Name=10\nItem Name2=30")
    local name = f:GetName()
    f.okay = function()
        Bohemian_AuctionConfig.itemPrices = C:ConfigTextToTable(_G[name.."EditBoxItemPriceItemPrice"]:GetText())
        Bohemian_AuctionConfig.minBid = _G[name.."EditBoxMinimalBid"]:GetNumber()
        Bohemian_AuctionConfig.minItemPrice = _G[name.."EditBoxMinItemPrice"]:GetNumber()
        Bohemian_AuctionConfig.timerMax = _G[name.."EditBoxAuctionCountdown"]:GetNumber()
        Bohemian_AuctionConfig.startingDKP = _G[name.."EditBoxStartingDKP"]:GetNumber()
        Bohemian_AuctionConfig.bidCooldown = _G[name.."EditBoxBidCooldown"]:GetNumber()
        Bohemian_AuctionConfig.showBidInfoInChat = _G[name.."ShowBidInfoInChat"]:GetChecked()
        Bohemian_AuctionConfig.startAuctionModifier = UIDropDownMenu_GetSelectedValue(_G[name.."AuctionKeyBind"])
        Bohemian_AuctionConfig.addToCurrentAmount = _G[name.."ToggleAuctionMode"]:GetChecked()
    end

    f.cancel = function()
        _G[name.."EditBoxItemPriceItemPrice"]:SetText(C:TableToConfigText(Bohemian_AuctionConfig.itemPrices))
        _G[name.."EditBoxMinimalBid"]:SetNumber(Bohemian_AuctionConfig.minBid)
        _G[name.."EditBoxMinItemPrice"]:SetNumber(Bohemian_AuctionConfig.minItemPrice)
        _G[name.."EditBoxAuctionCountdown"]:SetNumber(Bohemian_AuctionConfig.timerMax)
        _G[name.."EditBoxStartingDKP"]:SetNumber(Bohemian_AuctionConfig.startingDKP)
        _G[name.."EditBoxBidCooldown"]:SetNumber(Bohemian_AuctionConfig.bidCooldown)
        _G[name.."ShowBidInfoInChat"]:SetChecked(Bohemian_AuctionConfig.showBidInfoInChat)
        _G[name.."ToggleAuctionMode"]:SetChecked(Bohemian_AuctionConfig.addToCurrentAmount)
        UIDropDownMenu_SetSelectedValue(_G[name.."AuctionKeyBind"], Bohemian_AuctionConfig.startAuctionModifier);
    end
end
