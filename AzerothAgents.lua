local ADDON_NAME = ...

local AA = {}
local GRID_SIZE = 5
local CARD_COUNT = GRID_SIZE * GRID_SIZE
local CARD_SIZE = 105
local CARD_GAP = 8

local state = {
    phase = "LOBBY",
    board = {},
    turn = "RED",
    startTeam = "RED",
    spyMode = false,
    message = "Bienvenue dans Azeroth Agents."
}

local WORDS = {
    "PORTAIL", "MURLOC", "TITAN", "LUNE", "FORGE",
    "DRAGON", "RUNE", "ANCRE", "DAGUE", "BANQUE",
    "GOBELIN", "GLACE", "OMBRE", "TORCHE", "MAGE",
    "CRYPTE", "GRIFFON", "HORDE", "ALLIANCE", "TOTEM",
    "FEL", "NAGA", "ARCANE", "RELIQUE", "BATEAU",
    "SABRE", "MONTURE", "AUBERGE", "MARTEAU", "COURONNE",
    "ELFE", "ORC", "NAIN", "GNOME", "TROLL",
    "DRAENEI", "PANDAREN", "MORT", "VIE", "CHAOS",
    "PRÊTRE", "VOLEUR", "PALADIN", "CHASSEUR", "DÉMON",
    "LANCE", "BOUCLIER", "PRISON", "TEMPLE", "CAVERNE",
    "SABLE", "MER", "VOLCAN", "FLEUR", "CHAMPION",
    "BANNIÈRE", "BOSS", "DONJON", "RAID", "TRÉSOR"
}

local TYPE_LABELS = {
    RED = "Rouge",
    BLUE = "Bleu",
    NEUTRAL = "Neutre",
    ASSASSIN = "Assassin"
}

local TYPE_COLORS = {
    RED = { 0.75, 0.10, 0.10, 0.85 },
    BLUE = { 0.10, 0.30, 0.85, 0.85 },
    NEUTRAL = { 0.65, 0.55, 0.38, 0.85 },
    ASSASSIN = { 0.05, 0.05, 0.05, 0.90 },
    HIDDEN = { 0.12, 0.12, 0.12, 0.75 }
}

local ui = {
    frame = nil,
    status = nil,
    cards = {},
    spyCheck = nil,
    turnText = nil
}

local function CopyArray(source)
    local result = {}

    for i = 1, #source do
        result[i] = source[i]
    end

    return result
end

local function Shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

local function PickWords()
    local pool = CopyArray(WORDS)
    Shuffle(pool)

    local result = {}

    for i = 1, CARD_COUNT do
        result[i] = pool[i]
    end

    return result
end

local function BuildTypes()
    local startTeam = math.random(2) == 1 and "RED" or "BLUE"
    local otherTeam = startTeam == "RED" and "BLUE" or "RED"

    local types = {}

    for _ = 1, 9 do
        table.insert(types, startTeam)
    end

    for _ = 1, 8 do
        table.insert(types, otherTeam)
    end

    for _ = 1, 7 do
        table.insert(types, "NEUTRAL")
    end

    table.insert(types, "ASSASSIN")

    Shuffle(types)

    return types, startTeam
end

local function SetStatus(message)
    state.message = message

    if ui.status then
        ui.status:SetText(message)
    end
end

local function CountRemaining(cardType)
    local count = 0

    for _, card in ipairs(state.board) do
        if card.type == cardType and not card.revealed then
            count = count + 1
        end
    end

    return count
end

local function GetTeamLabel(team)
    if team == "RED" then
        return "Rouge"
    end

    if team == "BLUE" then
        return "Bleu"
    end

    return team
end

local function SwapTurn()
    state.turn = state.turn == "RED" and "BLUE" or "RED"
end

local function RefreshUI()
    if not ui.frame then
        return
    end

    if ui.turnText then
        local redLeft = CountRemaining("RED")
        local blueLeft = CountRemaining("BLUE")

        ui.turnText:SetText(
            "Tour : " .. GetTeamLabel(state.turn)
            .. "  |  Rouge : " .. redLeft
            .. "  |  Bleu : " .. blueLeft
        )
    end

    if ui.status then
        ui.status:SetText(state.message)
    end

    for index, button in ipairs(ui.cards) do
        local card = state.board[index]

        if card then
            local showIdentity = card.revealed or state.spyMode
            local color = showIdentity and TYPE_COLORS[card.type] or TYPE_COLORS.HIDDEN

            button.bg:SetColorTexture(color[1], color[2], color[3], color[4])

            if state.spyMode and not card.revealed then
                button:SetText(card.word .. "\n" .. TYPE_LABELS[card.type])
            else
                button:SetText(card.word)
            end

            if card.revealed then
                button:GetFontString():SetTextColor(1, 1, 1)
            else
                button:GetFontString():SetTextColor(0.95, 0.95, 0.95)
            end

            button:Enable()
        else
            button:SetText("")
            button:Disable()
        end
    end
end

function AA:NewGame()
    math.randomseed(time())

    local words = PickWords()
    local types, startTeam = BuildTypes()

    state.board = {}
    state.phase = "PLAYING"
    state.startTeam = startTeam
    state.turn = startTeam

    for i = 1, CARD_COUNT do
        state.board[i] = {
            word = words[i],
            type = types[i],
            revealed = false
        }
    end

    SetStatus("Nouvelle partie 5x5. L'équipe " .. GetTeamLabel(startTeam) .. " commence.")
    RefreshUI()
end

function AA:RevealCard(index)
    if state.phase ~= "PLAYING" then
        return
    end

    local card = state.board[index]

    if not card or card.revealed then
        return
    end

    card.revealed = true

    if card.type == "ASSASSIN" then
        state.phase = "ENDED"
        SetStatus("Assassin révélé ! L'équipe " .. GetTeamLabel(state.turn) .. " perd immédiatement.")
        RefreshUI()
        return
    end

    local redLeft = CountRemaining("RED")
    local blueLeft = CountRemaining("BLUE")

    if redLeft == 0 then
        state.phase = "ENDED"
        SetStatus("Victoire de l'équipe Rouge !")
        RefreshUI()
        return
    end

    if blueLeft == 0 then
        state.phase = "ENDED"
        SetStatus("Victoire de l'équipe Bleue !")
        RefreshUI()
        return
    end

    if card.type ~= state.turn then
        SwapTurn()
        SetStatus("Mauvais contact. Tour de l'équipe " .. GetTeamLabel(state.turn) .. ".")
    else
        SetStatus("Bon contact pour l'équipe " .. GetTeamLabel(state.turn) .. ".")
    end

    RefreshUI()
end

function AA:EndTurn()
    if state.phase ~= "PLAYING" then
        return
    end

    SwapTurn()
    SetStatus("Tour passé. À l'équipe " .. GetTeamLabel(state.turn) .. ".")
    RefreshUI()
end

function AA:CreateUI()
    local frame = CreateFrame("Frame", "AzerothAgentsFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(650, 690)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    ui.frame = frame

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Azeroth Agents")

    ui.turnText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.turnText:SetPoint("TOP", 0, -42)
    ui.turnText:SetText("Aucune partie lancée.")

    ui.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.status:SetPoint("TOP", 0, -66)
    ui.status:SetWidth(590)
    ui.status:SetJustifyH("CENTER")
    ui.status:SetText(state.message)

    local newGameButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newGameButton:SetSize(150, 28)
    newGameButton:SetPoint("TOPLEFT", 25, -95)
    newGameButton:SetText("Nouvelle 5x5")
    newGameButton:SetScript("OnClick", function()
        AA:NewGame()
    end)

    local endTurnButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    endTurnButton:SetSize(120, 28)
    endTurnButton:SetPoint("LEFT", newGameButton, "RIGHT", 12, 0)
    endTurnButton:SetText("Passer tour")
    endTurnButton:SetScript("OnClick", function()
        AA:EndTurn()
    end)

    ui.spyCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ui.spyCheck:SetPoint("LEFT", endTurnButton, "RIGHT", 20, 0)
    ui.spyCheck.text:SetText("Mode maître-espion")
    ui.spyCheck:SetScript("OnClick", function(self)
        state.spyMode = self:GetChecked()
        RefreshUI()
    end)

    local boardFrame = CreateFrame("Frame", nil, frame)
    boardFrame:SetSize(
        GRID_SIZE * CARD_SIZE + (GRID_SIZE - 1) * CARD_GAP,
        GRID_SIZE * CARD_SIZE + (GRID_SIZE - 1) * CARD_GAP
    )
    boardFrame:SetPoint("TOP", 0, -145)

    for row = 1, GRID_SIZE do
        for col = 1, GRID_SIZE do
            local index = ((row - 1) * GRID_SIZE) + col

            local button = CreateFrame("Button", nil, boardFrame, "UIPanelButtonTemplate")
            button:SetSize(CARD_SIZE, CARD_SIZE)
            button:SetPoint(
                "TOPLEFT",
                (col - 1) * (CARD_SIZE + CARD_GAP),
                -((row - 1) * (CARD_SIZE + CARD_GAP))
            )

            button.bg = button:CreateTexture(nil, "BACKGROUND")
            button.bg:SetAllPoints(button)
            button.bg:SetColorTexture(0.12, 0.12, 0.12, 0.75)

            button:SetText("")
            button:GetFontString():SetWidth(CARD_SIZE - 12)
            button:GetFontString():SetWordWrap(true)
            button:GetFontString():SetJustifyH("CENTER")
            button:GetFontString():SetJustifyV("MIDDLE")

            button:SetScript("OnClick", function()
                AA:RevealCard(index)
            end)

            ui.cards[index] = button
        end
    end

    RefreshUI()
end

function AA:Toggle()
    if not ui.frame then
        AA:CreateUI()
    end

    ui.frame:SetShown(not ui.frame:IsShown())
end

SLASH_AZEROTHAGENTS1 = "/aa"
SLASH_AZEROTHAGENTS2 = "/agents"

SlashCmdList["AZEROTHAGENTS"] = function()
    AA:Toggle()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        AA:CreateUI()
        print("|cff00ff00Azeroth Agents chargé.|r Tape /aa pour ouvrir l'interface.")
    end
end)