local addonName, AA = ...

AA.name = addonName
AA.version = "0.2.2"

function AA:GetPlayerName()
    local name, realm = UnitFullName("player")

    if realm and realm ~= "" then
        return name .. "-" .. realm
    end

    return name or UnitName("player") or "Agent"
end

function AA:IsMe(name)
    if not name then
        return false
    end

    local shortName = UnitName("player")
    local fullName = self.localPlayer or self:GetPlayerName()

    return name == shortName or name == fullName
end

function AA:ShortName(name)
    if not name then
        return "?"
    end

    if Ambiguate then
        return Ambiguate(name, "short")
    end

    return string.gsub(name, "%-.*$", "")
end

function AA:Print(message)
    print("|cffffd100Azeroth Agents|r " .. tostring(message))
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event)
    if event ~= "PLAYER_LOGIN" then
        return
    end

    AzerothAgentsDB = AzerothAgentsDB or {
        ui = {},
        stats = {
            gamesStarted = 0,
            redWins = 0,
            blueWins = 0,
            assassinReveals = 0
        }
    }

    AzerothAgentsDB.stats = AzerothAgentsDB.stats or {}
    AA.DB = AzerothAgentsDB
    AA.localPlayer = AA:GetPlayerName()

    if AA.Game and AA.Game.Init then
        AA.Game:Init()
    end

    if AA.Lobby and AA.Lobby.Init then
        AA.Lobby:Init()
    end

    if AA.Comm and AA.Comm.Init then
        AA.Comm:Init()
    end

    if AA.UI and AA.UI.Init then
        AA.UI:Init()
    end

    AA:Print("v" .. AA.version .. " chargée. Tape /aa pour ouvrir le dossier confidentiel.")
end)

local function PrintHelp()
    AA:Print("Commandes disponibles :")
    print("/aa - Ouvrir/fermer l'interface")
    print("/aa lobby - Créer un lobby")
    print("/aa join - Rejoindre le lobby du groupe")
    print("/aa start - Lancer la mission, hôte uniquement")
    print("/aa ready - Basculer prêt/pas prêt")
    print("/aa red ou /aa blue - Changer d'équipe")
    print("/aa agent ou /aa spyrole - Changer de rôle")
    print("/aa new - Nouvelle mission locale")
    print("/aa spy - Activer/désactiver la vue maître-espion locale")
    print("/aa reset - Réinitialiser le plateau")
end

SLASH_AZEROTHAGENTS1 = "/aa"
SLASH_AZEROTHAGENTS2 = "/agents"

SlashCmdList["AZEROTHAGENTS"] = function(msg)
    msg = string.lower(msg or "")
    msg = string.gsub(msg, "^%s+", "")
    msg = string.gsub(msg, "%s+$", "")

    if msg == "help" or msg == "aide" then
        PrintHelp()
        return
    end

    if msg == "lobby" or msg == "host" or msg == "create" then
        AA.Lobby:Create()
        AA.UI:Show()
        return
    end

    if msg == "join" or msg == "rejoindre" then
        AA.Lobby:Join()
        AA.UI:Show()
        return
    end

    if msg == "leave" or msg == "quit" or msg == "quitter" then
        AA.Lobby:Leave()
        AA.UI:Refresh()
        return
    end

    if msg == "ready" or msg == "pret" or msg == "prêt" then
        AA.Lobby:ToggleReady()
        AA.UI:Refresh()
        return
    end

    if msg == "red" or msg == "rouge" then
        AA.Lobby:SetTeam("RED")
        AA.UI:Refresh()
        return
    end

    if msg == "blue" or msg == "bleu" then
        AA.Lobby:SetTeam("BLUE")
        AA.UI:Refresh()
        return
    end

    if msg == "agent" then
        AA.Lobby:SetRole("AGENT")
        AA.UI:Refresh()
        return
    end

    if msg == "spyrole" or msg == "maitre" or msg == "maître" then
        AA.Lobby:SetRole("SPYMASTER")
        AA.UI:Refresh()
        return
    end

    if msg == "start" or msg == "lancer" then
        AA.Lobby:StartMission()
        AA.UI:Show()
        return
    end

    if msg == "new" or msg == "nouveau" then
        AA.Game:NewGame(nil, true)
        AA.UI:Show()
        return
    end

    if msg == "spy" or msg == "espion" then
        AA.Game:ToggleSpyMode()
        AA.UI:Refresh()
        return
    end

    if msg == "reset" then
        AA.Game:Reset(true)
        AA.UI:Refresh()
        return
    end

    AA.UI:Toggle()
end
