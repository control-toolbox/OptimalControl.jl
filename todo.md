# Todo list

* pour l'instant j'ai fait un add de [Flows](https://github.com/control-toolbox/Flows.jl) via l'url github. Il faudra avoir un vrai packages à l'avenir.
* voir ce que j'exporte vraiment depuis ControlToolbox
* ne mettre que ce qui est indispensable dans les using
* utiliser Recipe au lieu de plot pour l'affichage.

## Général

- [x] utiliser le nouveau package Flows : dans la branche `flows-pkg`
- [ ] mettre dans un module à part les algos d'optimisation indépendant du point de vue contrôle optimal.
- [ ] ajouter des formulations d'ocp.
- [ ] faire un callback pour afficher la solution au cours des itérations avec une superposition de n plots par exemple et la possibilité de rejouer en mode player les itérations.
- [ ] ajouter régions de confiance
- [ ] ajouter une méthode indirecte avec création de la fonction de tir et calcul d'un $\lambda$ initial à partir de $p_0$. 
- [ ] faire du benchmarck + dataframe
- [ ] faire du batch à la main puis créer une méthode `batch` : sur paramètres du problème avec cold ou warm start, puis sur les options des algos que l'on peut donc modifier en cours de résolution + combinaison. 
- [ ] améliorer affichage du problème ocp : text/html ou markdown ou latex
- [ ] pouvoir faire `X, P, U, infos = sol()` avec `infos` qui contient le temps d'exécution, la méthode, les itérations...
- [ ] créer une fonction `formulation(ocp)` puis `print(ocp) = formulation(ocp)`.
- [ ] pourquoi pas créer un type abstrait Description pour gérer l'affichage d'une méthode
- [ ] ajouter une méthode de région de confiance pour voir si on doit mettre un cadre niveau packaging pour pouvoir faire autant de choses par région de confiance que par descente. A voir si pas déjà vu par une méthode indirecte.
- [ ] au lieu de faire un NLE solver, faire un PMP solver ? Ajouter Path.
- [ ] Ajouter `Jump`, `Optimisation`, `InfinitOpt`...

## Documentation

- [ ] commencer les docstrings
- [ ] faire une liste des exemples à choisir
- [ ] il faut la liste des descriptions possibles
- [ ] il faut expliquer les transcriptions des solveurs pour avoir les vraies problèmes résolus

## Descent

- [x] Finaliser init : ajouter une init via une fonction $t \mapsto u(t)$, via une solution, interpolation... Faire des tests unitaires et un exemple.
- [ ] pouvoir choisir l'intégrateur et la taille de la sous-grille si on utilise du pas fixe, sinon les tolérances.
- [ ] ajouter cpu time
- [ ] revoir les plots pour gérer mieux quand y'aura d'autres solveurs. Il faut une méthode ne prenant pas une solution en argument mais `T, X, U, P`.
- [ ] a voir si le comportement par défaut de `plot(ocp, :time, :state)` ne serait pas d'afficher tous les states.
- [ ] ajouter `interpolation` + `approche finition`.
- [ ] généraliser le problème de contrôle que l'on peut résoudre et généraliser le calcul de l'adjoint, qui est ici explicite mais qui pourrait être implicite dans certains cas plus difficile, par exemple si on a des contraintes qui mélangent $x_0$ et $x_f$. 
- [ ] faire un exemple avec les différentes init possibles

## Tests unitaires

- [x] faire 0 itérations
- [ ] revoir les tests d'appels au solveur
- [ ] trouver un exemple où la `bissection` a une utilité, cf covering.
- [ ] trouver un exemple tel que lors d'une itération, pour `bfgs`, on n'a pas une direction de descente.
- [ ] ajouter des tests pour `backtracking`...
- [ ] description : voir si cela marche avec des description de tailles différentes dans la base
- [ ] faire un fichier test qui pour chaque algo ou autre, fait tous les appels qui sont obligatoires, ie. plot, formulation...