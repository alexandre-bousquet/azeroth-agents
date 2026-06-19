# Azeroth Agents

> *“Les meilleures opérations sont celles dont personne ne parle.”*  
> — Archive non officielle du SI:7

**Azeroth Agents** est un addon World of Warcraft proposant un mini-jeu de déduction en équipe, jouable directement en jeu via une interface dédiée.

Deux équipes s’affrontent sur une grille de mots codés. Chaque maître-espion connaît l’identité des agents, des contacts neutres et de l’assassin. À l’aide d’indices limités, il doit guider son équipe vers les bons mots avant l’adversaire.

Pensé comme une version légère, conviviale et roleplay d’un jeu d’agents secrets, l’addon transforme votre groupe en cellule d’infiltration prête à opérer dans les ombres d’Azeroth.

## État du projet

Version actuelle : **v0.2.3**  
Interface WoW : **120007**

## Installation

Copier le dossier `AzerothAgents` dans :

```txt
World of Warcraft/_retail_/Interface/AddOns/
```

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

## Commandes

```txt
/aa              Ouvre ou ferme l'interface
/aa lobby        Crée un lobby
/aa join         Rejoint le lobby du groupe
/aa ready        Bascule prêt / pas prêt
/aa red          Passe équipe Rouge
/aa blue         Passe équipe Bleue
/aa agent        Passe rôle Agent
/aa spyrole      Passe rôle Maître-espion
/aa start        Lance la mission, hôte uniquement
/aa new          Lance une nouvelle mission locale/synchronisée
/aa spy          Active ou désactive la vue maître-espion locale
/aa reset        Réinitialise le plateau
/aa help         Affiche l'aide
```

## Notes techniques

Le lobby utilise les messages addon WoW avec le préfixe court `AzAgents`. La synchronisation v0.2 reste volontairement simple : l’hôte envoie une seed, puis chaque client génère le même plateau localement.

Cette version est pensée pour jouer entre amis. Elle ne cherche pas à empêcher la triche côté client : un addon WoW reste exécuté localement chez chaque joueur.

## Roadmap

### v0.3 - Resynchronisation robuste

- bouton “Resync” ;
- reprise propre après `/reload` ;
- état complet du plateau par fragments ;
- historique des actions ;
- champ d’indice + nombre ;
- journal de mission.

### v0.4 - Finitions UI

- animations légères de révélation ;
- meilleur écran de fin de partie.

## Licence / assets

Le projet n’utilise pas d’assets externes dans sa v0.2. L’interface repose sur les templates et primitives UI disponibles dans le client World of Warcraft.
