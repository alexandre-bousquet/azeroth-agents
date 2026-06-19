local addonName, AA = ...

AA.Game = {}

local GRID_SIZE = 5
local CARD_COUNT = GRID_SIZE * GRID_SIZE
local RNG_MOD = 2147483647
local RNG_MULT = 48271

local TYPE_LABELS = {
    RED = "Rouge",
    BLUE = "Bleu",
    NEUTRAL = "Neutre",
    ASSASSIN = "Assassin"
}

local state = {
    phase = "LOBBY",
    board = {},
    turn = "RED",
    startTeam = "RED",
    spyMode = false,
    message = "Dossier SI:7 en attente. Crée ou rejoins un lobby.",
    winner = nil,
    seed = nil
}

AA.Game.GRID_SIZE = GRID_SIZE
AA.Game.CARD_COUNT = CARD_COUNT
AA.Game.TYPE_LABELS = TYPE_LABELS

local function CopyArray(source)
    local result = {}

    for i = 1, #source do
        result[i] = source[i]
    end

    return result
end

local function NewRng(seed)
    local value = tonumber(seed) or 1
    value = math.floor(value) % RNG_MOD

    if value <= 0 then
        value = 1
    end

    return function(max)
        value = (value * RNG_MULT) % RNG_MOD

        if max then
            return (value % max) + 1
        end

        return value / RNG_MOD
    end
end

local function Shuffle(list, rng)
    for i = #list, 2, -1 do
        local j = rng(i)
        list[i], list[j] = list[j], list[i]
    end
end

local function GetTeamLabel(team)
    if team == "RED" then
        return "Rouge"
    end

    if team == "BLUE" then
        return "Bleu"
    end

    return team or "?"
end

local function SwapTurn()
    state.turn = state.turn == "RED" and "BLUE" or "RED"
end

local function GenerateSeed()
    local value = (time() or 1) + math.floor((GetTime() or 0) * 1000) + math.random(1, 999999)
    value = math.floor(value) % RNG_MOD

    if value <= 0 then
        value = value + 12345
    end

    return value
end

local function PickWords(rng)
    local pool = CopyArray(AA.Words or {})
    Shuffle(pool, rng)

    local selected = {}

    for i = 1, CARD_COUNT do
        selected[i] = pool[i] or ("MOT " .. i)
    end

    return selected
end

local function BuildTypes(rng)
    local startTeam = rng(2) == 1 and "RED" or "BLUE"
    local secondTeam = startTeam == "RED" and "BLUE" or "RED"
    local types = {}

    for _ = 1, 9 do
        table.insert(types, startTeam)
    end

    for _ = 1, 8 do
        table.insert(types, secondTeam)
    end

    for _ = 1, 7 do
        table.insert(types, "NEUTRAL")
    end

    table.insert(types, "ASSASSIN")
    Shuffle(types, rng)

    return types, startTeam
end

local function Refresh()
    if AA.UI and AA.UI.Refresh then
        AA.UI:Refresh()
    end
end

function AA.Game:Init()
    math.randomseed(time() + math.floor((GetTime() or 0) * 1000))
end

function AA.Game:GetState()
    return state
end

function AA.Game:GetTeamLabel(team)
    return GetTeamLabel(team)
end

function AA.Game:SetMessage(message)
    state.message = message
end

function AA.Game:Reset(shouldBroadcast)
    state.phase = "LOBBY"
    state.board = {}
    state.turn = "RED"
    state.startTeam = "RED"
    state.winner = nil
    state.seed = nil
    state.message = "Dossier SI:7 réinitialisé. Crée ou rejoins un lobby."

    if shouldBroadcast and AA.Comm then
        AA.Comm:Broadcast("RESET")
    end

    Refresh()
end

function AA.Game:NewGame(seed, shouldBroadcast)
    seed = tonumber(seed) or GenerateSeed()

    local rng = NewRng(seed)
    local words = PickWords(rng)
    local types, startTeam = BuildTypes(rng)

    state.phase = "PLAYING"
    state.board = {}
    state.startTeam = startTeam
    state.turn = startTeam
    state.winner = nil
    state.seed = seed
    state.message = "Mission lancée. L'équipe " .. GetTeamLabel(startTeam) .. " commence."

    for i = 1, CARD_COUNT do
        state.board[i] = {
            word = words[i],
            type = types[i],
            revealed = false
        }
    end

    if AA.DB and AA.DB.stats and shouldBroadcast then
        AA.DB.stats.gamesStarted = (AA.DB.stats.gamesStarted or 0) + 1
    end

    if shouldBroadcast and AA.Comm then
        AA.Comm:Broadcast("START", tostring(seed))
    end

    Refresh()
end

function AA.Game:ToggleSpyMode()
    state.spyMode = not state.spyMode

    if state.spyMode then
        state.message = "Vue maître-espion active localement. Les identités sont visibles."
    else
        state.message = "Vue agent active localement. Les identités sont masquées."
    end
end

function AA.Game:SetSpyMode(enabled)
    state.spyMode = enabled and true or false
end

function AA.Game:CanSeeIdentities()
    if state.spyMode then
        return true
    end

    if AA.Lobby and AA.Lobby.IsLocalSpymaster then
        return AA.Lobby:IsLocalSpymaster()
    end

    return false
end

function AA.Game:CountRemaining(cardType)
    local count = 0

    for _, card in ipairs(state.board) do
        if card.type == cardType and not card.revealed then
            count = count + 1
        end
    end

    return count
end

function AA.Game:EndTurn(shouldBroadcast)
    if state.phase ~= "PLAYING" then
        state.message = "Aucune mission active. Lance une nouvelle partie."
        Refresh()
        return
    end

    SwapTurn()
    state.message = "Tour passé. À l'équipe " .. GetTeamLabel(state.turn) .. "."

    if shouldBroadcast and AA.Comm then
        AA.Comm:Broadcast("ENDTURN")
    end

    Refresh()
end

function AA.Game:RevealCard(index, shouldBroadcast)
    index = tonumber(index)

    if state.phase ~= "PLAYING" then
        state.message = "Aucune mission active. Lance une nouvelle partie."
        Refresh()
        return
    end

    local card = state.board[index]

    if not card then
        return
    end

    if card.revealed then
        state.message = "Ce contact a déjà été révélé."
        Refresh()
        return
    end

    card.revealed = true

    if shouldBroadcast and AA.Comm then
        AA.Comm:Broadcast("REVEAL", tostring(index))
    end

    if card.type == "ASSASSIN" then
        state.phase = "ENDED"
        state.winner = state.turn == "RED" and "BLUE" or "RED"
        state.message = "Assassin révélé. L'équipe " .. GetTeamLabel(state.turn) .. " est compromise. Victoire " .. GetTeamLabel(state.winner) .. "."

        if AA.DB and AA.DB.stats and shouldBroadcast then
            AA.DB.stats.assassinReveals = (AA.DB.stats.assassinReveals or 0) + 1
        end

        Refresh()
        return
    end

    local redLeft = self:CountRemaining("RED")
    local blueLeft = self:CountRemaining("BLUE")

    if redLeft == 0 then
        state.phase = "ENDED"
        state.winner = "RED"
        state.message = "Tous les agents rouges sont exfiltrés. Victoire Rouge."

        if AA.DB and AA.DB.stats and shouldBroadcast then
            AA.DB.stats.redWins = (AA.DB.stats.redWins or 0) + 1
        end

        Refresh()
        return
    end

    if blueLeft == 0 then
        state.phase = "ENDED"
        state.winner = "BLUE"
        state.message = "Tous les agents bleus sont exfiltrés. Victoire Bleue."

        if AA.DB and AA.DB.stats and shouldBroadcast then
            AA.DB.stats.blueWins = (AA.DB.stats.blueWins or 0) + 1
        end

        Refresh()
        return
    end

    if card.type == state.turn then
        state.message = "Contact confirmé pour l'équipe " .. GetTeamLabel(state.turn) .. "."
    elseif card.type == "NEUTRAL" then
        SwapTurn()
        state.message = "Contact neutre. Tour de l'équipe " .. GetTeamLabel(state.turn) .. "."
    else
        SwapTurn()
        state.message = "Agent adverse révélé. Tour de l'équipe " .. GetTeamLabel(state.turn) .. "."
    end

    Refresh()
end
