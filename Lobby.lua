local addonName, AA = ...

AA.Lobby = {}

local ROLE_LABELS = {
    AGENT = "roleAgent",
    SPYMASTER = "roleSpymaster"
}

local state = {
    active = false,
    host = nil,
    players = {},
    message = nil,
    messageKey = nil,
    messageArgs = nil
}

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

local function CopyPlayers(source)
    local result = {}

    for name, player in pairs(source or {}) do
        result[name] = {
            name = player.name,
            team = player.team,
            role = player.role,
            ready = player.ready and true or false
        }
    end

    return result
end

local function SaveLobby()
    if not AA.DB then
        return
    end

    if not state.active then
        AA.DB.lastLobby = nil
        return
    end

    AA.DB.lastLobby = {
        active = state.active,
        host = state.host,
        players = CopyPlayers(state.players)
    }
end

local function Refresh()
    SaveLobby()

    if AA.UI and AA.UI.Refresh then
        AA.UI:Refresh()
    end
end

local function LocalName()
    return AA.localPlayer or AA:GetPlayerName()
end

local function EnsurePlayer(name)
    name = name or LocalName()

    if not state.players[name] then
        state.players[name] = {
            name = name,
            team = "BLUE",
            role = "AGENT",
            ready = false
        }
    end

    return state.players[name]
end

local function SendPlayer(name, target)
    local player = state.players[name]

    if not player or not AA.Comm then
        return
    end

    AA.Comm:Send(target, "PLAYER", player.name, player.team, player.role, player.ready and "1" or "0")
end

local function BroadcastPlayer(name)
    SendPlayer(name, nil)
end

local function CountPlayers()
    local count = 0

    for _ in pairs(state.players) do
        count = count + 1
    end

    return count
end

local function AllReady()
    local count = 0

    for _, player in pairs(state.players) do
        count = count + 1

        if not player.ready then
            return false, count
        end
    end

    return count > 0, count
end

local function HasSpymaster(team)
    for _, player in pairs(state.players) do
        if player.team == team and player.role == "SPYMASTER" then
            return true
        end
    end

    return false
end

local function HasGroupChannel()
    return AA.Comm and AA.Comm.GetChannel and AA.Comm:GetChannel() ~= nil
end

function AA.Lobby:Init()
    state.players = state.players or {}

    local saved = AA.DB and AA.DB.lastLobby

    if saved and saved.active then
        state.active = saved.active
        state.host = saved.host
        state.players = CopyPlayers(saved.players or {})
        SetMessage("lobbyRestored")
    else
        SetMessage("noLobby")
    end
end

function AA.Lobby:GetState()
    return state
end

function AA.Lobby:GetMessage()
    if state.messageKey then
        return FormatMessage(state.messageKey, state.messageArgs)
    end

    return state.message or L("noLobby")
end

function AA.Lobby:SetMessage(key, ...)
    SetMessage(key, ...)
end

function AA.Lobby:GetRoleLabel(role)
    local key = ROLE_LABELS[role]
    return key and L(key) or role or "?"
end

function AA.Lobby:IsActive()
    return state.active
end

function AA.Lobby:CanUseGroupLobby()
    return HasGroupChannel()
end

function AA.Lobby:IsHost()
    return state.active and state.host == LocalName()
end

function AA.Lobby:IsLocalSpymaster()
    local player = state.players[LocalName()]
    return player and player.role == "SPYMASTER"
end

function AA.Lobby:IsLocalTurnAgent(team)
    local player = state.players[LocalName()]
    return player and player.team == team and player.role == "AGENT"
end

function AA.Lobby:IsLocalTurnSpymaster(team)
    local player = state.players[LocalName()]
    return player and player.team == team and player.role == "SPYMASTER"
end

function AA.Lobby:GetLocalPlayer()
    return state.players[LocalName()]
end

function AA.Lobby:CanStartMission()
    local ready, count = AllReady()
    return state.active and self:IsHost() and ready, count
end

function AA.Lobby:BroadcastState(target)
    if AA.Comm then
        AA.Comm:Send(target, "LOBBY", state.host or LocalName())
    end

    for name in pairs(state.players) do
        SendPlayer(name, target)
    end
end

function AA.Lobby:RequestResync()
    if self:IsHost() then
        self:BroadcastState(nil)
        if AA.Game and AA.Game.SendSync then
            AA.Game:SendSync(nil)
        end
        SetMessage("stateSent")
        Refresh()
        return
    end

    if AA.Comm then
        AA.Comm:Broadcast("SYNCREQ", LocalName())
        SetMessage("resyncRequested")
    else
        SetMessage("addonChannelUnavailable")
    end

    Refresh()
end

function AA.Lobby:Create()
    local me = LocalName()

    if not HasGroupChannel() then
        SetMessage("localModeGroupRequired")
        Refresh()
        return
    end

    state.active = true
    state.host = me
    state.players = {}

    local player = EnsurePlayer(me)
    player.team = "RED"
    player.role = "SPYMASTER"
    player.ready = true

    SetMessage("lobbyCreated")
    AA.Game:Reset(false)

    if AA.Comm then
        AA.Comm:Broadcast("LOBBY", me)
    end

    BroadcastPlayer(me)
    Refresh()
end

function AA.Lobby:Join()
    local me = LocalName()

    if not HasGroupChannel() then
        SetMessage("localModeGroupRequired")
        Refresh()
        return
    end

    if state.active then
        SetMessage("alreadyInLobby")
        Refresh()
        return
    end

    state.active = true
    state.host = state.host or "Recherche..."

    local player = EnsurePlayer(me)
    player.team = player.team or "BLUE"
    player.role = player.role or "AGENT"
    player.ready = false

    SetMessage("joinRequested")

    if AA.Comm then
        AA.Comm:Broadcast("JOIN", me)
        BroadcastPlayer(me)
        AA.Comm:Broadcast("SYNCREQ", me)
    end

    Refresh()
end

function AA.Lobby:Leave()
    local me = LocalName()

    if not state.active then
        SetMessage("noLobby")
        Refresh()
        return
    end

    if AA.Comm then
        AA.Comm:Broadcast("LEAVE", me)
    end

    state.active = false
    state.host = nil
    state.players = {}
    SetMessage("lobbyLeft")
    AA.Game:Reset(false)
    Refresh()
end

function AA.Lobby:SetTeam(team)
    if team ~= "RED" and team ~= "BLUE" then
        return
    end

    if AA.Game and AA.Game.GetState and AA.Game:GetState().phase == "PLAYING" then
        SetMessage("teamChangeDuringMission")
        Refresh()
        return
    end

    local player = EnsurePlayer(LocalName())
    player.team = team
    player.ready = false
    SetMessage("teamUpdated", function()
        return AA.Game:GetTeamLabel(team)
    end)

    BroadcastPlayer(player.name)
    Refresh()
end

function AA.Lobby:SetRole(role)
    if role ~= "AGENT" and role ~= "SPYMASTER" then
        return
    end

    if AA.Game and AA.Game.GetState and AA.Game:GetState().phase == "PLAYING" then
        SetMessage("roleChangeDuringMission")
        Refresh()
        return
    end

    local player = EnsurePlayer(LocalName())

    if player.role == role then
        SetMessage("roleAlreadySelected", function()
            return self:GetRoleLabel(role)
        end)
        Refresh()
        return
    end

    player.role = role
    player.ready = false
    SetMessage("roleUpdated", function()
        return self:GetRoleLabel(role)
    end)

    BroadcastPlayer(player.name)
    Refresh()
end

function AA.Lobby:SetReady(ready)
    if not state.active then
        SetMessage("needLobbyReady")
        Refresh()
        return
    end

    if AA.Game and AA.Game.GetState and AA.Game:GetState().phase == "PLAYING" then
        SetMessage("missionInProgress")
        Refresh()
        return
    end

    local player = EnsurePlayer(LocalName())
    player.ready = ready and true or false
    SetMessage(player.ready and "playerReady" or "playerWaiting")

    BroadcastPlayer(player.name)
    Refresh()
end

function AA.Lobby:ToggleReady()
    local player = EnsurePlayer(LocalName())
    self:SetReady(not player.ready)
end

function AA.Lobby:StartMission()
    if not state.active then
        self:Create()

        if not state.active then
            return
        end
    end

    if not self:IsHost() then
        SetMessage("onlyHostCanStart")
        Refresh()
        return
    end

    local ready, count = AllReady()

    if not ready then
        SetMessage("allPlayersNotReady")
        Refresh()
        return
    end

    if count > 1 and (not HasSpymaster("RED") or not HasSpymaster("BLUE")) then
        SetMessage("spymasterAdvice")
        Refresh()
        return
    end

    SetMessage("missionStartedByHost")
    AA.Game:NewGame(nil, true)
    Refresh()
end

function AA.Lobby:OnComm(command, args, sender)
    if command == "LOBBY" then
        local host = args[1] or sender
        state.active = true
        state.host = host
        EnsurePlayer(host)
        SetMessage("lobbyDetected", AA:ShortName(host))
        Refresh()
        return
    end

    if command == "JOIN" then
        local playerName = args[1] or sender
        state.active = true
        EnsurePlayer(playerName)
        SetMessage("playerJoinedLobby", AA:ShortName(playerName))

        if self:IsHost() then
            self:BroadcastState(sender)
            if AA.Game and AA.Game.SendSync then
                AA.Game:SendSync(sender)
            end
        end

        Refresh()
        return
    end

    if command == "PLAYER" then
        local name = args[1] or sender
        local player = EnsurePlayer(name)
        player.team = args[2] or player.team or "BLUE"
        player.role = args[3] or player.role or "AGENT"
        player.ready = args[4] == "1"
        state.active = true
        SetMessage("lobbyStatusUpdated")
        Refresh()
        return
    end

    if command == "LEAVE" then
        local playerName = args[1] or sender
        state.players[playerName] = nil
        SetMessage("playerLeftLobby", AA:ShortName(playerName))

        if playerName == state.host then
            state.active = false
            state.host = nil
            state.players = {}
            SetMessage("hostLeftLobby")
        end

        Refresh()
        return
    end
end
