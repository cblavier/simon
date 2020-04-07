# Simon

Ce projet est un code challenge dont le but est d'apprendre le fonctionnement des `GenServer` Elixir en implémentant une IA joueur pour le Simon's Game.

[![Alt text](https://img.youtube.com/vi/G6p7zRsECaI/0.jpg)](https://www.youtube.com/watch?v=G6p7zRsECaI)

## Démarrage du serveur

Première étape, s'assurer que le projet actuel fonctionne sur votre poste.

Il n'y a pas de base de données, il suffit donc de lancer :
- `mix deps.get`
- `mix phx.server`
- `cd assets && npm install`

En appuyant sur "START" la partie doit démarrer puis s'arrêter aussitôt.

L'application est constituée de ces composants :

- `GameLive` est une `LiveView` qui permet de démarrer la partie puis de suivre son avancement.
- `GameServer` est un `GenServer` qui gère l'état de la partie, donne le tour de jeu au joueur et s'assure que les séquences de couleurs entrées sont correctes. `GameServer` notifie l'ensemble de ses listeners (les joueurs et la liveview) des évènements de la partie.
- Les IA des joueurs, que vous allez implémenter (une même IA peut être instantiée plusieurs fois avec des noms différents)

## Coder votre IA

**Vous allez coder votre IA sous la forme d'une branche + pull request sur ce repo.**

L'IA de votre joueur doit être capable de jouer correctement une partie sur toute la longueur de la séquence.
Votre serveur sera codée sous la forme d'un GenServer qui implémente les fonctions suivantes :

* `start_link/1` 
  * Le tableau d'options suivantes lui sera passé `[game_server: game_server, name: name, guess_delay: guess_delay, round_delay: round_delay]`
    * `game_server` est le pid du process qui gère la partie
    * `name` est une string qui représente le nom donné à votre joueur
    * `guess_delay` est une durée en ms qui représente le temps après chaque couleur lorsque votre IA donne sa séquence.
    * `round_delay` est une durée en ms qui représente le temps à attendre au début de votre tour avant de donner la première couleur de la séquence.

  - Lorsque votre serveur est démarré, il doit d'abord rejoindre la partie en faisant un appel de type `cast` au `GameServer` avec le message suivant : `{:join, player_pid, player_name}`

* Gérer les messages `handle_info/2` suivants 
  * `{:sequence_color, round, color}`
    * Ce message est lancé plusieurs fois par le `GameServer` pour indiquer la séquence en cours (au tour 3, le `GameServer` va envoyer 3x ce message d'affilée pour chacune des couleurs; au début du tour 10 ce message sera lancé 10x)
    * `round` est le numéro du tour en cours
    * `color` est un atom parmi `:red`, `:yellow`, `:green` et `:blue` 

  * `{:your_round, round}`
    * Ce message n'est adressé qu'au joueur qui a été choisi par le `GameServer` pour jouer le tour en cours.
    * `round` est le numéro du tour en cours
    * Lorsque ce message est adressé à votre IA, elle doit:
      1. Attendre `round_delay` ms
      2. Attendre `guess_delay` ms
      3. Envoyer au `GameServer` un message de type `call` avec les paramètres suivants `{:color_guess, color}`. **Attention, cet appel doit être effectué avec un timeout :infinity !!!**
      4. Vérifier le résultat de l'appel : si `:ok` on reprend à l'étape 2 jusqu'à ce que la séquence soit terminée, Si `:bad_guess` on s'arrête là.

  * `{:current_player, {player_pid, player_name}}`
    * Ce message est adressé à tous les joueurs (en même temps que :your_round) pour indiquer à tous quel joueur a commencé son tour.
    * `player_pid` est le process du joueur qui prend le tour
    * `player_name` est le nom du joueur qui prend le tour

  * `{:guess, color, {player_pid, player_name}}`
    * Ce message est adressé à tous les joueurs (en même temps que :your_round) pour indiquer à tous quel coup vient d'être joué.
    * `color` est la couleur qui vient d'être jouée
    * `player_pid` est le process du joueur qui vient de jouer
    * `player_name` est le nom du joueur qui vient de jouer

  * `{:win}`
    * La partie vient de se terminer en arrivant au bout la séquence sans erreur 🥳

  * `{:lose}`
    * La partie vient de se terminer sur une erreur 😞

## Tester votre IA

Evidemment via la LiveView mais également avec `ExUnit`. Vous pouvez vous inspirer du test de `game_server_test.exs`.    

## Supporter des perks

Afin d'apporter un peu de sel aux parties, vos IA vont être dotées de facultées qui malheureusement feront toutes prendre fin à la partie de manièré prématurée.

Votre IA doit supporter la fonction suivante : 

  - `supported_perks/0` qui retourne un tableau d'atoms de cette forme : `[:color_blind, :amnesic]`
  - au lancement de la partie, votre player sera aléatoirement doté d'un _perk_ parmi la liste supportée par votre IA via une nouvelle option `perk` passée à `start_link/1`

Implémentez les perks que vous souhaitez, voici quelques exemples :

  - `:color_blind` : ne fait pas la différence entre bleu et rouge.
  - `:short_memory` : ne se souvient que des 5 derniers tours, pour le reste, c'est du hasard 🎲.
  - `:rebel` : n'écoute pas les séquences du `GameServer`, uniquement les coups joués par les autres joueurs.
  - `:asshole` : envoie des fausses séquences aux autres joueurs.
