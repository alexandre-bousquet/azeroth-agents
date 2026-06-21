local addonName, AA = ...

AA.UI = {}

local CARD_SIZE = 104
local CARD_GAP = 8
local SIDE_PANEL_X = 610
local SIDE_PANEL_WIDTH = 300
local LOBBY_BUTTON_GAP = 10
local LOBBY_ACTION_WIDTH = (SIDE_PANEL_WIDTH - LOBBY_BUTTON_GAP) / 2
local LOBBY_LAUNCH_WIDTH = SIDE_PANEL_WIDTH

local TYPE_COLORS = {
    RED = { 0.62, 0.08, 0.08, 0.92 },
    BLUE = { 0.08, 0.22, 0.65, 0.92 },
    NEUTRAL = { 0.47, 0.38, 0.24, 0.92 },
    ASSASSIN = { 0.02, 0.02, 0.02, 0.95 },
    HIDDEN = { 0.12, 0.10, 0.08, 0.92 },
    EMPTY = { 0.04, 0.04, 0.04, 0.65 }
}

local TYPE_TEXT_COLORS = {
    RED = { 1, 0.88, 0.88 },
    BLUE = { 0.86, 0.91, 1 },
    NEUTRAL = { 1, 0.95, 0.82 },
    ASSASSIN = { 1, 0.25, 0.25 },
    HIDDEN = { 1, 0.92, 0.72 }
}

local ui = {
    frame = nil,
    title = nil,
    subtitle = nil,
    status = nil,
    turnText = nil,
    boardFrame = nil,
    cards = {},
    statsText = nil,
    lobbyText = nil,
    lobbyStatus = nil,
    lobbyTitle = nil,
    missionTitle = nil,
    agentsTitle = nil,
    historyTitle = nil,
    languageButton = nil,
    createButton = nil,
    joinButton = nil,
    leaveButton = nil,
    readyButton = nil,
    redButton = nil,
    blueButton = nil,
    agentButton = nil,
    spyRoleButton = nil,
    launchButton = nil,
    endTurnButton = nil,
    resetButton = nil,
    channelText = nil,
    clueEdit = nil,
    clueNumberEdit = nil,
    clueText = nil,
    clueInputLabel = nil,
    clueButton = nil,
    historyText = nil,
    syncButton = nil
}

local function ApplyColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4])
end

local function SetFontColor(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3])
end

local function L(key, ...)
    if AA.Locale then
        return AA.Locale:T(key, ...)
    end

    return key
end

local function SetRegionShown(region, shown)
    if not region then
        return
    end

    if shown then
        region:Show()
    else
        region:Hide()
    end
end

local function SetButtonEnabled(button, enabled)
    if not button then
        return
    end

    if enabled then
        button:Enable()
    else
        button:Disable()
    end
end

local function CreateDivider(parent, y, leftOffset, rightOffset)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", parent, "TOPLEFT", leftOffset or 18, y)
    line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", rightOffset or -18, y)
    line:SetColorTexture(1, 0.82, 0.35, 0.22)
    return line
end

local function CreatePanelTitle(parent, text, x, y)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", x, y)
    title:SetText(text)
    return title
end

local function CreateButton(parent, text, width, height, point, relativeTo, relativePoint, x, y, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 110, height or 26)

    if relativeTo then
        button:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
    else
        button:SetPoint(point, x or 0, y or 0)
    end

    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end


local function CreateEditBox(parent, width, height, point, relativeTo, relativePoint, x, y)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width or 120, height or 24)
    edit:SetAutoFocus(false)
    edit:SetText("")

    if relativeTo then
        edit:SetPoint(point, relativeTo, relativePoint, x or 0, y or 0)
    else
        edit:SetPoint(point, x or 0, y or 0)
    end

    return edit
end

local function CreateCard(parent, index)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(CARD_SIZE, CARD_SIZE)
    button:RegisterForClicks("LeftButtonUp")

    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints(button)
    ApplyColor(button.bg, TYPE_COLORS.EMPTY)

    button.border = button:CreateTexture(nil, "BORDER")
    button.border:SetPoint("TOPLEFT", -1, 1)
    button.border:SetPoint("BOTTOMRIGHT", 1, -1)
    button.border:SetColorTexture(1, 0.82, 0.35, 0.20)

    button.inner = button:CreateTexture(nil, "ARTWORK")
    button.inner:SetPoint("TOPLEFT", 3, -3)
    button.inner:SetPoint("BOTTOMRIGHT", -3, 3)
    button.inner:SetColorTexture(0, 0, 0, 0.18)

    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("TOPLEFT", 7, -7)
    button.text:SetPoint("BOTTOMRIGHT", -7, 7)
    button.text:SetJustifyH("CENTER")
    button.text:SetJustifyV("MIDDLE")
    button.text:SetWordWrap(true)
    button.text:SetText("")

    button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
    button.highlight:SetAllPoints(button)
    button.highlight:SetColorTexture(1, 1, 1, 0.10)

    button:SetScript("OnClick", function()
        AA.Game:RevealCard(index, true)
    end)

    button:SetScript("OnEnter", function(self)
        self.border:SetColorTexture(1, 0.82, 0.35, 0.55)
    end)

    button:SetScript("OnLeave", function(self)
        self.border:SetColorTexture(1, 0.82, 0.35, 0.20)
    end)

    return button
end

local function BuildLobbyText()
    if not AA.Lobby then
        return L("lobbyUnavailable")
    end

    local lobby = AA.Lobby:GetState()

    if not lobby.active then
        return L("noLobbyHint")
    end

    local lines = {}
    table.insert(lines, L("lobbyHost", AA:ShortName(lobby.host or "?")))
    table.insert(lines, "")

    local names = {}
    for name in pairs(lobby.players or {}) do
        table.insert(names, name)
    end
    table.sort(names)

    for _, name in ipairs(names) do
        local player = lobby.players[name]
        local readyMark = player.ready and "|cff00ff00" .. L("ready") .. "|r" or "|cffff0000" .. L("notReady") .. "|r"
        local team = AA.Game:GetTeamLabel(player.team)
        local role = AA.Lobby:GetRoleLabel(player.role)

        table.insert(lines, L("playerLine", AA:ShortName(name), team, role, readyMark))
    end

    return table.concat(lines, "\n")
end

local function RefreshButtons()
    local localPlayer = AA.Lobby and AA.Lobby:GetLocalPlayer() or nil
    local lobbyActive = AA.Lobby and AA.Lobby.IsActive and AA.Lobby:IsActive()

    if ui.createButton then
        ui.createButton:SetText(L("createLobby"))
        SetButtonEnabled(ui.createButton, not lobbyActive)
    end

    if ui.joinButton then
        ui.joinButton:SetText(L("joinLobby"))
        SetButtonEnabled(ui.joinButton, not lobbyActive)
    end

    if ui.leaveButton then
        ui.leaveButton:SetText(L("leaveLobby"))
        SetButtonEnabled(ui.leaveButton, lobbyActive)
    end

    if ui.readyButton then
        if localPlayer and localPlayer.ready then
            ui.readyButton:SetText(L("notReady"))
        else
            ui.readyButton:SetText(L("ready"))
        end

        SetButtonEnabled(ui.readyButton, lobbyActive)
    end

    if ui.launchButton then
        local canStart = AA.Lobby and AA.Lobby.CanStartMission and AA.Lobby:CanStartMission()
        SetButtonEnabled(ui.launchButton, canStart)
    end

    if ui.redButton then
        ui.redButton:SetText(L("red"))
        SetButtonEnabled(ui.redButton, lobbyActive and (not localPlayer or localPlayer.team ~= "RED"))
    end

    if ui.blueButton then
        ui.blueButton:SetText(L("blue"))
        SetButtonEnabled(ui.blueButton, lobbyActive and (not localPlayer or localPlayer.team ~= "BLUE"))
    end

    if ui.agentButton then
        ui.agentButton:SetText(L("agent"))
        SetButtonEnabled(ui.agentButton, lobbyActive and (not localPlayer or localPlayer.role ~= "AGENT"))
    end

    if ui.spyRoleButton then
        ui.spyRoleButton:SetText(L("spymasterShort"))
        SetButtonEnabled(ui.spyRoleButton, lobbyActive and (not localPlayer or localPlayer.role ~= "SPYMASTER"))
    end

    if ui.launchButton then
        ui.launchButton:SetText(L("launchMission"))
    end

    if ui.endTurnButton then
        ui.endTurnButton:SetText(L("endTurn"))
        SetButtonEnabled(ui.endTurnButton, AA.Game and AA.Game.CanLocalRevealCard and AA.Game:CanLocalRevealCard())
    end

    if ui.resetButton then
        ui.resetButton:SetText(L("reset"))
    end

    if ui.syncButton then
        ui.syncButton:SetText(L("resync"))
    end

    if ui.clueButton then
        ui.clueButton:SetText(L("clueButton"))
    end

    if ui.languageButton and AA.Locale then
        ui.languageButton:SetText(AA.Locale:GetModeLabel())
    end

    if ui.channelText and AA.Comm then
        local channel = AA.Comm:GetChannel()
        if channel then
            ui.channelText:SetText(L("channelLabel", channel))
        else
            ui.channelText:SetText(L("channelLocalNoGroup"))
        end
    end
end

local function RefreshStaticText()
    if ui.subtitle then
        ui.subtitle:SetText(L("subtitle"))
    end

    if ui.lobbyTitle then
        ui.lobbyTitle:SetText(L("lobbyTitle"))
    end

    if ui.missionTitle then
        ui.missionTitle:SetText(L("missionTitle"))
    end

    if ui.agentsTitle then
        ui.agentsTitle:SetText(L("agentsTitle"))
    end

    if ui.historyTitle then
        ui.historyTitle:SetText(L("historyTitle"))
    end

    if ui.clueInputLabel then
        ui.clueInputLabel:SetText(L("clueInputLabel"))
    end
end

function AA.UI:Init()
    if ui.frame then
        return
    end

    local frame = CreateFrame("Frame", "AzerothAgentsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(940, 760)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    ui.frame = frame

    ui.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    ui.title:SetPoint("TOP", 0, -3)
    ui.title:SetText("Azeroth Agents")

    ui.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.subtitle:SetPoint("TOP", 0, -34)
    ui.subtitle:SetText(L("subtitle"))

    ui.languageButton = CreateButton(frame, "", 36, 20, "TOPRIGHT", nil, nil, -20, -31, function()
        if AA.Locale then
            AA.Locale:CycleMode()
            AA.Words = AA.Locale:GetWords()
            if AA.Game and AA.Game.RefreshWords then
                AA.Game:RefreshWords()
            else
                AA.UI:Refresh()
            end
        end
    end)

    CreateDivider(frame, -55)

    ui.turnText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.turnText:SetPoint("TOPLEFT", 24, -66)
    ui.turnText:SetText(L("noActiveMission"))

    ui.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.status:SetPoint("TOPLEFT", 24, -87)
    ui.status:SetWidth(560)
    ui.status:SetJustifyH("LEFT")
    ui.status:SetText(L("initialGameMessage"))

    ui.boardFrame = CreateFrame("Frame", nil, frame)
    local boardSize = (AA.Game.GRID_SIZE * CARD_SIZE) + ((AA.Game.GRID_SIZE - 1) * CARD_GAP)
    ui.boardFrame:SetSize(boardSize, boardSize)
    ui.boardFrame:SetPoint("TOPLEFT", 24, -120)

    for row = 1, AA.Game.GRID_SIZE do
        for col = 1, AA.Game.GRID_SIZE do
            local index = ((row - 1) * AA.Game.GRID_SIZE) + col
            local card = CreateCard(ui.boardFrame, index)

            card:SetPoint(
                "TOPLEFT",
                (col - 1) * (CARD_SIZE + CARD_GAP),
                -((row - 1) * (CARD_SIZE + CARD_GAP))
            )

            ui.cards[index] = card
        end
    end

    ui.lobbyTitle = CreatePanelTitle(frame, L("lobbyTitle"), SIDE_PANEL_X, -70)

    ui.lobbyStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.lobbyStatus:SetPoint("TOPLEFT", SIDE_PANEL_X, -92)
    ui.lobbyStatus:SetWidth(SIDE_PANEL_WIDTH)
    ui.lobbyStatus:SetJustifyH("LEFT")
    ui.lobbyStatus:SetText(L("noLobby"))

    ui.createButton = CreateButton(frame, L("createLobby"), LOBBY_ACTION_WIDTH, 26, "TOPLEFT", nil, nil, SIDE_PANEL_X, -130, function()
        AA.Lobby:Create()
    end)

    ui.joinButton = CreateButton(frame, L("joinLobby"), LOBBY_ACTION_WIDTH, 26, "LEFT", ui.createButton, "RIGHT", LOBBY_BUTTON_GAP, 0, function()
        AA.Lobby:Join()
    end)

    ui.leaveButton = CreateButton(frame, L("leaveLobby"), LOBBY_ACTION_WIDTH, 26, "TOPLEFT", ui.createButton, "BOTTOMLEFT", 0, -6, function()
        AA.Lobby:Leave()
    end)

    ui.readyButton = CreateButton(frame, L("ready"), LOBBY_ACTION_WIDTH, 26, "LEFT", ui.leaveButton, "RIGHT", LOBBY_BUTTON_GAP, 0, function()
        AA.Lobby:ToggleReady()
    end)

    ui.redButton = CreateButton(frame, L("red"), LOBBY_ACTION_WIDTH, 24, "TOPLEFT", ui.leaveButton, "BOTTOMLEFT", 0, -16, function()
        AA.Lobby:SetTeam("RED")
    end)

    ui.blueButton = CreateButton(frame, L("blue"), LOBBY_ACTION_WIDTH, 24, "LEFT", ui.redButton, "RIGHT", LOBBY_BUTTON_GAP, 0, function()
        AA.Lobby:SetTeam("BLUE")
    end)

    ui.spyRoleButton = CreateButton(frame, L("spymasterShort"), LOBBY_ACTION_WIDTH, 24, "TOPLEFT", ui.redButton, "BOTTOMLEFT", 0, -4, function()
        AA.Lobby:SetRole("SPYMASTER")
    end)

    ui.agentButton = CreateButton(frame, L("agent"), LOBBY_ACTION_WIDTH, 24, "LEFT", ui.spyRoleButton, "RIGHT", LOBBY_BUTTON_GAP, 0, function()
        AA.Lobby:SetRole("AGENT")
    end)

    ui.launchButton = CreateButton(frame, L("launchMission"), LOBBY_LAUNCH_WIDTH, 28, "TOPLEFT", ui.spyRoleButton, "BOTTOMLEFT", 0, -6, function()
        AA.Lobby:StartMission()
    end)

    CreateDivider(frame, -302, 610, -30)
    ui.missionTitle = CreatePanelTitle(frame, L("missionTitle"), 610, -319)

    ui.endTurnButton = CreateButton(frame, L("endTurn"), 120, 26, "TOPLEFT", nil, nil, 610, -347, function()
        AA.Game:EndTurn(true)
    end)

    ui.resetButton = CreateButton(frame, L("reset"), 80, 26, "LEFT", ui.endTurnButton, "RIGHT", 8, 0, function()
        AA.Game:Reset(true)
    end)

    ui.syncButton = CreateButton(frame, L("resync"), 90, 26, "LEFT", ui.resetButton, "RIGHT", 8, 0, function()
        AA.Lobby:RequestResync()
    end)

    ui.clueText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.clueText:SetPoint("TOPLEFT", 610, -381)
    ui.clueText:SetWidth(300)
    ui.clueText:SetJustifyH("LEFT")
    ui.clueText:SetText(L("noActiveClue"))

    ui.clueInputLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.clueInputLabel:SetPoint("TOPLEFT", 610, -409)
    ui.clueInputLabel:SetWidth(300)
    ui.clueInputLabel:SetJustifyH("LEFT")
    ui.clueInputLabel:SetText(L("clueInputLabel"))

    ui.clueEdit = CreateEditBox(frame, 156, 24, "TOPLEFT", nil, nil, 610, -431)
    ui.clueEdit:SetMaxLetters(24)

    ui.clueNumberEdit = CreateEditBox(frame, 42, 24, "LEFT", ui.clueEdit, "RIGHT", 8, 0)
    ui.clueNumberEdit:SetMaxLetters(2)
    if ui.clueNumberEdit.SetNumeric then
        ui.clueNumberEdit:SetNumeric(true)
    end

    ui.clueButton = CreateButton(frame, L("clueButton"), 86, 24, "LEFT", ui.clueNumberEdit, "RIGHT", 8, 0, function()
        local word = ui.clueEdit:GetText()
        local number = ui.clueNumberEdit:GetText()

        if AA.Game:SubmitClue(word, number, true) then
            ui.clueEdit:SetText("")
            ui.clueNumberEdit:SetText("")
            ui.clueEdit:ClearFocus()
            ui.clueNumberEdit:ClearFocus()
        end
    end)

    ui.channelText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.channelText:SetPoint("TOPLEFT", 610, -477)
    ui.channelText:SetWidth(SIDE_PANEL_WIDTH)
    ui.channelText:SetJustifyH("LEFT")
    ui.channelText:SetText(L("channelLocal"))

    CreateDivider(frame, -507, 610, -30)
    ui.agentsTitle = CreatePanelTitle(frame, L("agentsTitle"), 610, -525)

    ui.lobbyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.lobbyText:SetPoint("TOPLEFT", 610, -549)
    ui.lobbyText:SetWidth(300)
    ui.lobbyText:SetJustifyH("LEFT")
    ui.lobbyText:SetJustifyV("TOP")
    ui.lobbyText:SetText(BuildLobbyText())

    CreateDivider(frame, -610, 610, -30)
    ui.historyTitle = CreatePanelTitle(frame, L("historyTitle"), 610, -628)

    ui.historyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.historyText:SetPoint("TOPLEFT", 610, -652)
    ui.historyText:SetWidth(300)
    ui.historyText:SetJustifyH("LEFT")
    ui.historyText:SetJustifyV("TOP")
    ui.historyText:SetText(L("noHistory"))

    ui.statsText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.statsText:SetPoint("BOTTOM", 0, 14)
    ui.statsText:SetText(L("versionText", AA.version or "0.4.3"))

    self:Refresh()
end

function AA.UI:Refresh()
    if not ui.frame then
        return
    end

    local game = AA.Game:GetState()
    local redLeft = AA.Game:CountRemaining("RED")
    local blueLeft = AA.Game:CountRemaining("BLUE")

    if game.phase == "PLAYING" then
        ui.turnText:SetText(L("turnSummary", AA.Game:GetTeamLabel(game.turn), redLeft, blueLeft))
    elseif game.phase == "ENDED" then
        ui.turnText:SetText(L("missionEnded", redLeft, blueLeft))
    else
        ui.turnText:SetText(L("noActiveMission"))
    end

    ui.status:SetText(game.message or "")

    if AA.Lobby then
        local lobby = AA.Lobby:GetState()
        ui.lobbyStatus:SetText(lobby.message or L("noLobby"))
        ui.lobbyText:SetText(BuildLobbyText())
    end

    RefreshStaticText()

    SetRegionShown(ui.boardFrame, game.phase ~= "LOBBY")

    local showLobbySetup = game.phase ~= "PLAYING"
    SetRegionShown(ui.createButton, showLobbySetup)
    SetRegionShown(ui.joinButton, showLobbySetup)
    SetRegionShown(ui.leaveButton, true)
    SetRegionShown(ui.readyButton, showLobbySetup)
    SetRegionShown(ui.redButton, showLobbySetup)
    SetRegionShown(ui.blueButton, showLobbySetup)
    SetRegionShown(ui.agentButton, showLobbySetup)
    SetRegionShown(ui.spyRoleButton, showLobbySetup)
    SetRegionShown(ui.launchButton, showLobbySetup)
    SetRegionShown(ui.endTurnButton, game.phase == "PLAYING")
    SetRegionShown(ui.resetButton, game.phase == "ENDED")
    SetRegionShown(ui.syncButton, true)

    if ui.clueText then
        ui.clueText:SetText(AA.Game:GetCurrentClueText())
    end

    local showCurrentClue = game.phase == "PLAYING"
    local showClueInput = showCurrentClue and AA.Game:CanLocalSubmitClue()
    SetRegionShown(ui.clueText, showCurrentClue)
    SetRegionShown(ui.clueInputLabel, showClueInput)
    SetRegionShown(ui.clueEdit, showClueInput)
    SetRegionShown(ui.clueNumberEdit, showClueInput)
    SetRegionShown(ui.clueButton, showClueInput)

    if not showClueInput then
        if ui.clueEdit then
            ui.clueEdit:ClearFocus()
        end

        if ui.clueNumberEdit then
            ui.clueNumberEdit:ClearFocus()
        end
    end

    if ui.historyText then
        ui.historyText:SetText(AA.Game:GetHistoryText())
    end

    RefreshButtons()

    local canSeeIdentities = AA.Game:CanSeeIdentities()
    local canRevealCard = AA.Game:CanLocalRevealCard()

    for index, button in ipairs(ui.cards) do
        local card = game.board[index]

        if not card then
            ApplyColor(button.bg, TYPE_COLORS.EMPTY)
            button.text:SetText(L("classified"))
            SetFontColor(button.text, TYPE_TEXT_COLORS.HIDDEN)
            button:Disable()
        else
            if card.revealed or not canRevealCard then
                button:Disable()
            else
                button:Enable()
            end

            local visibleType = card.revealed or canSeeIdentities
            local color = visibleType and TYPE_COLORS[card.type] or TYPE_COLORS.HIDDEN
            ApplyColor(button.bg, color)

            if canSeeIdentities and not card.revealed then
                button.text:SetText(card.word .. "\n|cffffd100" .. AA.Game:GetTypeLabel(card.type) .. "|r")
            elseif card.revealed then
                button.text:SetText(card.word .. "\n|cffffd100" .. AA.Game:GetTypeLabel(card.type) .. "|r")
            else
                button.text:SetText(card.word)
            end

            if visibleType then
                SetFontColor(button.text, TYPE_TEXT_COLORS[card.type])
            else
                SetFontColor(button.text, TYPE_TEXT_COLORS.HIDDEN)
            end
        end
    end
end

function AA.UI:Show()
    if not ui.frame then
        self:Init()
    end

    ui.frame:Show()
    self:Refresh()
end

function AA.UI:Hide()
    if ui.frame then
        ui.frame:Hide()
    end
end

function AA.UI:Toggle()
    if not ui.frame then
        self:Init()
    end

    ui.frame:SetShown(not ui.frame:IsShown())
    self:Refresh()
end
