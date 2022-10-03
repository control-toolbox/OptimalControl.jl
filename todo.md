# Todo list

## Septembre - octobre

- [x] examples/steepest.jl : essayer dynamique non autonome
- [x] examples/steepest.jl : faire une méthode générique de plot paramétrable
- [ ] test/test_steepest.jl : reprendre les tests
- [x] src/ocp.jl : revoir la gestion de description + revoir ensuite dans src/Flows.jl
- [ ] src/steepest.jl : 
    * [x] ajouter struct pour init et sol Steepest + améliorer les transcriptions
    * [x] faire en sorte que la partie sd_solver résout un problème d'opti à définir, indépendant de OCP
    * [ ] rendre plus général le genre de problème que l'on peut résoudre par steepest : on calcule simplement le gradient si on ne sait pas faire intelligemment
    * [ ] améliorer le code de la steepest pour ajouter des variantes et ajouter description des variantes
    * [ ] ajouter callbacks et gestion des erreurs
    * [ ] vérifier signe adjoint et valeur (division par le pas ?)  
- [ ] ajouter un autre type de problème ocp avec gestion du type par inputs + check par description
- [ ] améliorer affichage du problème ocp : text/html ou makdown ou latex
- [ ] ajouter des tests unitaires + docstrings + documentation
- [x] Flows : on pourrait ajouter un kwargs  
- [x] Flows : est-ce qu'on ne fixerait pas les méthodes et tolérances à la création du flots ? ou les deux ?
- [x] Créer le flot d'une "function" : flot d'un hamiltonien par défaut