# Design of `solve_descriptive`

**Layer**: 2 (Mode-Specific Logic - Descriptive Mode)

## R0 — Rôle et flux général

`solve_descriptive` est le point d'entrée du mode **descriptif** : l'utilisateur passe des symboles (`:collocation`, `:adnlp`, `:ipopt`) et des options à plat (kwargs), et la fonction doit :

1. **Compléter** la description partielle en un triplet complet `(discretizer_id, modeler_id, solver_id)`
2. **Router** les kwargs vers les bonnes stratégies via `CTSolvers.Orchestration.route_all_options`
3. **Construire** les trois stratégies concrètes avec leurs options routées
4. **Appeler** la couche canonique (Layer 3) avec les composants complets

### Contexte d'appel (Layer 1 → Layer 2)

`dispatch.jl` appelle `solve_descriptive` après avoir :

- Normalisé `initial_guess` (via `CTModels.build_initial_guess`)
- Créé ou extrait le `registry` (`CTSolvers.StrategyRegistry`)
- Filtré les composants explicites (mode descriptif = aucun composant explicite dans kwargs)

```julia
# dispatch.jl (Layer 1 → Layer 2, mode descriptif)
return solve_descriptive(
    ocp, description...;
    initial_guess = normalized_init,
    display       = display,
    registry      = registry,
    kwargs...      # options à plat pour les stratégies
)
```

Les `kwargs` reçus par `solve_descriptive` sont **exclusivement** des options de stratégies
(plus éventuellement des `RoutedOption` via `route_to`). Il n'y a **pas** de composants
explicites (`discretizer=`, `modeler=`, `solver=`) car ceux-ci auraient déclenché
`ExplicitMode` dans `_explicit_or_descriptive`.

---

## R1 — Signature et corps de haut niveau

```julia
function solve_descriptive(
    ocp::CTModels.AbstractModel,
    description::Symbol...;
    initial_guess::CTModels.AbstractInitialGuess,   # normalisé par Layer 1
    display::Bool,                                  # sans défaut
    registry::CTSolvers.StrategyRegistry,
    kwargs...                                       # options stratégies (plat + route_to)
)::CTModels.AbstractSolution

    # 1. Compléter la description partielle → triplet complet
    complete_description = _complete_description(description)

    # 2. Router toutes les options vers les familles de stratégies
    routed = _route_descriptive_options(complete_description, registry, kwargs)

    # 3. Construire les trois stratégies avec leurs options routées
    components = _build_components_from_routed(complete_description, registry, routed)

    # 4. Appel canonique (Layer 3)
    return CommonSolve.solve(
        ocp, initial_guess,
        components.discretizer,
        components.modeler,
        components.solver;
        display = display
    )
end
```

**Invariants** :

- Aucun défaut dans cette fonction (tout vient de Layer 1)
- `_complete_description` réutilise le helper existant dans `helpers/strategy_builders.jl`
- `_route_descriptive_options` encapsule l'appel à `CTSolvers.Orchestration.route_all_options`
- `_build_components_from_routed` construit les stratégies via `CTSolvers.Strategies.build_strategy_from_method`

---

## R2 — Fonctions helpers à implémenter

### R2.1 — `_route_descriptive_options` (nouveau helper)

**Rôle** : Encapsule `CTSolvers.Orchestration.route_all_options` avec les familles et
`action_defs` propres à OptimalControl.

```julia
function _route_descriptive_options(
    complete_description::Tuple{Symbol, Symbol, Symbol},
    registry::CTSolvers.Strategies.StrategyRegistry,
    kwargs
)
    families = _descriptive_families()
    action_defs = _descriptive_action_defs()
    return CTSolvers.Orchestration.route_all_options(
        complete_description,
        families,
        action_defs,
        NamedTuple(kwargs),
        registry;
        source_mode = :description,
        mode        = :strict
    )
end
```

**Fichier** : `src/helpers/descriptive_routing.jl`

### R2.2 — `_descriptive_families` (nouveau helper, pur)

**Rôle** : Retourne le `NamedTuple` des familles abstraites pour le routage.

```julia
function _descriptive_families()
    return (
        discretizer = CTDirect.AbstractDiscretizer,
        modeler     = CTSolvers.AbstractNLPModeler,
        solver      = CTSolvers.AbstractNLPSolver,
    )
end
```

**Fichier** : `src/helpers/descriptive_routing.jl`

### R2.3 — `_descriptive_action_defs` (nouveau helper, pur)

**Rôle** : Retourne les `OptionDefinition` pour les options d'action (niveau `solve`),
c'est-à-dire les options qui ne sont **pas** des options de stratégies.

> **Note** : `display` et `initial_guess` sont gérés par Layer 1 et ne parviennent
> **pas** dans les `kwargs` de `solve_descriptive`. Les `action_defs` sont donc vides
> pour l'instant. Ce helper existe pour extensibilité future.

```julia
function _descriptive_action_defs()
    return CTSolvers.Options.OptionDefinition[]
end
```

**Fichier** : `src/helpers/descriptive_routing.jl`

### R2.4 — `_build_components_from_routed` (nouveau helper)

**Rôle** : Construit les trois stratégies concrètes à partir du résultat de routage.

```julia
function _build_components_from_routed(
    complete_description::Tuple{Symbol, Symbol, Symbol},
    registry::CTSolvers.Strategies.StrategyRegistry,
    routed::NamedTuple
)
    discretizer = CTSolvers.Strategies.build_strategy_from_method(
        complete_description,
        CTDirect.AbstractDiscretizer,
        registry;
        routed.strategies.discretizer...
    )
    modeler = CTSolvers.Strategies.build_strategy_from_method(
        complete_description,
        CTSolvers.AbstractNLPModeler,
        registry;
        routed.strategies.modeler...
    )
    solver = CTSolvers.Strategies.build_strategy_from_method(
        complete_description,
        CTSolvers.AbstractNLPSolver,
        registry;
        routed.strategies.solver...
    )
    return (discretizer=discretizer, modeler=modeler, solver=solver)
end
```

**Fichier** : `src/helpers/descriptive_routing.jl`

---

## R3 — Gestion du mode strict vs permissive

### Principe

`route_all_options` accepte un paramètre `mode::Symbol` (`:strict` ou `:permissive`) :

- **`:strict`** (défaut) : toute option inconnue lève une `IncorrectArgument`
- **`:permissive`** : une option inconnue *avec* `route_to` est acceptée avec un warning

### Règle adoptée pour `solve_descriptive`

**Toujours `:strict`** dans un premier temps. La raison :

- En mode descriptif, l'utilisateur passe des options à plat. Si une option est inconnue,
  c'est presque toujours une faute de frappe → erreur claire préférable.
- Le mode `:permissive` est utile pour des backends expérimentaux qui ajoutent des options
  non déclarées dans les métadonnées. Ce cas peut être géré plus tard.

### Extension future (mode permissive)

Si l'utilisateur veut passer une option non déclarée à une stratégie spécifique, il peut
utiliser `route_to` avec un mode permissif. Pour l'activer, il suffirait d'exposer un
paramètre `validation_mode::Symbol=:strict` dans `solve_descriptive` et de le passer à
`_route_descriptive_options`. Cette extension est **YAGNI** pour l'instant.

---

## R4 — Plan d'action

### Étape 1 : Nouveau fichier `src/helpers/descriptive_routing.jl`

Implémenter les 3 helpers purs (R2.2, R2.3, R2.4) et le helper principal (R2.1).
Ces fonctions sont **directement testables** sans mock complexe.

Ajouter l'include dans `OptimalControl.jl` :

```julia
include(joinpath(@__DIR__, "helpers", "descriptive_routing.jl"))
```

### Étape 2 : Implémenter `solve_descriptive` dans `src/solve/descriptive.jl`

Remplacer le stub `NotImplemented` par l'implémentation réelle (R1).

### Étape 3 : Tests unitaires — `test/suite/solve/test_descriptive_routing.jl`

Tests des helpers purs (sans mock OCP, sans vrai solver) :

- `_descriptive_families` : structure correcte
- `_descriptive_action_defs` : liste vide
- `_route_descriptive_options` : auto-routing, disambiguation, erreurs
- `_build_components_from_routed` : construction avec options routées

Utiliser des mocks de stratégies (pattern des tests CTSolvers) pour éviter les dépendances
sur les vrais backends.

### Étape 4 : Tests d'intégration — mise à jour de `test/suite/solve/test_orchestration.jl`

Remplacer le test `"solve_descriptive raises NotImplemented"` par des tests réels :

- Descriptive mode complet : `solve(ocp, :collocation, :adnlp, :ipopt; display=false)`
- Descriptive mode partiel : `solve(ocp, :collocation; display=false)`
- Descriptive mode vide : `solve(ocp; display=false)`
- Options routées : `solve(ocp, :collocation, :adnlp, :ipopt; grid_size=10, display=false)`
- Disambiguation : `solve(ocp, ...; backend=route_to(adnlp=:sparse), display=false)`
- Erreur option inconnue : `@test_throws IncorrectArgument solve(ocp, ...; bad_opt=1)`
- Erreur option ambiguë : `@test_throws IncorrectArgument solve(ocp, ...; backend=:sparse)`

---

## R5 — Fichiers à créer / modifier

| Fichier | Action |
| --- | --- |
| `src/helpers/descriptive_routing.jl` | **Créer** — helpers R2.1–R2.4 |
| `src/solve/descriptive.jl` | **Modifier** — remplacer stub par implémentation R1 |
| `src/OptimalControl.jl` | **Modifier** — ajouter include de `descriptive_routing.jl` |
| `test/suite/solve/test_descriptive_routing.jl` | **Créer** — tests unitaires helpers |
| `test/suite/solve/test_orchestration.jl` | **Modifier** — remplacer test stub, ajouter intégration |
| `test/runtests.jl` | **Modifier** — enregistrer `test_descriptive_routing` |

---

## R6 — Points d'attention

1. **`NamedTuple(kwargs)`** : `kwargs` dans `solve_descriptive` est un `Base.Pairs`.
   Il faut le convertir en `NamedTuple` pour `route_all_options`. Utiliser `(; kwargs...)`.

2. **Splatting des options routées** : `routed.strategies.discretizer` est un `NamedTuple`.
   Le splatting `routed.strategies.discretizer...` passe les options comme kwargs à
   `build_strategy_from_method`.

3. **`_complete_description` existe déjà** dans `helpers/strategy_builders.jl` — la
   réutiliser directement.

4. **`CTSolvers.Orchestration`** est importé via `src/imports/ctsolvers.jl` mais
   `route_all_options` n'est pas encore importé. Il faudra vérifier si un import
   supplémentaire est nécessaire ou si l'accès qualifié `CTSolvers.Orchestration.route_all_options`
   suffit.

5. **`CTSolvers.Options.OptionDefinition`** est importé comme `OptionDefinition` dans
   `ctsolvers.jl` — utiliser ce nom court dans les helpers.