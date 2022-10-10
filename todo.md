# Todo list

## Septembre - octobre

- [ ] description : ajouter la possiblilté d'afficher les descriptions possibles, afficher les options qui existent...
- [ ] ajouter d'autres types d'ocp - commencer par la possiblité de donner une condition terminale fixée. Dans ce cas, c'est au solveur de transformer le problème dans la formulation intéressante pour lui. Il faut donc une méhode `convert(ocp::TypeOCP, newType)`.
- [ ] ajouter un affichage du type de problème vraiment résolu par le solveur pour expliquer aussi comme ça les options possibles - à voir si ça ne va pas directement dans la doc. Il y a les paramètres du solveur et ceux qui apparaissent dans la transcription du problème, c'est ces derniers qu'il faut mettre en avant aussi. 
- [ ] ajouter des variantes au solveur descent.
- [ ] ajouter callbacks et gestion des erreurs - commencer par le solveur descent.
- [ ] faire un notebook tutoriel
- [ ] améliorer affichage du problème ocp : text/html ou makdown ou latex
- [ ] ajouter des tests unitaires + docstrings + documentation
- [ ] ajouter une méthode indirecte avec création de la fonction de tir et calcul d'un $\lambda$ initial à partir de $p_0$. 
- [ ] ajouter des formulations d'ocp et continuer à résoudre via `descent` et `indirect` en faisant une bonne transcription.