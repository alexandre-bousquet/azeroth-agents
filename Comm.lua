local addonName, AA = ...

AA.Comm = {}

local PREFIX = "AzAgents"
local VERSION_TAG = "2"
local initialized = false

local function Encode(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%", "%%p")
    value = string.gsub(value, "|", "%%b")
    value = string.gsub(value, "\n", "%%n")
    return value
end

local function Decode(value)
    value = tostring(value or "")
    value = string.gsub(value, "%%n", "\n")
    value = string.gsub(value, "%%b", "|")
    value = string.gsub(value, "%%p", "%%")
    return value
end

local function Split(text)
    local parts = {}
    local startIndex = 1

    text = text or ""

    while true do
        local separator = string.find(text, "|", startIndex, true)

        if not separator then
            table.insert(parts, Decode(string.sub(text, startIndex)))
            break
        end

        table.insert(parts, Decode(string.sub(text, startIndex, separator - 1)))
        startIndex = separator + 1
    end

    return parts
end

local function BuildPayload(command, ...)
    local parts = { VERSION_TAG, command }

    for i = 1, select("#", ...) do
        table.insert(parts, Encode(select(i, ...)))
    end

    return table.concat(parts, "|")
end

function AA.Comm:GetChannel()
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    end

    if IsInRaid and IsInRaid() then
        return "RAID"
    end

    if IsInGroup and IsInGroup() then
        return "PARTY"
    end

    return nil
end

function AA.Comm:Init()
    if initialized then
        return
    end

    initialized = true

    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function(_, event, prefix, text, channel, sender)
        if event ~= "CHAT_MSG_ADDON" or prefix ~= PREFIX then
            return
        end

        self:Handle(text, channel, sender)
    end)

    self.frame = frame
end

function AA.Comm:Broadcast(command, ...)
    local channel = self:GetChannel()
    local payload = BuildPayload(command, ...)

    if not channel then
        if AA.Lobby and AA.Lobby.GetState then
            local lobby = AA.Lobby:GetState()
            lobby.message = "Mode local : groupe requis pour synchroniser le lobby."
        end
        return false
    end

    C_ChatInfo.SendAddonMessage(PREFIX, payload, channel)
    return true
end

function AA.Comm:Handle(text, channel, sender)
    if not sender then
        return
    end

    -- Les actions locales sont déjà appliquées avant envoi.
    if AA:IsMe(sender) then
        return
    end

    local parts = Split(text)

    if parts[1] ~= VERSION_TAG then
        return
    end

    local command = parts[2]
    local args = {}

    for i = 3, #parts do
        table.insert(args, parts[i])
    end

    if AA.Lobby then
        AA.Lobby:OnComm(command, args, sender)
    end

    if command == "START" then
        local seed = tonumber(args[1])
        AA.Game:NewGame(seed, false)
        AA.Game:SetMessage("Mission synchronisée avec l'hôte " .. AA:ShortName(sender) .. ".")
        if AA.UI then AA.UI:Refresh() end
        return
    end

    if command == "REVEAL" then
        AA.Game:RevealCard(tonumber(args[1]), false)
        return
    end

    if command == "ENDTURN" then
        AA.Game:EndTurn(false)
        return
    end

    if command == "RESET" then
        AA.Game:Reset(false)
        return
    end
end
