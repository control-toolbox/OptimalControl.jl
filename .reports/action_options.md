# Action Options — Rapport de conception

## Objectif

Transformer `initial_guess` et `display` en **options d'action** routées via le mécanisme
`CTSolvers.route_all_options`, afin de :

1. Supporter des **aliases** (`init`, `i` pour `initial_guess`)
2. Détecter les **conflits** entre options d'action et options de stratégies
3. Unifier la signature de `solve` : tout passe par `kwargs...`

---

## Concepts clés

### Option d'action vs option de stratégie

| Type | Propriétaire | Exemple | Traitement |
|---|---|---|---|
| **Action** | L'orchestrateur (Layer 1/2) | `initial_guess`, `display` | Extrait *avant* le routage |
| **Stratégie** | Un composant (discretizer, modeler, solver) | `grid_size`, `max_iter` | Routé vers le composant |

### Priorité action

Si une option apparaît à la fois dans `action_defs` et dans les métadonnées d'une stratégie :

- **Sans `route_to`** → l'action gagne (extraite en premier par `extract_options`)
- **Avec `route_to(ipopt=val)`** → l'option est dans `remaining_kwargs` après extraction action, donc routée à la stratégie normalement

Cette priorité est **naturelle** : `extract_options` retire les options d'action de `kwargs`
*avant* que le routeur de stratégies ne les voie. Un `route_to` explicite échappe à cette
extraction car la valeur est un `RoutedOption`, pas une valeur brute.

---

## Côté CTSolvers — Ce qui existe déjà

### `OptionDefinition` (`src/Options/option_definition.jl`)

Supporte nativement :
- `aliases::Tuple{Vararg{Symbol}}` — noms alternatifs reconnus par `extract_option`
- `default=nothing` → crée `OptionDefinition{Any}` avec `type=Any` automatiquement
- `validator` — fonction de validation optionnelle

```julia
# Exemple : initial_guess avec aliases
OptionDefinition(
    name=:initial_guess,
    aliases=(:init, :i),
    type=Any,
    default=nothing,
    description="Initial guess for the OCP solution"
)
```

### `extract_option` (`src/Options/extraction.jl`)

Parcourt `all_names(def)` (= `(name, aliases...)`) dans `kwargs`. Si trouvé :
- Valide le type
- Applique le validator
- Retire la clé de `kwargs`
- Retourne `OptionValue(value, :user)`

Si non trouvé : retourne `OptionValue(default, :default)`.

### `route_all_options` (`src/Orchestration/routing.jl`)

```julia
function route_all_options(method, families, action_defs, kwargs, registry; source_mode=:description)
    # Étape 1 : extraction des options d'action (AVANT tout routage)
    action_options, remaining_kwargs = Options.extract_options(kwargs, action_defs)

    # Étapes 2-4 : routage des remaining_kwargs vers les familles de stratégies
    # ...

    return (action=action_nt, strategies=strategy_options)
end
```

**Retour** : `(action=NamedTuple, strategies=NamedTuple)` où :
- `action` : `Dict{Symbol, OptionValue}` converti en `NamedTuple` (clés = noms primaires)
- `strategies` : `NamedTuple` avec sous-tuples par famille (`discretizer`, `modeler`, `solver`)

### `OptionValue` (`src/Options/option_value.jl`)

Wrapper avec provenance :
```julia
struct OptionValue
    value::Any
    source::Symbol  # :user ou :default
end
```

Pour extraire la valeur brute : `CTSolvers.value(opt_value)` ou `opt_value.value`.

---

## Ce qui manque dans CTSolvers

### Problème : ambiguïté action ↔ stratégie non détectée

Actuellement, si une stratégie déclare une option `display` ou `initial_guess`, et que
l'utilisateur écrit `solve(ocp; display=false)` **sans** `route_to`, l'action gagne
silencieusement. C'est le comportement voulu, mais il n'est **pas documenté** et aucune
erreur n'est levée si l'utilisateur voulait cibler la stratégie.

**Modification suggérée dans `route_all_options`** : après l'extraction des action options,
vérifier si une clé extraite comme action option est *aussi* connue d'une stratégie. Si oui,
enrichir le message d'erreur de `_error_ambiguous_option` pour mentionner que l'option est
aussi une option d'action, et suggérer `route_to` pour cibler explicitement la stratégie.

```julia
# Après l'extraction des action options :
action_names = Set(keys(action_options))
for (key, raw_val) in pairs(remaining_kwargs)
    # ... logique existante ...
end

# Nouveau : détecter les options d'action qui sont aussi dans les stratégies
for (key, opt_val) in action_options
    if haskey(option_owners, key) && !isempty(option_owners[key])
        # L'option est à la fois action et stratégie
        # → ajouter un avertissement ou une note dans les messages d'erreur
        # (pas une erreur : la priorité action est le comportement voulu)
    end
end
```

> **Note** : cette modification est optionnelle pour une première implémentation.
> La priorité action fonctionne correctement sans elle.

### Résumé des modifications CTSolvers

| Fichier | Modification | Priorité |
|---|---|---|
| `src/Orchestration/routing.jl` | Documenter la priorité action dans la docstring de `route_all_options` | Faible |
| `src/Orchestration/routing.jl` | Optionnel : détecter et signaler les options action/stratégie en conflit | Optionnel |

**Conclusion** : CTSolvers n'a pas besoin de modification fonctionnelle. L'infrastructure
est déjà en place. Seule une mise à jour de documentation est souhaitable.

---

## Côté OptimalControl — Ce qu'il faut faire

### Vue d'ensemble de la chaîne d'appel actuelle

```
CommonSolve.solve(ocp, description...; initial_guess=nothing, display=true, kwargs...)
    │
    ├─ ExplicitMode → solve_explicit(ocp; initial_guess=init, display=d, ...)
    │
    └─ DescriptiveMode → solve_descriptive(ocp, desc...; initial_guess=init, display=d, kwargs...)
                              └─ _route_descriptive_options(desc, registry, kwargs)
                                    └─ CTSolvers.route_all_options(...)  # action_defs = []
                              └─ _build_components_from_routed(desc, registry, routed)
                              └─ CommonSolve.solve(ocp, init, disc, mod, sol; display=d)
```

### Vue d'ensemble de la chaîne d'appel cible

```
CommonSolve.solve(ocp, description...; kwargs...)   # plus de named args
    │
    ├─ ExplicitMode → solve_explicit(ocp; registry, kwargs...)
    │                     └─ extrait init, display, disc, mod, sol de kwargs (avec aliases)
    │
    └─ DescriptiveMode → solve_descriptive(ocp, desc...; registry, kwargs...)
                              └─ _route_descriptive_options(desc, registry, kwargs)
                                    └─ CTSolvers.route_all_options(...)
                                          # action_defs = [initial_guess (aliases: init, i), display]
                                          # → routed.action.initial_guess, routed.action.display
                              └─ _build_components_from_routed(ocp, desc, registry, routed)
                                    # reçoit ocp pour appeler build_initial_guess
                              └─ CommonSolve.solve(
                                    ocp, components.initial_guess,
                                    components.discretizer, components.modeler, components.solver;
                                    display=components.display
                                 )
```

---

## Modifications détaillées — OptimalControl

### 1. `src/solve/dispatch.jl`

**Avant :**
```julia
function CommonSolve.solve(
    ocp::CTModels.AbstractModel,
    description::Symbol...;
    initial_guess=nothing,
    display::Bool=__display(),
    kwargs...
)::CTModels.AbstractSolution
    mode = _explicit_or_descriptive(description, kwargs)
    normalized_init = CTModels.build_initial_guess(ocp, initial_guess)
    registry = _extract_kwarg(kwargs, CTSolvers.StrategyRegistry)
    # ...
    if mode isa ExplicitMode
        return solve_explicit(ocp; initial_guess=normalized_init, display=display, ...)
    else
        return solve_descriptive(ocp, description...; initial_guess=normalized_init, display=display, kwargs...)
    end
end
```

**Après :**
```julia
function CommonSolve.solve(
    ocp::CTModels.AbstractModel,
    description::Symbol...;
    kwargs...                    # tout passe par kwargs
)::CTModels.AbstractSolution
    mode = _explicit_or_descriptive(description, kwargs)
    registry = _extract_kwarg(kwargs, CTSolvers.StrategyRegistry)
    registry = isnothing(registry) ? get_strategy_registry() : registry

    if mode isa ExplicitMode
        return solve_explicit(ocp; registry=registry, kwargs...)
    else
        return solve_descriptive(ocp, description...; registry=registry, kwargs...)
    end
end
```

**Points clés :**
- `initial_guess` et `display` ne sont plus extraits ici.
- `registry` reste extrait par type (pas d'alias nécessaire).
- `normalized_init` (appel à `build_initial_guess`) est déplacé dans les layers 2.

---

### 2. `src/helpers/descriptive_routing.jl`

#### `_descriptive_action_defs()` — remplir avec les vraies définitions

```julia
function _descriptive_action_defs()::Vector{CTSolvers.OptionDefinition}
    return [
        CTSolvers.OptionDefinition(
            name        = :initial_guess,
            aliases     = (:init, :i),
            type        = Any,
            default     = nothing,
            description = "Initial guess for the OCP solution"
        ),
        CTSolvers.OptionDefinition(
            name        = :display,
            aliases     = (),
            type        = Bool,
            default     = __display(),
            description = "Display solve configuration"
        ),
    ]
end
```

#### `_build_components_from_routed()` — ajouter `ocp` et extraire les action options

```julia
function _build_components_from_routed(
    ocp::CTModels.AbstractModel,           # nouveau paramètre
    complete_description::Tuple{Symbol, Symbol, Symbol},
    registry::CTSolvers.StrategyRegistry,
    routed::NamedTuple,
)
    # Stratégies (inchangé)
    discretizer = CTSolvers.build_strategy_from_method(
        complete_description, CTDirect.AbstractDiscretizer, registry;
        routed.strategies.discretizer...
    )
    modeler = CTSolvers.build_strategy_from_method(
        complete_description, CTSolvers.AbstractNLPModeler, registry;
        routed.strategies.modeler...
    )
    solver = CTSolvers.build_strategy_from_method(
        complete_description, CTSolvers.AbstractNLPSolver, registry;
        routed.strategies.solver...
    )

    # Action options — unwrapper les OptionValue
    init_raw = get(routed.action, :initial_guess, nothing)
    init_val = init_raw isa CTSolvers.OptionValue ? init_raw.value : init_raw
    normalized_init = CTModels.build_initial_guess(ocp, init_val)

    display_raw = get(routed.action, :display, __display())
    display_val = display_raw isa CTSolvers.OptionValue ? display_raw.value : display_raw

    return (
        discretizer   = discretizer,
        modeler       = modeler,
        solver        = solver,
        initial_guess = normalized_init,
        display       = display_val,
    )
end
```

---

### 3. `src/solve/descriptive.jl`

**Avant :**
```julia
function solve_descriptive(
    ocp, description...;
    initial_guess::CTModels.AbstractInitialGuess,
    display::Bool,
    registry::CTSolvers.StrategyRegistry,
    kwargs...
)
    complete_description = _complete_description(description)
    routed = _route_descriptive_options(complete_description, registry, kwargs)
    components = _build_components_from_routed(complete_description, registry, routed)
    return CommonSolve.solve(ocp, initial_guess, components.discretizer,
                             components.modeler, components.solver; display=display)
end
```

**Après :**
```julia
function solve_descriptive(
    ocp, description...;
    registry::CTSolvers.StrategyRegistry,
    kwargs...
)
    complete_description = _complete_description(description)
    routed = _route_descriptive_options(complete_description, registry, kwargs)
    components = _build_components_from_routed(ocp, complete_description, registry, routed)
    return CommonSolve.solve(
        ocp, components.initial_guess,
        components.discretizer, components.modeler, components.solver;
        display=components.display
    )
end
```

**Points clés :**
- `initial_guess` et `display` disparaissent de la signature.
- `ocp` est passé à `_build_components_from_routed` pour `build_initial_guess`.

---

### 4. `src/solve/explicit.jl`

En mode explicite, `initial_guess` et `display` ne passent pas par `route_all_options`
(pas de description symbolique). Il faut les extraire manuellement de `kwargs` avec aliases.

Ajouter un helper dans `src/helpers/` (ou dans `explicit.jl`) :

```julia
function _extract_action_kwarg(kwargs, names::Tuple{Vararg{Symbol}}, default)
    present = [n for n in names if haskey(kwargs, n)]
    if isempty(present)
        return default, kwargs
    elseif length(present) == 1
        name = present[1]
        value = kwargs[name]
        remaining = NamedTuple(k => v for (k, v) in pairs(kwargs) if k != name)
        return value, remaining
    else
        throw(CTBase.IncorrectArgument(
            "Conflicting aliases",
            got="multiple aliases $(present) for the same option",
            expected="at most one of $(names)",
            suggestion="Use only one alias at a time",
            context="solve - action option extraction"
        ))
    end
end
```

**Après :**
```julia
function solve_explicit(
    ocp::CTModels.AbstractModel;
    registry::CTSolvers.StrategyRegistry,
    kwargs...
)::CTModels.AbstractSolution
    init_raw, kwargs1  = _extract_action_kwarg(kwargs, (:initial_guess, :init, :i), nothing)
    display_val, _     = _extract_action_kwarg(kwargs1, (:display,), __display())
    discretizer        = _extract_kwarg(kwargs1, CTDirect.AbstractDiscretizer)
    modeler            = _extract_kwarg(kwargs1, CTSolvers.AbstractNLPModeler)
    solver             = _extract_kwarg(kwargs1, CTSolvers.AbstractNLPSolver)

    normalized_init = CTModels.build_initial_guess(ocp, init_raw)

    components = if _has_complete_components(discretizer, modeler, solver)
        (discretizer=discretizer, modeler=modeler, solver=solver)
    else
        _complete_components(discretizer, modeler, solver, registry)
    end

    return CommonSolve.solve(
        ocp, normalized_init,
        components.discretizer, components.modeler, components.solver;
        display=display_val
    )
end
```

---

## Comportement des aliases — exemples utilisateur

```julia
# Tous équivalents :
solve(ocp; initial_guess=x)
solve(ocp; init=x)
solve(ocp; i=x)

# Erreur : deux aliases en même temps
solve(ocp; init=x, i=y)
# → IncorrectArgument: Conflicting aliases [:init, :i]

# Conflit action/stratégie : si Ipopt déclare aussi `display`
solve(ocp; display=false)
# → action gagne : display=false pour l'orchestrateur uniquement

solve(ocp; display=route_to(ipopt=false))
# → stratégie gagne : display=false pour Ipopt uniquement
# (mais si Ipopt ne déclare pas `display`, erreur "option inconnue")
```

## Limitation : impossible de passer une option à la fois à l'action ET à une stratégie

En mode descriptif, `extract_options` **retire** l'option d'action de `kwargs` avant que
le routeur de stratégies ne la voie. Une option ne peut donc avoir qu'un seul propriétaire
dans un appel donné.

**Si l'utilisateur veut passer `display=false` à la fois à l'orchestrateur et à Ipopt**,
il doit utiliser le **mode explicite** :

```julia
# Mode explicite : contrôle total
solver = CTSolvers.Ipopt(display=false)    # display=false pour Ipopt
solve(ocp; solver=solver, display=false)   # display=false aussi pour l'orchestrateur
```

C'est cohérent avec la philosophie des deux modes :

- **Mode descriptif** — simplicité : l'orchestrateur gère tout, les options sont routées
  automatiquement. Les options d'action ont la priorité.
- **Mode explicite** — contrôle total : l'utilisateur construit les composants lui-même
  et peut passer n'importe quelle option à n'importe quel composant.

> Cette limitation doit être documentée dans la docstring de `CommonSolve.solve`.

---

## Fichiers à modifier — récapitulatif

| Fichier | Nature du changement |
|---|---|
| `src/solve/dispatch.jl` | Supprimer `initial_guess` et `display` de la signature |
| `src/solve/descriptive.jl` | Supprimer `initial_guess` et `display` de la signature, lire depuis `components` |
| `src/solve/explicit.jl` | Extraire `initial_guess`/`display` de `kwargs` avec aliases via helper |
| `src/helpers/descriptive_routing.jl` | Remplir `_descriptive_action_defs()`, passer `ocp` à `_build_components_from_routed` |
| `src/helpers/strategy_builders.jl` ou nouveau fichier | Ajouter `_extract_action_kwarg` |

## Tests à mettre à jour

| Fichier | Changement |
|---|---|
| `test/suite/solve/test_bypass.jl` | Adapter les appels (plus de `initial_guess=` en named arg explicite) |
| `test/suite/solve/test_orchestration.jl` | Idem |
| `test/suite/solve/test_dispatch.jl` | Idem |
| `test/suite/solve/test_descriptive_routing.jl` | Adapter `_build_components_from_routed` (nouveau param `ocp`) |
| `test/suite/solve/test_bypass.jl` ou nouveau fichier | Ajouter tests pour aliases `init` et `i` |

---

## Ordre d'implémentation recommandé

1. `_descriptive_action_defs()` — ajouter les définitions
2. `_build_components_from_routed` — ajouter `ocp`, extraire action options
3. `solve_descriptive` — simplifier la signature
4. `_extract_action_kwarg` — nouveau helper
5. `solve_explicit` — simplifier la signature
6. `CommonSolve.solve` — simplifier la signature
7. Mettre à jour les tests
