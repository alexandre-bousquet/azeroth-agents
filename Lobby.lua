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

local function Refresh()
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

local function BroadcastPlayer(name)
    local player = state.players[name]

    if not player or not AA.Comm then
        return
    end

    AA.Comm:Broadcast("PLAYER", player.name, player.team, player.role, player.ready and "1" or "0")
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

local function HostBroadcastState()
    if not AA.Lobby:IsHost() then
        return
    end

    if AA.Comm then
        AA.Comm:Broadcast("LOBBY", state.host or LocalName())
    end

    for name in pairs(state.players) do
        BroadcastPlayer(name)
    end
end

function AA.Lobby:Init()
    state.players = state.players or {}
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

function AA.Lobby:GetLocalPlayer()
    return state.players[LocalName()]
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

    local player = EnsurePlayer(LocalName())
    player.role = role
    player.ready = false
    state.message = "Rôle mis à jour : " .. self:GetRoleLabel(role) .. "."

    AA.Game:SetSpyMode(role == "SPYMASTER")
    BroadcastPlayer(player.name)
    Refresh()
end

function AA.Lobby:SetReady(ready)
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
            HostBroadcastState()
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
