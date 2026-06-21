local addonName, AA = ...

AA.name = addonName
AA.version = "0.4.3"

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
        },
        lastGame = nil,
        lastLobby = nil
    }

    AzerothAgentsDB.stats = AzerothAgentsDB.stats or {}
    AA.DB = AzerothAgentsDB
    AA.localPlayer = AA:GetPlayerName()

    if AA.Locale and AA.Locale.Init then
        AA.Locale:Init()
    end

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

    if AA.Locale then
        AA:Print(AA.Locale:T("addonLoaded", AA.version))
    else
        AA:Print("v" .. AA.version .. " loaded. Type /aa to open the confidential file.")
    end
end)

SLASH_AZEROTHAGENTS1 = "/aa"
SLASH_AZEROTHAGENTS2 = "/agents"

SlashCmdList["AZEROTHAGENTS"] = function()
    AA.UI:Toggle()
end
