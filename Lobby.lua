local addonName, AA = ...

AA.Lobby = {}

local ROLE_LABELS = {
    AGENT = "Agent",
    SPYMASTER = "Maître-espion"
}

local state = {
    active = false,
    host = nil,
    players = {},
    message = "Aucun lobby actif."
}


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

function AA.Lobby:Init()
    state.players = state.players or {}

    local saved = AA.DB and AA.DB.lastLobby

    if saved and saved.active then
        state.active = saved.active
        state.host = saved.host
        state.players = CopyPlayers(saved.players or {})
        state.message = "Lobby restauré depuis la cache locale. Clique Resync si besoin."
    end
end

function AA.Lobby:GetState()
    return state
end

function AA.Lobby:GetRoleLabel(role)
    return ROLE_LABELS[role] or role or "?"
end

function AA.Lobby:IsActive()
    return state.active
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
        state.message = "État renvoyé au groupe."
        Refresh()
        return
    end

    if AA.Comm then
        AA.Comm:Broadcast("SYNCREQ", LocalName())
        state.message = "Demande de resynchronisation envoyée à l'hôte."
    else
        state.message = "Canal addon indisponible."
    end

    Refresh()
end

function AA.Lobby:Create()
    local me = LocalName()

    state.active = true
    state.host = me
    state.players = {}

    local player = EnsurePlayer(me)
    player.team = "RED"
    player.role = "SPYMASTER"
    player.ready = true

    state.message = "Lobby créé. Les agents du groupe peuvent rejoindre."
    AA.Game:Reset(false)

    if AA.Comm then
        AA.Comm:Broadcast("LOBBY", me)
    end

    BroadcastPlayer(me)
    Refresh()
end

function AA.Lobby:Join()
    local me = LocalName()

    if state.active then
        state.message = "Tu es deja dans un lobby. Quitte-le avant d'en rejoindre un autre."
        Refresh()
        return
    end

    state.active = true
    state.host = state.host or "Recherche..."

    local player = EnsurePlayer(me)
    player.team = player.team or "BLUE"
    player.role = player.role or "AGENT"
    player.ready = false

    state.message = "Demande de jonction envoyée au groupe."

    if AA.Comm then
        AA.Comm:Broadcast("JOIN", me)
        BroadcastPlayer(me)
        AA.Comm:Broadcast("SYNCREQ", me)
    end

    Refresh()
end

function AA.Lobby:Leave()
    local me = LocalName()

    if AA.Comm then
        AA.Comm:Broadcast("LEAVE", me)
    end

    state.active = false
    state.host = nil
    state.players = {}
    state.message = "Lobby quitté."
    AA.Game:Reset(false)
    Refresh()
end

function AA.Lobby:SetTeam(team)
    if team ~= "RED" and team ~= "BLUE" then
        return
    end

    if AA.Game and AA.Game.GetState and AA.Game:GetState().phase == "PLAYING" then
        state.message = "Impossible de changer d'equipe pendant la mission."
        Refresh()
        return
    end

    local player = EnsurePlayer(LocalName())
    player.team = team
    player.ready = false
    state.message = "Équipe mise à jour : " .. AA.Game:GetTeamLabel(team) .. "."

    BroadcastPlayer(player.name)
    Refresh()
end

function AA.Lobby:SetRole(role)
    if role ~= "AGENT" and role ~= "SPYMASTER" then
        return
    end

    if AA.Game and AA.Game.GetState and AA.Game:GetState().phase == "PLAYING" then
        state.message = "Impossible de changer de role pendant la mission."
        Refresh()
        return
    end

    local player = EnsurePlayer(LocalName())

    if player.role == role then
        state.message = "Role deja selectionne : " .. self:GetRoleLabel(role) .. "."
        Refresh()
        return
    end

    player.role = role
    player.ready = false
    state.message = "Rôle mis à jour : " .. self:GetRoleLabel(role) .. "."

    BroadcastPlayer(player.name)
    Refresh()
end

function AA.Lobby:SetReady(ready)
    if AA.Game and AA.Game.GetState and AA.Game:GetState().phase == "PLAYING" then
        state.message = "La mission est en cours."
        Refresh()
        return
    end

    local player = EnsurePlayer(LocalName())
    player.ready = ready and true or false
    state.message = player.ready and "Agent prêt." or "Agent en attente."

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
    end

    if not self:IsHost() then
        state.message = "Seul l'hôte peut lancer la mission."
        Refresh()
        return
    end

    local ready, count = AllReady()

    if not ready then
        state.message = "Impossible de lancer : tous les agents ne sont pas prêts."
        Refresh()
        return
    end

    if count > 1 and (not HasSpymaster("RED") or not HasSpymaster("BLUE")) then
        state.message = "Conseil SI:7 : prévois un maître-espion par équipe avant de lancer."
        Refresh()
        return
    end

    state.message = "Mission lancée par l'hôte."
    AA.Game:NewGame(nil, true)
    Refresh()
end

function AA.Lobby:OnComm(command, args, sender)
    if command == "LOBBY" then
        local host = args[1] or sender
        state.active = true
        state.host = host
        EnsurePlayer(host)
        state.message = "Lobby détecté : hôte " .. AA:ShortName(host) .. "."
        Refresh()
        return
    end

    if command == "JOIN" then
        local playerName = args[1] or sender
        state.active = true
        EnsurePlayer(playerName)
        state.message = AA:ShortName(playerName) .. " a rejoint le lobby."

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
        state.message = "Statut lobby mis à jour."
        Refresh()
        return
    end

    if command == "LEAVE" then
        local playerName = args[1] or sender
        state.players[playerName] = nil
        state.message = AA:ShortName(playerName) .. " a quitté le lobby."

        if playerName == state.host then
            state.active = false
            state.host = nil
            state.players = {}
            state.message = "L'hôte a quitté le lobby."
        end

        Refresh()
        return
    end
end
