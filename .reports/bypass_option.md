# Design Report: `bypass` and `route_to` with Mode

**Date**: 2026-02-19
**Status**: Proposal
**Scope**: `CTSolvers.jl`

---

## 1. Problem Statement

There are two distinct use cases for bypassing option validation in `CTSolvers`:

### Use Case A — Mode Descriptif (Niveau 1)

L'utilisateur passe des options à plat dans `solve`. Le routeur (`route_all_options`)
décide où elles vont. Si une option est inconnue, c'est une erreur.

```julia
solve(ocp, :collocation, :adnlp, :ipopt;
    max_iter=100,                           # connu → routé automatiquement
    backend=route_to(adnlp=:sparse),        # ambigu → routé explicitement
    toto=route_to(ipopt=42),                # inconnu MAIS destination explicite
                                            # → erreur en mode strict actuel
)
```

**Contrainte fondamentale** : sans destination explicite, une option inconnue ne
peut pas être routée. `toto=42` seul est toujours une erreur, même en mode
permissif. Seul `route_to` peut forcer le passage d'une option inconnue, car il
fournit la destination.

### Use Case B — Mode Explicite (Niveau 2)

L'utilisateur construit les stratégies lui-même. Il peut vouloir passer des
options non déclarées dans les métadonnées CTSolvers directement au backend.

```julia
solve(ocp;
    modeler=Exa(toto=bypass(42)),   # option inconnue de CTSolvers, passée au backend Exa
    solver=Ipopt(max_iter=100),
)
```

L'utilisateur sait exactement à qui il parle. La permissivité est locale à la
stratégie.

---

## 2. Les Deux Mécanismes Proposés

### Mécanisme A — `route_to` avec `mode` (Use Case A)

Enrichir `route_to` d'un argument `mode` optionnel :

```julia
route_to(ipopt=42)                    # strict (défaut) : erreur si :ipopt ne connaît pas l'option
route_to(ipopt=42; mode=:permissive)  # permissif : passe sans validation
```

### Mécanisme B — `bypass(val)` (Use Case B)

Nouveau wrapper pour les constructeurs de stratégie :

```julia
Exa(toto=bypass(42))
Ipopt(max_iter=100, custom_option=bypass("value"))
```

Ces deux mécanismes sont **complémentaires et orthogonaux**. Ils opèrent à des
niveaux différents et ne se substituent pas l'un à l'autre.

---

## 3. Mécanisme A : `route_to` avec `bypass`

### 3.1 Interface utilisateur

```julia
# Strict (défaut) — erreur si :ipopt ne connaît pas :toto
toto = route_to(ipopt=42)

# Bypass — contourne la validation pour cette option spécifique
toto = route_to(ipopt=42; bypass=true)
```

Le paramètre `mode` reste réservé au contrôle **global** (`route_all_options`,
`build_strategy_options`, `build_strategy_from_method`). `bypass` est une action
**locale** à un seul `RoutedOption`, cohérente avec `bypass(val)` du Mécanisme B.

### 3.2 Changements dans CTSolvers

#### `src/Strategies/api/disambiguation.jl`

**Fichier actuel** : `RoutedOption` est un simple wrapper autour d'un `NamedTuple`.

```julia
struct RoutedOption
    routes::NamedTuple
end

function route_to(; kwargs...)
    return RoutedOption(NamedTuple(kwargs))
end
```

**Modification** : Ajouter un champ `mode` à `RoutedOption`.

```julia
struct RoutedOption
    routes::NamedTuple
    bypass::Bool   # false (défaut, strict) ou true (contourne la validation)

    function RoutedOption(routes::NamedTuple, bypass::Bool = false)
        isempty(routes) && throw(...)
        new(routes, bypass)
    end
end

function route_to(; bypass::Bool = false, kwargs...)
    isempty(kwargs) && throw(...)
    return RoutedOption(NamedTuple(kwargs), bypass)
end
```

**Impact** : Changement non-breaking car `mode` a une valeur par défaut. L'interface
existante `route_to(solver=100)` continue de fonctionner.

#### `src/Orchestration/routing.jl`

**Localisation** : Dans `route_all_options`, la branche qui traite les options
explicitement disambiguées (lignes ~143–178).

**Logique actuelle** :

```julia
if disambiguations !== nothing
    for (value, strategy_id) in disambiguations
        family_name = strategy_to_family[strategy_id]
        owners = get(option_owners, key, Set{Symbol}())

        if family_name in owners
            push!(routed[family_name], key => value)
        elseif isempty(owners) && mode == :permissive   # ← mode GLOBAL
            _warn_unknown_option_permissive(key, strategy_id, family_name)
            push!(routed[family_name], key => value)
        else
            # Error
        end
    end
end
```

**Modification** : Lire le mode depuis le `RoutedOption` lui-même plutôt que
depuis le mode global de `route_all_options`. Cela nécessite que
`extract_strategy_ids` (ou la boucle) ait accès au `RoutedOption` original.

```julia
if disambiguations !== nothing
    # Récupérer le flag bypass de ce RoutedOption spécifique
    local_bypass = (raw_val isa RoutedOption) ? raw_val.bypass : false

    for (value, strategy_id) in disambiguations
        family_name = strategy_to_family[strategy_id]
        owners = get(option_owners, key, Set{Symbol}())

        if family_name in owners
            push!(routed[family_name], key => value)
        elseif isempty(owners) && local_bypass   # ← bypass LOCAL
            _warn_unknown_option_permissive(key, strategy_id, family_name)
            push!(routed[family_name], key => value)
        else
            # Error (comme avant)
        end
    end
end
```

**Conséquence** : Le paramètre `mode` global de `route_all_options` reste
inchangé et continue de contrôler le comportement global. Le bypass est désormais
porté par chaque `RoutedOption` individuellement, orthogonalement au mode global.

#### `src/Orchestration/disambiguation.jl`

La fonction `extract_strategy_ids` retourne actuellement des paires
`(value, strategy_id)`. Elle n'a pas besoin de changer si on lit le mode
directement depuis `raw_val` dans la boucle principale (voir ci-dessus).

### 3.3 Impact en aval : `build_strategy_options`

Quand `route_all_options` place une option dans `routed[family_name]`, c'est
une paire `key => value` brute. Le mode permissif est déjà appliqué à ce stade
(l'option est acceptée dans le dict). Ensuite, `build_strategy_from_method` est
appelé avec ces options, en mode `:strict` par défaut.

**Question** : faut-il propager le mode permissif jusqu'à `build_strategy_options` ?

**Réponse** : Non, si on accepte l'option dans `route_all_options` (en mode
permissif), elle est déjà dans le dict des options routées. Quand
`build_strategy_options` la reçoit, elle sera dans `remaining` (options inconnues
de la stratégie). Il faut donc que `build_strategy_options` soit aussi appelé en
mode `:permissive` pour cette stratégie.

**Solution** : Retourner, en plus des options routées, un dict de modes par famille :

```julia
# Retour enrichi de route_all_options
(
    action    = (...),
    strategies = (
        discretizer = (grid_size = 100,),
        modeler     = (backend = :sparse,),
        solver      = (max_iter = 1000, toto = 42),  # toto accepté en permissif
    ),
    bypasses = (                                       # NOUVEAU
        discretizer = false,
        modeler     = false,
        solver      = true,                            # car toto était route_to(...; bypass=true)
    )
)
```

Puis dans `_build_components_from_routed` (OptimalControl) :

```julia
solver = build_strategy_from_method(method, AbstractNLPSolver, registry;
    mode = routed.bypasses.solver ? :permissive : :strict,
    routed.strategies.solver...
)
```

**Alternative plus simple** : Marquer les valeurs permissives avec un wrapper
interne `_PermissiveValue(val)` dans le dict routé, et laisser
`build_strategy_options` les détecter. Mais cela complexifie la sérialisation
des options.

**Recommandation** : Retourner les modes par famille dans le résultat de
`route_all_options`. C'est propre et explicite.

---

## 4. Mécanisme B : `bypass(val)`

### 4.1 Interface utilisateur

```julia
# Mode explicite : l'utilisateur construit la stratégie lui-même
solve(ocp;
    modeler = Exa(toto=bypass(42)),
    solver  = Ipopt(max_iter=100, custom_hook=bypass("myvalue")),
)
```

### 4.2 Nouveau type dans CTSolvers

#### `src/Strategies/api/bypass.jl` (nouveau fichier)

Deux éléments à définir :

- **`BypassValue{T}`** : struct paramétrique wrappant une valeur. Docstring avec
  `$(TYPEDEF)`, description, exemple d'usage `Exa(toto=bypass(42))`, et
  `See also: build_strategy_options`.
- **`bypass(val)`** : fonction constructeur retournant `BypassValue(val)`.
  Docstring avec `$(TYPEDSIGNATURES)`.

```julia
struct BypassValue{T}
    value::T
end

bypass(val) = BypassValue(val)
```

### 4.3 Modification de `build_strategy_options`

**Fichier** : `src/Strategies/api/configuration.jl`

**Logique actuelle** (lignes 72–113) :

```julia
function build_strategy_options(strategy_type; mode=:strict, kwargs...)
    meta = metadata(strategy_type)
    defs = collect(values(meta))
    extracted, remaining = Options.extract_options((; kwargs...), defs)

    if !isempty(remaining)
        if mode == :strict
            _error_unknown_options_strict(remaining, strategy_type, meta)
        else  # permissive
            _warn_unknown_options_permissive(remaining, strategy_type)
            for (key, value) in pairs(remaining)
                extracted[key] = Options.OptionValue(value, :user)
            end
        end
    end
    # ...
end
```

**Modification** : Avant d'appeler `extract_options`, détecter et extraire les
`BypassValue`. Ces options sont acceptées inconditionnellement, quel que soit le
mode global.

```julia
function build_strategy_options(strategy_type; mode=:strict, kwargs...)
    meta = metadata(strategy_type)
    defs = collect(values(meta))

    # Séparer les options bypass des options normales
    bypass_kwargs = NamedTuple(k => v.value for (k, v) in pairs(kwargs) if v isa BypassValue)
    normal_kwargs = NamedTuple(k => v       for (k, v) in pairs(kwargs) if !(v isa BypassValue))

    # Traitement normal des options connues
    extracted, remaining = Options.extract_options((; normal_kwargs...), defs)

    if !isempty(remaining)
        if mode == :strict
            _error_unknown_options_strict(remaining, strategy_type, meta)
        else
            _warn_unknown_options_permissive(remaining, strategy_type)
            for (key, value) in pairs(remaining)
                extracted[key] = Options.OptionValue(value, :user)
            end
        end
    end

    # Injecter les options bypass sans validation (avec warning)
    if !isempty(bypass_kwargs)
        @warn """
        Bypassed options passed to $(strategy_type)
        Options: $(keys(bypass_kwargs))
        These options bypass all validation and are passed directly to the backend.
        """
        for (key, value) in pairs(bypass_kwargs)
            extracted[key] = Options.OptionValue(value, :user)
        end
    end

    nt = (; (k => v for (k, v) in extracted)...)
    return StrategyOptions(nt)
end
```

**Avantage clé** : `bypass` est détecté au niveau le plus bas, là où les options
sont construites. Aucune propagation à travers la stack de routage n'est nécessaire.

### 4.4 Export dans CTSolvers

Dans `src/CTSolvers.jl` (ou le module `Strategies`) :

```julia
export bypass, BypassValue
```

Dans `OptimalControl.jl` (`src/imports/ctsolvers.jl`) :

```julia
@reexport import CTSolvers: bypass
```

---

## 5. Récapitulatif des Changements par Fichier

### Dans `CTSolvers.jl`

| Fichier | Changement | Complexité |
| --- | --- | --- |
| `src/Strategies/api/disambiguation.jl` | Ajouter `bypass::Bool` à `RoutedOption` + `route_to(; bypass=false, ...)` | Faible |
| `src/Orchestration/routing.jl` | Lire `raw_val.bypass` pour les `RoutedOption` ; retourner `bypasses` par famille | Moyenne |
| `src/Strategies/api/bypass.jl` | Nouveau fichier : `BypassValue{T}` + `bypass(val)` | Faible |
| `src/Strategies/api/configuration.jl` | Détecter `BypassValue` avant `extract_options` | Faible |
| `src/Strategies/Strategies.jl` | `include("api/bypass.jl")` + `export bypass, BypassValue` | Trivial |
| `src/CTSolvers.jl` | `export bypass` | Trivial |

### Dans `OptimalControl.jl`

| Fichier | Changement | Complexité |
| --- | --- | --- |
| `src/imports/ctsolvers.jl` | `@reexport import CTSolvers: bypass` | Trivial |
| `src/helpers/descriptive_routing.jl` | Propager `bypasses` depuis `route_all_options` vers `build_strategy_from_method` | Faible |

---

## 6. Flux Complets

### Flux A : `route_to` avec `bypass` (Niveau 1)

```text
solve(ocp, :collocation, :adnlp, :ipopt; toto=route_to(ipopt=42; bypass=true))
    │
    ▼
solve_descriptive(...)
    │
    ▼
_route_descriptive_options(...)
    │
    ▼
route_all_options(method, families, action_defs, kwargs, registry)
    │
    ├── kwargs.toto isa RoutedOption → local_bypass = true
    ├── owners de :toto = {} (inconnu)
    ├── local_bypass == true → warning + accepté dans routed[:solver]
    └── retourne (strategies=(solver=(toto=42,), ...), bypasses=(solver=true, ...))
    │
    ▼
_build_components_from_routed(method, routed, registry)
    │
    ▼
build_strategy_from_method(method, AbstractNLPSolver, registry;
    mode=:permissive,   # ← dérivé de routed.bypasses.solver
    toto=42
)
    │
    ▼
build_strategy(:ipopt, AbstractNLPSolver, registry; mode=:permissive, toto=42)
    │
    ▼
Ipopt(; mode=:permissive, toto=42)
    │
    ▼
build_strategy_options(Ipopt; mode=:permissive, toto=42)
    │
    ├── extract_options → remaining = {toto: 42}
    ├── mode == :permissive → warning + accepté
    └── StrategyOptions(max_iter=..., toto=42)
```

### Flux B : `bypass` (Niveau 2)

```text
solve(ocp; modeler=Exa(toto=bypass(42)))
    │
    ▼
solve_explicit(...)
    │
    ▼
Exa(toto=bypass(42))   # constructeur appelé directement par l'utilisateur
    │
    ▼
build_strategy_options(Exa; toto=BypassValue(42))
    │
    ├── bypass_kwargs = {toto: 42}   # détecté car BypassValue
    ├── normal_kwargs = {}
    ├── extract_options({}) → extracted = {}, remaining = {}
    ├── bypass_kwargs non vide → warning + injecté dans extracted
    └── StrategyOptions(toto=42)
```

---

## 7. Recommandation d'Implémentation

### Priorité 1 : Mécanisme B (`bypass`)

- Impact minimal, localisé à `build_strategy_options`.
- Cas d'usage le plus courant (utilisateur avancé en mode explicite).
- Aucune propagation de mode à travers la stack.
- Implémentable en ~50 lignes dans CTSolvers.

### Priorité 2 : Mécanisme A (`route_to` avec mode)

- Plus rare (passer une option inconnue via le mode descriptif).
- Nécessite de propager les modes par famille dans le retour de `route_all_options`.
- Implémentable après B, une fois le besoin confirmé.

### Ordre des changements pour Mécanisme B

1. Créer `src/Strategies/api/bypass.jl` avec `BypassValue{T}` et `bypass`.
2. Modifier `build_strategy_options` pour détecter `BypassValue` en amont.
3. Exporter `bypass` depuis `CTSolvers` et `Strategies`.
4. Réexporter `bypass` depuis `OptimalControl` via `src/imports/ctsolvers.jl`.
5. Ajouter des tests dans `CTSolvers/test/suite/strategies/test_bypass.jl`.

### Ordre des changements pour Mécanisme A

1. Ajouter `bypass::Bool` à `RoutedOption` + mettre à jour `route_to(; bypass=false, ...)`.
2. Modifier la boucle dans `route_all_options` pour lire `raw_val.bypass`.
3. Enrichir le retour de `route_all_options` avec un champ `bypasses`.
4. Mettre à jour `_build_components_from_routed` dans OptimalControl pour
   propager les bypasses (convertis en `mode=:permissive` si `true`).
5. Ajouter des tests.

---

## 8. Points Ouverts

- **Naming** : `bypass` vs `force` vs `unchecked`. `bypass` est retenu car il
  décrit l'action (contourner la validation) sans ambiguïté.
- **Warning vs Silence** : Les deux mécanismes émettent des warnings. Faut-il
  un argument `silent=true` pour les supprimer ? À décider selon les retours
  utilisateurs.
- **Suppression du mode global** : Une fois le Mécanisme A implémenté, le
  paramètre `mode` global de `route_all_options` devient redondant. Il peut être
  déprécié puis supprimé.
- **Type stability** : `BypassValue{T}` est paramétrique pour préserver la
  stabilité de type. `build_strategy_options` doit être testé avec `@inferred`.
