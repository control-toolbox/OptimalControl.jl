# Todo list

## Général

- [x] ajouter d'autres types d'ocp - commencer par la possiblité de donner une condition terminale fixée. Dans ce cas, c'est au solveur de transformer le problème dans la formulation intéressante pour lui. Il faut donc une méhode `convert(ocp::TypeOCP, newType)`.
- [ ] ajouter des variantes au solveur descent.
- [ ] faire un notebook tutoriel
- [ ] améliorer affichage du problème ocp : text/html ou makdown ou latex
- [ ] ajouter des tests unitaires + docstrings + documentation
- [ ] ajouter une méthode indirecte avec création de la fonction de tir et calcul d'un $\lambda$ initial à partir de $p_0$. 
- [ ] ajouter des formulations d'ocp et continuer à résoudre via `descent` et `indirect` en faisant une bonne transcription.
- [ ] faire du benchmarck + dataframe
- [ ] concepts : convert, description d'algo et de transcription
- [ ] description : ajouter la possiblilté d'afficher les descriptions possibles, afficher les options qui existent... C'est sûrement dans la doc ça.
- [ ] ajouter un affichage du type de problème vraiment résolu par le solveur pour expliquer aussi comme ça 
les options possibles - à voir si ça ne va pas directement dans la doc. Il y a les paramètres du solveur et 
ceux qui apparaissent dans la transcription du problème, c'est ces derniers qu'il faut mettre en avant aussi.
- [ ] pourquoi pas créer un type abstrait Description pour gérer l'affichage d'une méthode...
- [ ] pouvoir faire `X, P, U, infos = sol()` avec `infos` qui contient le temps d'exécution, la méthode, les itérations...
- [ ] créer une fonction `formulation(ocp)` puis `print(ocp) = formulation(ocp)`.
- [ ] faire du batch à la main puis créer une méthode `batch` : sur paramètres du problème avec cold ou warm start, puis sur les options des algos que l'on peut donc modifier en cours de résolution + combinaison. 
- [ ] faire un callback pour afficher la solution au cours des itérations avec une superposition de n plots par exemple et la possibilité de rejouer en mode player les itérations.
 
## Tests unitaires

- [ ] ajouter des tests pour `Flow` et les méthodes du style `backtracking`...
- [ ] ajouter des tests de validation car j'ai mis beaucoup de tests simples du genre vérifier les types.
- [ ] description : voir si cela marche avec des description de tailles différentes dans la base
- [ ] faire un fichier test qui pour chaque algo ou autre, fait tous les appels qui sont obligatoires, ie. plot, formulation...