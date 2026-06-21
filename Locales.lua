local addonName, AA = ...

AA.Locale = {}

local DEFAULT_MODE = "AUTO"
local DEFAULT_LOCALE = "frFR"

local STRINGS = {
    frFR = {
        addonLoaded = "v%s chargée. Tape /aa pour ouvrir le dossier confidentiel.",
        languageAuto = "Auto",
        languageFrench = "FR",
        languageEnglish = "EN",
        languageButton = "Langue : %s",
        subtitle = "Dossier confidentiel — SI:7",

        teamRed = "Rouge",
        teamBlue = "Bleu",
        typeRed = "Rouge",
        typeBlue = "Bleu",
        typeNeutral = "Neutre",
        typeAssassin = "Assassin",
        roleAgent = "Agent",
        roleSpymaster = "Maître-espion",

        initialGameMessage = "Dossier SI:7 en attente. Crée ou rejoins un lobby.",
        noActiveMission = "Aucune mission active.",
        noActiveMissionStart = "Aucune mission active. Lance une nouvelle partie.",
        missionEnded = "Mission terminée  |  Rouge : %d  |  Bleu : %d",
        turnSummary = "Tour : %s  |  Rouge : %d  |  Bleu : %d",
        classified = "CLASSIFIÉ",

        noActiveClue = "Aucun indice actif.",
        clueText = "Indice %s : %s / %s",
        clueInputLabel = "Donner un indice",
        noMissionForClue = "Aucune mission active pour envoyer un indice.",
        clueOnlyActiveSpymaster = "Seul le maître-espion de l'équipe active peut donner un indice.",
        invalidClue = "Indice invalide. Format attendu : un mot + un nombre.",
        clueMessage = "Indice %s : %s / %s.",
        clueHistory = "Indice %s — %s / %s.",

        noHistory = "Aucun événement consigné.",
        localCacheRestored = "Dossier restauré depuis la cache locale. Clique Resync si besoin.",
        resetMessage = "Dossier SI:7 réinitialisé. Crée ou rejoins un lobby.",
        missionStarted = "Mission lancée. L'équipe %s commence.",
        missionOpenedHistory = "Mission ouverte — %s commence.",
        turnPassed = "Tour passé. À l'équipe %s.",
        turnPassedHistory = "Tour passé — %s joue.",
        endTurnOnlyActiveAgents = "Seuls les agents de l'équipe active peuvent passer le tour.",
        revealOnlyActiveAgents = "Seuls les agents de l'équipe active peuvent révéler un mot.",
        cardAlreadyRevealed = "Ce contact a déjà été révélé.",
        assassinRevealed = "Assassin révélé. L'équipe %s est compromise. Victoire %s.",
        assassinHistory = "Assassin révélé : %s. Victoire %s.",
        redWin = "Tous les agents rouges sont exfiltrés. Victoire Rouge.",
        blueWin = "Tous les agents bleus sont exfiltrés. Victoire Bleue.",
        redWinHistory = "Victoire Rouge — dernier contact : %s.",
        blueWinHistory = "Victoire Bleue — dernier contact : %s.",
        contactConfirmed = "Contact confirmé pour l'équipe %s.",
        contactHistory = "%s révélé — contact %s.",
        neutralRevealed = "Contact neutre. Tour de l'équipe %s.",
        neutralHistory = "%s révélé — neutre. Tour %s.",
        opponentRevealed = "Agent adverse révélé. Tour de l'équipe %s.",
        opponentHistory = "%s révélé — agent %s. Tour %s.",
        resyncReceived = "Resync reçue de %s.",
        syncedWithHost = "Mission synchronisée avec l'hôte %s.",

        noLobby = "Aucun lobby actif.",
        lobbyUnavailable = "Lobby indisponible.",
        noLobbyHint = "Aucun lobby actif.\n\nCrée un lobby ou rejoins celui du groupe.",
        lobbyRestored = "Lobby restauré depuis la cache locale. Clique Resync si besoin.",
        stateSent = "État renvoyé au groupe.",
        resyncRequested = "Demande de resynchronisation envoyée à l'hôte.",
        addonChannelUnavailable = "Canal addon indisponible.",
        localModeGroupRequired = "Mode local : groupe requis pour synchroniser le lobby.",
        lobbyCreated = "Lobby créé. Les agents du groupe peuvent rejoindre.",
        alreadyInLobby = "Tu es déjà dans un lobby. Quitte-le avant d'en rejoindre un autre.",
        joinRequested = "Demande de jonction envoyée au groupe.",
        lobbyLeft = "Lobby quitté.",
        teamChangeDuringMission = "Impossible de changer d'équipe pendant la mission.",
        teamUpdated = "Équipe mise à jour : %s.",
        roleChangeDuringMission = "Impossible de changer de rôle pendant la mission.",
        roleAlreadySelected = "Rôle déjà sélectionné : %s.",
        roleUpdated = "Rôle mis à jour : %s.",
        needLobbyReady = "Crée ou rejoins un lobby avant de te déclarer prêt.",
        missionInProgress = "La mission est en cours.",
        playerReady = "Agent prêt.",
        playerWaiting = "Agent en attente.",
        onlyHostCanStart = "Seul l'hôte peut lancer la mission.",
        allPlayersNotReady = "Impossible de lancer : tous les agents ne sont pas prêts.",
        spymasterAdvice = "Conseil SI:7 : prévois un maître-espion par équipe avant de lancer.",
        missionStartedByHost = "Mission lancée par l'hôte.",
        lobbyDetected = "Lobby détecté : hôte %s.",
        playerJoinedLobby = "%s a rejoint le lobby.",
        lobbyStatusUpdated = "Statut lobby mis à jour.",
        playerLeftLobby = "%s a quitté le lobby.",
        hostLeftLobby = "L'hôte a quitté le lobby.",

        lobbyTitle = "Lobby groupe",
        missionTitle = "Mission",
        agentsTitle = "Agents",
        historyTitle = "Journal",
        createLobby = "Créer lobby",
        joinLobby = "Rejoindre",
        leaveLobby = "Quitter",
        ready = "Prêt",
        notReady = "Pas prêt",
        red = "Rouge",
        blue = "Bleu",
        spymasterShort = "Espion",
        agent = "Agent",
        launchMission = "Lancer mission",
        endTurn = "Passer tour",
        reset = "Reset",
        resync = "Resync",
        clueButton = "Indice",
        channelLocal = "Canal addon : local",
        channelLabel = "Canal addon : %s",
        channelLocalNoGroup = "Canal addon : local, aucun groupe",
        lobbyHost = "Hôte : %s",
        playerLine = "%s — %s / %s %s",
        versionText = "v%s"
    },

    enUS = {
        addonLoaded = "v%s loaded. Type /aa to open the confidential file.",
        languageAuto = "Auto",
        languageFrench = "FR",
        languageEnglish = "EN",
        languageButton = "Lang: %s",
        subtitle = "Confidential file — SI:7",

        teamRed = "Red",
        teamBlue = "Blue",
        typeRed = "Red",
        typeBlue = "Blue",
        typeNeutral = "Neutral",
        typeAssassin = "Assassin",
        roleAgent = "Agent",
        roleSpymaster = "Spymaster",

        initialGameMessage = "SI:7 file pending. Create or join a lobby.",
        noActiveMission = "No active mission.",
        noActiveMissionStart = "No active mission. Start a new game.",
        missionEnded = "Mission ended  |  Red: %d  |  Blue: %d",
        turnSummary = "Turn: %s  |  Red: %d  |  Blue: %d",
        classified = "CLASSIFIED",

        noActiveClue = "No active clue.",
        clueText = "%s clue: %s / %s",
        clueInputLabel = "Give a clue",
        noMissionForClue = "No active mission for sending a clue.",
        clueOnlyActiveSpymaster = "Only the active team's spymaster can give a clue.",
        invalidClue = "Invalid clue. Expected format: one word + one number.",
        clueMessage = "%s clue: %s / %s.",
        clueHistory = "%s clue — %s / %s.",

        noHistory = "No event logged.",
        localCacheRestored = "File restored from local cache. Click Resync if needed.",
        resetMessage = "SI:7 file reset. Create or join a lobby.",
        missionStarted = "Mission started. Team %s begins.",
        missionOpenedHistory = "Mission opened — %s begins.",
        turnPassed = "Turn passed. Team %s plays.",
        turnPassedHistory = "Turn passed — %s plays.",
        endTurnOnlyActiveAgents = "Only agents from the active team can pass the turn.",
        revealOnlyActiveAgents = "Only agents from the active team can reveal a word.",
        cardAlreadyRevealed = "This contact has already been revealed.",
        assassinRevealed = "Assassin revealed. Team %s is compromised. %s wins.",
        assassinHistory = "Assassin revealed: %s. %s wins.",
        redWin = "All red agents extracted. Red wins.",
        blueWin = "All blue agents extracted. Blue wins.",
        redWinHistory = "Red victory — last contact: %s.",
        blueWinHistory = "Blue victory — last contact: %s.",
        contactConfirmed = "Contact confirmed for team %s.",
        contactHistory = "%s revealed — %s contact.",
        neutralRevealed = "Neutral contact. Team %s's turn.",
        neutralHistory = "%s revealed — neutral. %s turn.",
        opponentRevealed = "Enemy agent revealed. Team %s's turn.",
        opponentHistory = "%s revealed — %s agent. %s turn.",
        resyncReceived = "Resync received from %s.",
        syncedWithHost = "Mission synchronized with host %s.",

        noLobby = "No active lobby.",
        lobbyUnavailable = "Lobby unavailable.",
        noLobbyHint = "No active lobby.\n\nCreate a lobby or join the group's one.",
        lobbyRestored = "Lobby restored from local cache. Click Resync if needed.",
        stateSent = "State sent to the group.",
        resyncRequested = "Resync request sent to the host.",
        addonChannelUnavailable = "Addon channel unavailable.",
        localModeGroupRequired = "Local mode: group required to sync the lobby.",
        lobbyCreated = "Lobby created. Group agents can join.",
        alreadyInLobby = "You are already in a lobby. Leave it before joining another one.",
        joinRequested = "Join request sent to the group.",
        lobbyLeft = "Lobby left.",
        teamChangeDuringMission = "You cannot change team during the mission.",
        teamUpdated = "Team updated: %s.",
        roleChangeDuringMission = "You cannot change role during the mission.",
        roleAlreadySelected = "Role already selected: %s.",
        roleUpdated = "Role updated: %s.",
        needLobbyReady = "Create or join a lobby before marking yourself ready.",
        missionInProgress = "The mission is in progress.",
        playerReady = "Agent ready.",
        playerWaiting = "Agent waiting.",
        onlyHostCanStart = "Only the host can start the mission.",
        allPlayersNotReady = "Cannot start: all agents must be ready.",
        spymasterAdvice = "SI:7 advice: plan one spymaster per team before starting.",
        missionStartedByHost = "Mission started by host.",
        lobbyDetected = "Lobby detected: host %s.",
        playerJoinedLobby = "%s joined the lobby.",
        lobbyStatusUpdated = "Lobby status updated.",
        playerLeftLobby = "%s left the lobby.",
        hostLeftLobby = "The host left the lobby.",

        lobbyTitle = "Group lobby",
        missionTitle = "Mission",
        agentsTitle = "Agents",
        historyTitle = "Log",
        createLobby = "Create lobby",
        joinLobby = "Join",
        leaveLobby = "Leave",
        ready = "Ready",
        notReady = "Not ready",
        red = "Red",
        blue = "Blue",
        spymasterShort = "Spy",
        agent = "Agent",
        launchMission = "Launch mission",
        endTurn = "Pass turn",
        reset = "Reset",
        resync = "Resync",
        clueButton = "Clue",
        channelLocal = "Addon channel: local",
        channelLabel = "Addon channel: %s",
        channelLocalNoGroup = "Addon channel: local, no group",
        lobbyHost = "Host: %s",
        playerLine = "%s — %s / %s %s",
        versionText = "v%s"
    }
}

local WORDS = {
    frFR = {
        "PORTAIL", "MURLOC", "TITAN", "LUNE", "FORGE",
        "DRAGON", "RUNE", "ANCRE", "DAGUE", "BANQUE",
        "GLACE", "OMBRE", "TORCHE", "MAGE", "CRYPTE",
        "GRIFFON", "HORDE", "ALLIANCE", "TOTEM", "FEL",
        "NAGA", "ARCANE", "RELIQUE", "BATEAU", "SABRE",
        "MONTURE", "AUBERGE", "MARTEAU", "COURONNE", "ELFE",
        "ORC", "NAIN", "GNOME", "DRAENEI", "PANDAREN",
        "MORT", "VIE", "CHAOS", "PRÊTRE", "VOLEUR",
        "PALADIN", "CHASSEUR", "DÉMON", "LANCE", "BOUCLIER",
        "PRISON", "TEMPLE", "CAVERNE", "SABLE", "MER",
        "VOLCAN", "FLEUR", "CHAMPION", "BANNIÈRE", "BOSS",
        "DONJON", "RAID", "TRÉSOR", "ROYAUME", "CITADELLE",
        "ESPION", "AGENT", "MISSION", "DÉSERTEUR", "ARCHIVE",
        "DOSSIER", "SCEAU", "COURRIER", "POISON", "MASQUE",
        "TAVERNE", "NAVIRE", "CRISTAL", "FANTÔME", "PIÈGE",
        "CLÉ", "CARTE", "SECRET", "HÉROS", "INVASION",
        "PORT", "MARCHAND", "RAVENHOLDT", "HURLEVENT", "ORGRIMMAR",
        "KUL TIRAS", "DALARAN", "AZERITE",
        "BOUGIE", "KOBOLD", "GNOLL", "TROGG", "MASCOTTE",
        "KODO", "WYVERNE", "HIPPOGRIFFE", "ZEPPELIN", "CHOPPER",
        "TABARD", "BISCUIT", "FROMAGE", "MARMITE", "CHAUSSETTE",
        "PANTOUFLE", "MOUSTACHE", "BIDULE", "BRELOQUE", "GADGET",
        "RUSTINE", "GONG", "CLOCHE", "SIFFLET", "TAMBOUR",
        "PARCHEMIN", "GRIMOIRE", "ALMANACH", "CADENAS", "LANTERNE",
        "BAGUETTE", "FIOLE", "ELIXIR", "CHAMPIGNON", "TRUFFE",
        "SOUCOUPE", "TONNEAU", "HAMECON", "FILET", "BOUSSOLE",
        "LIMON", "GARGOUILLE", "BASILIC", "HARPIE", "MOLLUSQUE",
        "SARCOPHAGE", "MONOCLE", "PERRUQUE", "CONFETTI", "TROMPETTE",
        "CARTOUCHE", "CACAHUETE", "NOODLE", "MYSTERE", "PANNEAU",
        "CENDRES", "ENGRENAGE", "ROUILLE", "SABLIER", "CAFARD",
        "RONCE", "BRUME", "TROUPEAU", "SANCTUAIRE", "LUCIOLE",
        "PIEDS", "XAL'ATATH", "MALYGOS", "N'ZOTH", "Y'SHAARJ", "C'THUN",
        "AZSHARA", "KEL'THUZAD", "ILLIDAN", "SARGERAS",
        "ARTHAS", "KARAZHAN", "BLACKROCK", "DRAENOR", "NORTHREND",
        "HURLEVENT", "ORGRIMMAR", "DALARAN"
    },

    enUS = {
        "PORTAL", "MURLOC", "TITAN", "MOON", "FORGE",
        "DRAGON", "RUNE", "ANCHOR", "DAGGER", "BANK",
        "ICE", "SHADOW", "TORCH", "MAGE", "CRYPT",
        "GRYPHON", "HORDE", "ALLIANCE", "TOTEM", "FEL",
        "NAGA", "ARCANE", "RELIC", "BOAT", "SABER",
        "MOUNT", "INN", "HAMMER", "CROWN", "ELF",
        "ORC", "DWARF", "GNOME", "DRAENEI", "PANDAREN",
        "DEATH", "LIFE", "CHAOS", "PRIEST", "ROGUE",
        "PALADIN", "HUNTER", "DEMON", "SPEAR", "SHIELD",
        "PRISON", "TEMPLE", "CAVERN", "SAND", "SEA",
        "VOLCANO", "FLOWER", "CHAMPION", "BANNER", "BOSS",
        "DUNGEON", "RAID", "TREASURE", "KINGDOM", "CITADEL",
        "SPY", "AGENT", "MISSION", "DESERTER", "ARCHIVE",
        "FILE", "SEAL", "COURIER", "POISON", "MASK",
        "TAVERN", "SHIP", "CRYSTAL", "GHOST", "TRAP",
        "KEY", "MAP", "SECRET", "HERO", "INVASION",
        "HARBOR", "MERCHANT", "RAVENHOLDT", "STORMWIND", "ORGRIMMAR",
        "KUL TIRAS", "DALARAN", "AZERITE",
        "CANDLE", "KOBOLD", "GNOLL", "TROGG", "PET",
        "KODO", "WYVERN", "HIPPOGRYPH", "ZEPPELIN", "CHOPPER",
        "TABARD", "BISCUIT", "CHEESE", "CAULDRON", "SOCK",
        "SLIPPER", "MOUSTACHE", "DOOHICKEY", "TRINKET", "GADGET",
        "PATCH", "GONG", "BELL", "WHISTLE", "DRUM",
        "SCROLL", "GRIMOIRE", "ALMANAC", "PADLOCK", "LANTERN",
        "WAND", "VIAL", "ELIXIR", "MUSHROOM", "TRUFFLE",
        "SAUCER", "BARREL", "HOOK", "NET", "COMPASS",
        "OOZE", "GARGOYLE", "BASILISK", "HARPY", "CLAM",
        "SARCOPHAGUS", "MONOCLE", "WIG", "CONFETTI", "TRUMPET",
        "CARTRIDGE", "PEANUT", "NOODLE", "MYSTERY", "SIGN",
        "ASHES", "GEAR", "RUST", "HOURGLASS", "ROACH",
        "BRAMBLE", "MIST", "HERD", "SANCTUARY", "FIREFLY",
        "FEET", "XAL'ATATH", "MALYGOS", "N'ZOTH", "Y'SHAARJ", "C'THUN",
        "AZSHARA", "KEL'THUZAD", "ILLIDAN", "SARGERAS",
        "ARTHAS", "KARAZHAN", "BLACKROCK", "DRAENOR", "NORTHREND",
        "STORMWIND", "ORGRIMMAR", "DALARAN"
    }
}

local function NormalizeLocale(locale)
    locale = tostring(locale or "")

    if string.sub(locale, 1, 2) == "fr" then
        return "frFR"
    end

    return "enUS"
end

local function CurrentGameLocale()
    if GetLocale then
        return NormalizeLocale(GetLocale())
    end

    return DEFAULT_LOCALE
end

local function ResolveMode(mode)
    if mode == "frFR" or mode == "enUS" then
        return mode
    end

    return CurrentGameLocale()
end

function AA.Locale:Init()
    if AA.DB then
        AA.DB.ui = AA.DB.ui or {}
        AA.DB.ui.languageMode = AA.DB.ui.languageMode or DEFAULT_MODE
        self.mode = AA.DB.ui.languageMode
    else
        self.mode = DEFAULT_MODE
    end

    self.current = ResolveMode(self.mode)
end

function AA.Locale:GetMode()
    return self.mode or DEFAULT_MODE
end

function AA.Locale:GetCurrentLocale()
    self.current = ResolveMode(self:GetMode())
    return self.current
end

function AA.Locale:SetMode(mode)
    if mode ~= "AUTO" and mode ~= "frFR" and mode ~= "enUS" then
        mode = DEFAULT_MODE
    end

    self.mode = mode
    self.current = ResolveMode(mode)

    if AA.DB then
        AA.DB.ui = AA.DB.ui or {}
        AA.DB.ui.languageMode = mode
    end
end

function AA.Locale:CycleMode()
    local locale = self:GetCurrentLocale()

    if locale == "frFR" then
        self:SetMode("enUS")
    else
        self:SetMode("frFR")
    end
end

function AA.Locale:GetModeLabel()
    local locale = self:GetCurrentLocale()

    if locale == "frFR" then
        return self:T("languageFrench")
    end

    return self:T("languageEnglish")
end

function AA.Locale:T(key, ...)
    local locale = self:GetCurrentLocale()
    local value = STRINGS[locale] and STRINGS[locale][key]

    if value == nil then
        value = STRINGS.enUS[key] or STRINGS.frFR[key] or key
    end

    if select("#", ...) > 0 then
        return string.format(value, ...)
    end

    return value
end

function AA.Locale:GetWords()
    return WORDS[self:GetCurrentLocale()] or WORDS.enUS
end
