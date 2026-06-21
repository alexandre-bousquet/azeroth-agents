# Azeroth Agents

> *“Les meilleures opérations sont celles dont personne ne parle.”*  
> — Archive non officielle du SI:7

**Azeroth Agents** est un addon World of Warcraft proposant un mini-jeu de déduction en équipe, jouable directement en jeu via une interface dédiée.

Deux équipes s’affrontent sur une grille de mots codés. Chaque maître-espion connaît l’identité des agents, des contacts neutres et de l’assassin. À l’aide d’indices limités, il doit guider son équipe vers les bons mots avant l’adversaire.

Pensé comme une version légère, conviviale et roleplay d’un jeu d’agents secrets, l’addon transforme votre groupe en cellule d’infiltration prête à opérer dans les ombres d’Azeroth.

## État du projet

Version actuelle : **v0.4.4**

Interface WoW : **120007**

Cette version ajoute la localisation :

- textes d'interface variabilisés ;
- messages de lobby et de mission variabilisés ;
- listes de mots FR / EN ;
- détection automatique de la langue du client WoW ;
- switch discret **Langue** dans l'interface : FR / EN.

## Installation

Copier le dossier `AzerothAgents` dans :

```txt
World of Warcraft/_retail_/Interface/AddOns/
```

ou avec le lien [CurseForge](https://www.curseforge.com/wow/addons/azeroth-agents)

Puis relancer le jeu ou exécuter :

```txt
/reload
```

## Utilisation rapide

```txt
/aa
/agents
```

1. Être dans un groupe ou raid WoW.
2. Un joueur clique sur **Créer lobby**.
3. Les autres joueurs cliquent sur **Rejoindre**.
4. Chaque joueur choisit son équipe et son rôle.
5. Chaque joueur clique sur **Prêt**.
6. L’hôte clique sur **Lancer mission**.
7. Les maîtres-espions envoient les indices depuis le panneau **Mission**.
8. En cas de `/reload`, cliquer sur **Resync** pour demander l’état complet à l’hôte.

## Localisation

Par défaut, le mode **Auto** utilise la langue du client World of Warcraft au lancement. Le bouton discret **Langue** affiche uniquement la langue active, **FR** ou **EN**, et permet de forcer l'une des deux.

## Commandes

```txt
/aa              Ouvre ou ferme l'interface
/agents          Ouvre ou ferme l'interface
```

Toutes les actions de lobby et de mission se font depuis l'interface graphique.

## Notes techniques

Le lobby utilise les messages addon WoW avec le préfixe court `AzAgents`. La synchronisation utilise une seed commune pour reconstruire le plateau, puis un masque de 25 caractères pour appliquer les cartes révélées. Le journal et l’indice actif sont aussi envoyés lors d’un resync.

Cette version est pensée pour jouer entre amis. Elle ne cherche pas à empêcher la triche côté client : un addon WoW reste exécuté localement chez chaque joueur.

## Roadmap

### v0.5 — Finitions UI

- thème SI:7 plus marqué ;
- textures de cartes ;
- animations légères de révélation ;
- meilleur écran de fin de partie ;
- verrouillage des actions selon équipe/rôle.

### v0.6 — Qualité de vie

- variantes de listes de mots ;
- options de taille de plateau ;
- statistiques locales plus détaillées.

## Licence / assets

Le projet n’utilise pas d’assets externes dans sa v0.4. L’interface repose sur les templates et primitives UI disponibles dans le client World of Warcraft.
