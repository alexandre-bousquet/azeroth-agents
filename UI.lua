local addonName, AA = ...

AA.UI = {}

local CARD_SIZE = 104
local CARD_GAP = 8

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
    status = nil,
    turnText = nil,
    spyCheck = nil,
    cards = {},
    statsText = nil,
    lobbyText = nil,
    lobbyStatus = nil,
    readyButton = nil,
    launchButton = nil,
    channelText = nil
}

local function ApplyColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4])
end

local function SetFontColor(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3])
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
        return "Lobby indisponible."
    end

    local lobby = AA.Lobby:GetState()

    if not lobby.active then
        return "Aucun lobby actif.\n\nCrée un lobby ou rejoins celui du groupe."
    end

    local lines = {}
    table.insert(lines, "Hôte : " .. AA:ShortName(lobby.host or "?"))
    table.insert(lines, "")

    local names = {}
    for name in pairs(lobby.players or {}) do
        table.insert(names, name)
    end
    table.sort(names)

    for _, name in ipairs(names) do
        local player = lobby.players[name]
        local hostMark = name == lobby.host and "★ " or ""
        local readyMark = player.ready and "|cff00ff00✓|r" or "|cffff3333✗|r"
        local team = AA.Game:GetTeamLabel(player.team)
        local role = AA.Lobby:GetRoleLabel(player.role)

        table.insert(lines, hostMark .. AA:ShortName(name) .. " — " .. team .. " / " .. role .. " " .. readyMark)
    end

    return table.concat(lines, "\n")
end

local function RefreshButtons()
    local localPlayer = AA.Lobby and AA.Lobby:GetLocalPlayer() or nil

    if ui.readyButton then
        if localPlayer and localPlayer.ready then
            ui.readyButton:SetText("Pas prêt")
        else
            ui.readyButton:SetText("Prêt")
        end
    end

    if ui.launchButton then
        if AA.Lobby and AA.Lobby:IsHost() then
            ui.launchButton:Enable()
        else
            ui.launchButton:Disable()
        end
    end

    if ui.channelText and AA.Comm then
        local channel = AA.Comm:GetChannel()
        if channel then
            ui.channelText:SetText("Canal addon : " .. channel)
        else
            ui.channelText:SetText("Canal addon : local, aucun groupe")
        end
    end
end

function AA.UI:Init()
    if ui.frame then
        return
    end

    local frame = CreateFrame("Frame", "AzerothAgentsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(940, 705)
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

    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", 0, -34)
    subtitle:SetText("Dossier confidentiel — SI:7")

    CreateDivider(frame, -55)

    ui.turnText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.turnText:SetPoint("TOPLEFT", 24, -66)
    ui.turnText:SetText("Aucune mission active.")

    ui.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.status:SetPoint("TOPLEFT", 24, -87)
    ui.status:SetWidth(560)
    ui.status:SetJustifyH("LEFT")
    ui.status:SetText("Dossier SI:7 en attente. Crée ou rejoins un lobby.")

    local boardFrame = CreateFrame("Frame", nil, frame)
    local boardSize = (AA.Game.GRID_SIZE * CARD_SIZE) + ((AA.Game.GRID_SIZE - 1) * CARD_GAP)
    boardFrame:SetSize(boardSize, boardSize)
    boardFrame:SetPoint("TOPLEFT", 24, -120)

    for row = 1, AA.Game.GRID_SIZE do
        for col = 1, AA.Game.GRID_SIZE do
            local index = ((row - 1) * AA.Game.GRID_SIZE) + col
            local card = CreateCard(boardFrame, index)

            card:SetPoint(
                "TOPLEFT",
                (col - 1) * (CARD_SIZE + CARD_GAP),
                -((row - 1) * (CARD_SIZE + CARD_GAP))
            )

            ui.cards[index] = card
        end
    end

    CreatePanelTitle(frame, "Lobby groupe", 610, -70)

    ui.lobbyStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.lobbyStatus:SetPoint("TOPLEFT", 610, -92)
    ui.lobbyStatus:SetWidth(295)
    ui.lobbyStatus:SetJustifyH("LEFT")
    ui.lobbyStatus:SetText("Aucun lobby actif.")

    local createButton = CreateButton(frame, "Créer lobby", 132, 26, "TOPLEFT", nil, nil, 610, -130, function()
        AA.Lobby:Create()
    end)

    local joinButton = CreateButton(frame, "Rejoindre", 132, 26, "LEFT", createButton, "RIGHT", 10, 0, function()
        AA.Lobby:Join()
    end)

    local leaveButton = CreateButton(frame, "Quitter", 132, 26, "TOPLEFT", nil, nil, 610, -162, function()
        AA.Lobby:Leave()
    end)

    ui.readyButton = CreateButton(frame, "Prêt", 132, 26, "LEFT", leaveButton, "RIGHT", 10, 0, function()
        AA.Lobby:ToggleReady()
    end)

    local redButton = CreateButton(frame, "Rouge", 86, 24, "TOPLEFT", nil, nil, 610, -204, function()
        AA.Lobby:SetTeam("RED")
    end)

    local blueButton = CreateButton(frame, "Bleu", 86, 24, "LEFT", redButton, "RIGHT", 8, 0, function()
        AA.Lobby:SetTeam("BLUE")
    end)

    local agentButton = CreateButton(frame, "Agent", 86, 24, "LEFT", blueButton, "RIGHT", 8, 0, function()
        AA.Lobby:SetRole("AGENT")
    end)

    local spyRoleButton = CreateButton(frame, "Espion", 86, 24, "TOPLEFT", nil, nil, 610, -232, function()
        AA.Lobby:SetRole("SPYMASTER")
    end)

    ui.launchButton = CreateButton(frame, "Lancer mission", 178, 28, "LEFT", spyRoleButton, "RIGHT", 10, 0, function()
        AA.Lobby:StartMission()
    end)

    CreateDivider(frame, -275, 610, -30)
    CreatePanelTitle(frame, "Mission", 610, -292)

    local endTurnButton = CreateButton(frame, "Passer tour", 132, 26, "TOPLEFT", nil, nil, 610, -320, function()
        AA.Game:EndTurn(true)
    end)

    local resetButton = CreateButton(frame, "Reset", 132, 26, "LEFT", endTurnButton, "RIGHT", 10, 0, function()
        AA.Game:Reset(true)
    end)

    ui.spyCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ui.spyCheck:SetPoint("TOPLEFT", 604, -356)
    ui.spyCheck.text:SetText("Vue maître-espion locale")
    ui.spyCheck:SetScript("OnClick", function(self)
        AA.Game:SetSpyMode(self:GetChecked())
        AA.UI:Refresh()
    end)

    ui.channelText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.channelText:SetPoint("TOPLEFT", 610, -388)
    ui.channelText:SetWidth(295)
    ui.channelText:SetJustifyH("LEFT")
    ui.channelText:SetText("Canal addon : local")

    CreateDivider(frame, -420, 610, -30)
    CreatePanelTitle(frame, "Agents", 610, -438)

    ui.lobbyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.lobbyText:SetPoint("TOPLEFT", 610, -462)
    ui.lobbyText:SetWidth(300)
    ui.lobbyText:SetJustifyH("LEFT")
    ui.lobbyText:SetJustifyV("TOP")
    ui.lobbyText:SetText(BuildLobbyText())

    ui.statsText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.statsText:SetPoint("BOTTOM", 0, 14)
    ui.statsText:SetText("v" .. (AA.version or "0.2.3"))

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
        ui.turnText:SetText("Tour : " .. AA.Game:GetTeamLabel(game.turn) .. "  |  Rouge : " .. redLeft .. "  |  Bleu : " .. blueLeft)
    elseif game.phase == "ENDED" then
        ui.turnText:SetText("Mission terminée  |  Rouge : " .. redLeft .. "  |  Bleu : " .. blueLeft)
    else
        ui.turnText:SetText("Aucune mission active.")
    end

    ui.status:SetText(game.message or "")

    if AA.Lobby then
        local lobby = AA.Lobby:GetState()
        ui.lobbyStatus:SetText(lobby.message or "Aucun lobby actif.")
        ui.lobbyText:SetText(BuildLobbyText())
    end

    if ui.spyCheck then
        ui.spyCheck:SetChecked(game.spyMode)
    end

    RefreshButtons()

    local canSeeIdentities = AA.Game:CanSeeIdentities()

    for index, button in ipairs(ui.cards) do
        local card = game.board[index]

        if not card then
            ApplyColor(button.bg, TYPE_COLORS.EMPTY)
            button.text:SetText("CLASSIFIÉ")
            SetFontColor(button.text, TYPE_TEXT_COLORS.HIDDEN)
            button:Disable()
        else
            button:Enable()

            local visibleType = card.revealed or canSeeIdentities
            local color = visibleType and TYPE_COLORS[card.type] or TYPE_COLORS.HIDDEN
            ApplyColor(button.bg, color)

            if canSeeIdentities and not card.revealed then
                button.text:SetText(card.word .. "\n|cffffd100" .. AA.Game.TYPE_LABELS[card.type] .. "|r")
            elseif card.revealed then
                button.text:SetText(card.word .. "\n|cffffd100" .. AA.Game.TYPE_LABELS[card.type] .. "|r")
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
