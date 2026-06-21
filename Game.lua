local addonName, AA = ...

AA.Game = {}

local GRID_SIZE = 5
local CARD_COUNT = GRID_SIZE * GRID_SIZE
local RNG_MOD = 2147483647
local RNG_MULT = 48271
local HISTORY_LIMIT = 12

local TYPE_LABELS = {
    RED = "RED",
    BLUE = "BLUE",
    NEUTRAL = "NEUTRAL",
    ASSASSIN = "ASSASSIN"
}

local state = {
    phase = "LOBBY",
    board = {},
    turn = "RED",
    startTeam = "RED",
    message = nil,
    messageKey = nil,
    messageArgs = nil,
    winner = nil,
    seed = nil,
    history = {},
    currentClue = nil
}

AA.Game.GRID_SIZE = GRID_SIZE
AA.Game.CARD_COUNT = CARD_COUNT
AA.Game.TYPE_LABELS = TYPE_LABELS

local function CopyArray(source)
    local result = {}

    for i = 1, #(source or {}) do
        result[i] = source[i]
    end

    return result
end

local function L(key, ...)
    if AA.Locale then
        return AA.Locale:T(key, ...)
    end

    return key
end

local function ResolveMessageArg(arg)
    if type(arg) == "function" then
        return arg()
    end

    return arg
end

local function FormatMessage(key, args)
    args = args or {}
    local resolved = {}

    for i = 1, #args do
        resolved[i] = ResolveMessageArg(args[i])
    end

    if #resolved == 0 then
        return L(key)
    end

    if #resolved == 1 then
        return L(key, resolved[1])
    end

    if #resolved == 2 then
        return L(key, resolved[1], resolved[2])
    end

    return L(key, resolved[1], resolved[2], resolved[3])
end

local function SetMessage(key, ...)
    local args = { ... }

    state.messageKey = key
    state.messageArgs = args
    state.message = FormatMessage(key, args)
end

local function SetRawMessage(message)
    state.messageKey = nil
    state.messageArgs = nil
    state.message = message
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
        return L("teamRed")
    end

    if team == "BLUE" then
        return L("teamBlue")
    end

    return team or "?"
end

local function SwapTurn()
    state.turn = state.turn == "RED" and "BLUE" or "RED"
end

local function GetSeedTime()
    local value = 1

    if type(time) == "function" then
        value = time() or value
    elseif type(GetServerTime) == "function" then
        value = GetServerTime() or value
    end

    if type(GetTime) == "function" then
        value = value + math.floor((GetTime() or 0) * 1000)
    end

    return value
end

local function GetSeedJitter(value)
    if math.random then
        return math.random(1, 999999)
    end

    return ((value * RNG_MULT) % 999999) + 1
end

local function GenerateSeed()
    local seedTime = GetSeedTime()
    local value = seedTime + GetSeedJitter(seedTime)
    value = math.floor(value) % RNG_MOD

    if value <= 0 then
        value = value + 12345
    end

    return value
end

local function PickWords(rng)
    local source = AA.Locale and AA.Locale:GetWords() or AA.Words or {}
    local pool = {}

    for i = 1, #source do
        pool[i] = {
            index = i,
            word = source[i]
        }
    end

    Shuffle(pool, rng)

    local selected = {}

    for i = 1, CARD_COUNT do
        selected[i] = pool[i] or {
            index = i,
            word = "WORD " .. i
        }
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

local function BuildBoard(seed)
    local rng = NewRng(seed)
    local words = PickWords(rng)
    local types, startTeam = BuildTypes(rng)
    local board = {}

    for i = 1, CARD_COUNT do
        board[i] = {
            word = words[i].word,
            wordIndex = words[i].index,
            type = types[i],
            revealed = false
        }
    end

    return board, startTeam
end

local function RefreshBoardWords()
    if not state.seed or not state.board then
        return
    end

    local source = AA.Locale and AA.Locale:GetWords() or AA.Words or {}
    local missingIndexes = false

    for i = 1, CARD_COUNT do
        local card = state.board[i]

        if card and not card.wordIndex then
            missingIndexes = true
            break
        end
    end

    if missingIndexes then
        local rng = NewRng(state.seed)
        local words = PickWords(rng)

        for i = 1, CARD_COUNT do
            local card = state.board[i]

            if card and words[i] then
                card.wordIndex = words[i].index
                card.word = words[i].word
            end
        end

        return
    end

    for i = 1, CARD_COUNT do
        local card = state.board[i]

        if card then
            card.word = source[card.wordIndex] or card.word
        end
    end
end

local function Refresh()
    if AA.UI and AA.UI.Refresh then
        AA.UI:Refresh()
    end
end

local function GetRevealedMask()
    local mask = {}

    for i = 1, CARD_COUNT do
        local card = state.board[i]
        mask[i] = card and card.revealed and "1" or "0"
    end

    return table.concat(mask)
end

local function ApplyRevealedMask(mask)
    mask = tostring(mask or "")

    for i = 1, CARD_COUNT do
        if state.board[i] then
            state.board[i].revealed = string.sub(mask, i, i) == "1"
        end
    end
end

local function SaveSnapshot()
    if not AA.DB then
        return
    end

    if state.phase == "LOBBY" and not state.seed then
        AA.DB.lastGame = nil
        return
    end

    AA.DB.lastGame = {
        phase = state.phase,
        seed = state.seed,
        turn = state.turn,
        startTeam = state.startTeam,
        winner = state.winner,
        revealed = GetRevealedMask(),
        history = CopyArray(state.history),
        currentClue = state.currentClue and {
            word = state.currentClue.word,
            number = state.currentClue.number,
            team = state.currentClue.team,
            sender = state.currentClue.sender
        } or nil
    }
end

local function AddHistoryLine(line)
    line = tostring(line or "")

    if line == "" then
        return
    end

    table.insert(state.history, 1, line)

    while #state.history > HISTORY_LIMIT do
        table.remove(state.history)
    end
end

function AA.Game:Init()
    if math.randomseed then
        math.randomseed(GetSeedTime())
    end

    if not state.message and not state.messageKey then
        SetMessage("initialGameMessage")
    end

    self:LoadSnapshot()
end

function AA.Game:GetState()
    return state
end

function AA.Game:GetTypeLabel(cardType)
    if cardType == "RED" then
        return L("typeRed")
    end

    if cardType == "BLUE" then
        return L("typeBlue")
    end

    if cardType == "NEUTRAL" then
        return L("typeNeutral")
    end

    if cardType == "ASSASSIN" then
        return L("typeAssassin")
    end

    return cardType or "?"
end

function AA.Game:GetTeamLabel(team)
    return GetTeamLabel(team)
end

function AA.Game:RefreshWords()
    RefreshBoardWords()
    Refresh()
end

function AA.Game:SetMessage(message)
    SetRawMessage(message)
end

function AA.Game:SetMessageKey(key, ...)
    SetMessage(key, ...)
end

function AA.Game:GetMessage()
    if state.messageKey then
        return FormatMessage(state.messageKey, state.messageArgs)
    end

    return state.message or L("initialGameMessage")
end

function AA.Game:GetCurrentClueText()
    local clue = state.currentClue

    if not clue or not clue.word or clue.word == "" then
        return L("noActiveClue")
    end

    return L("clueText", GetTeamLabel(clue.team), clue.word, tostring(clue.number or "?"))
end

function AA.Game:GetHistoryText()
    if not state.history or #state.history == 0 then
        return L("noHistory")
    end

    local lines = {}

    for i = 1, math.min(#state.history, 7) do
        table.insert(lines, state.history[i])
    end

    return table.concat(lines, "\n")
end

function AA.Game:SaveSnapshot()
    SaveSnapshot()
end

function AA.Game:LoadSnapshot()
    local saved = AA.DB and AA.DB.lastGame

    if not saved or not saved.seed then
        return false
    end

    state.seed = tonumber(saved.seed)
    state.board, state.startTeam = BuildBoard(state.seed)
    state.phase = saved.phase or "PLAYING"
    state.turn = saved.turn or state.startTeam or "RED"
    state.startTeam = saved.startTeam or state.startTeam or "RED"
    state.winner = saved.winner
    state.history = CopyArray(saved.history or {})
    state.currentClue = saved.currentClue

    ApplyRevealedMask(saved.revealed or "")

    SetMessage("localCacheRestored")
    return true
end

function AA.Game:Reset(shouldBroadcast)
    state.phase = "LOBBY"
    state.board = {}
    state.turn = "RED"
    state.startTeam = "RED"
    state.winner = nil
    state.seed = nil
    state.history = {}
    state.currentClue = nil
    SetMessage("resetMessage")

    if AA.DB then
        AA.DB.lastGame = nil
    end

    if shouldBroadcast and AA.Comm then
        AA.Comm:Broadcast("RESET")
    end

    Refresh()
end

function AA.Game:NewGame(seed, shouldBroadcast)
    seed = tonumber(seed) or GenerateSeed()

    state.seed = seed
    state.board, state.startTeam = BuildBoard(seed)
    state.phase = "PLAYING"
    state.turn = state.startTeam
    state.winner = nil
    state.history = {}
    state.currentClue = nil
    SetMessage("missionStarted", function()
        return GetTeamLabel(state.startTeam)
    end)

    AddHistoryLine(L("missionOpenedHistory", GetTeamLabel(state.startTeam)))

    if AA.DB and AA.DB.stats and shouldBroadcast then
        AA.DB.stats.gamesStarted = (AA.DB.stats.gamesStarted or 0) + 1
    end

    SaveSnapshot()

    if shouldBroadcast and AA.Comm then
        AA.Comm:Broadcast("START", tostring(seed))
    end

    Refresh()
end

function AA.Game:CanSeeIdentities()
    if AA.Lobby and AA.Lobby.IsLocalSpymaster then
        return AA.Lobby:IsLocalSpymaster()
    end

    return false
end

function AA.Game:CanLocalRevealCard()
    if state.phase ~= "PLAYING" then
        return false
    end

    if AA.Lobby and AA.Lobby.IsLocalTurnAgent then
        return AA.Lobby:IsLocalTurnAgent(state.turn)
    end

    return false
end

function AA.Game:CanLocalSubmitClue()
    if state.phase ~= "PLAYING" then
        return false
    end

    if AA.Lobby and AA.Lobby.IsLocalTurnSpymaster then
        return AA.Lobby:IsLocalTurnSpymaster(state.turn)
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
        SetMessage("noActiveMissionStart")
        Refresh()
        return
    end

    if shouldBroadcast and not self:CanLocalRevealCard() then
        SetMessage("endTurnOnlyActiveAgents")
        Refresh()
        return
    end

    SwapTurn()
    SetMessage("turnPassed", function()
        return GetTeamLabel(state.turn)
    end)
    AddHistoryLine(L("turnPassedHistory", GetTeamLabel(state.turn)))
    SaveSnapshot()

    if shouldBroadcast and AA.Comm then
        AA.Comm:Broadcast("ENDTURN")
    end

    Refresh()
end

function AA.Game:SubmitClue(word, number, shouldBroadcast)
    word = tostring(word or "")
    word = string.gsub(word, "^%s+", "")
    word = string.gsub(word, "%s+$", "")
    number = tonumber(number)

    if state.phase ~= "PLAYING" then
        SetMessage("noMissionForClue")
        Refresh()
        return false
    end

    if shouldBroadcast and not self:CanLocalSubmitClue() then
        SetMessage("clueOnlyActiveSpymaster")
        Refresh()
        return false
    end

    if word == "" or not number then
        SetMessage("invalidClue")
        Refresh()
        return false
    end

    self:SetClue(word, number, shouldBroadcast, AA.localPlayer or AA:GetPlayerName(), state.turn)
    return true
end

function AA.Game:SetClue(word, number, shouldBroadcast, sender, team)
    word = tostring(word or "")
    number = tonumber(number) or tostring(number or "?")
    team = team or state.turn

    state.currentClue = {
        word = word,
        number = number,
        team = team,
        sender = sender
    }

    SetMessage("clueMessage", function()
        return GetTeamLabel(team)
    end, word, tostring(number))
    AddHistoryLine(L("clueHistory", GetTeamLabel(team), word, tostring(number)))
    SaveSnapshot()

    if shouldBroadcast and AA.Comm then
        AA.Comm:Broadcast("CLUE", word, tostring(number), team)
    end

    Refresh()
end

function AA.Game:RevealCard(index, shouldBroadcast)
    index = tonumber(index)

    if state.phase ~= "PLAYING" then
        SetMessage("noActiveMissionStart")
        Refresh()
        return
    end

    if shouldBroadcast and not self:CanLocalRevealCard() then
        SetMessage("revealOnlyActiveAgents")
        Refresh()
        return
    end

    local card = state.board[index]

    if not card then
        return
    end

    if card.revealed then
        SetMessage("cardAlreadyRevealed")
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
        SetMessage("assassinRevealed", function()
            return GetTeamLabel(state.turn)
        end, function()
            return GetTeamLabel(state.winner)
        end)
        AddHistoryLine(L("assassinHistory", card.word, GetTeamLabel(state.winner)))

        if AA.DB and AA.DB.stats and shouldBroadcast then
            AA.DB.stats.assassinReveals = (AA.DB.stats.assassinReveals or 0) + 1
        end

        SaveSnapshot()
        Refresh()
        return
    end

    local redLeft = self:CountRemaining("RED")
    local blueLeft = self:CountRemaining("BLUE")

    if redLeft == 0 then
        state.phase = "ENDED"
        state.winner = "RED"
        SetMessage("redWin")
        AddHistoryLine(L("redWinHistory", card.word))

        if AA.DB and AA.DB.stats and shouldBroadcast then
            AA.DB.stats.redWins = (AA.DB.stats.redWins or 0) + 1
        end

        SaveSnapshot()
        Refresh()
        return
    end

    if blueLeft == 0 then
        state.phase = "ENDED"
        state.winner = "BLUE"
        SetMessage("blueWin")
        AddHistoryLine(L("blueWinHistory", card.word))

        if AA.DB and AA.DB.stats and shouldBroadcast then
            AA.DB.stats.blueWins = (AA.DB.stats.blueWins or 0) + 1
        end

        SaveSnapshot()
        Refresh()
        return
    end

    if card.type == state.turn then
        SetMessage("contactConfirmed", function()
            return GetTeamLabel(state.turn)
        end)
        AddHistoryLine(L("contactHistory", card.word, GetTeamLabel(card.type)))
    elseif card.type == "NEUTRAL" then
        SwapTurn()
        SetMessage("neutralRevealed", function()
            return GetTeamLabel(state.turn)
        end)
        AddHistoryLine(L("neutralHistory", card.word, GetTeamLabel(state.turn)))
    else
        SwapTurn()
        SetMessage("opponentRevealed", function()
            return GetTeamLabel(state.turn)
        end)
        AddHistoryLine(L("opponentHistory", card.word, GetTeamLabel(card.type), GetTeamLabel(state.turn)))
    end

    SaveSnapshot()
    Refresh()
end

function AA.Game:SendSync(target)
    if not AA.Comm then
        return false
    end

    local clue = state.currentClue or {}

    AA.Comm:Send(target, "SYNCSTATE",
        tostring(state.seed or ""),
        state.phase or "LOBBY",
        state.turn or "RED",
        state.startTeam or "RED",
        state.winner or "",
        GetRevealedMask(),
        clue.word or "",
        tostring(clue.number or ""),
        clue.team or "",
        clue.sender or ""
    )

    local total = #state.history

    for i = total, 1, -1 do
        AA.Comm:Send(target, "SYNCLOG", tostring(i), tostring(total), state.history[i])
    end

    return true
end

function AA.Game:ApplySync(args, sender)
    local seed = tonumber(args[1])
    local phase = args[2] or "LOBBY"

    if seed then
        state.seed = seed
        state.board, state.startTeam = BuildBoard(seed)
    else
        state.seed = nil
        state.board = {}
    end

    state.phase = phase
    state.turn = args[3] or state.turn or "RED"
    state.startTeam = args[4] or state.startTeam or "RED"
    state.winner = args[5] ~= "" and args[5] or nil
    ApplyRevealedMask(args[6] or "")

    if args[7] and args[7] ~= "" then
        state.currentClue = {
            word = args[7],
            number = args[8],
            team = args[9],
            sender = args[10]
        }
    else
        state.currentClue = nil
    end

    state.history = {}
    SetMessage("resyncReceived", AA:ShortName(sender))
    SaveSnapshot()
    Refresh()
end

function AA.Game:ApplySyncLog(index, total, line)
    index = tonumber(index)
    total = tonumber(total)

    if not index or not total or not line then
        return
    end

    state.history[index] = line

    while #state.history > HISTORY_LIMIT do
        table.remove(state.history)
    end

    SaveSnapshot()
    Refresh()
end
