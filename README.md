# Realistic Book Pages [B42](https://steamcommunity.com/sharedfiles/filedetails/?id=3777767140)

Skill books should feel like real books, not five copies of the same book with increasingly large page counts.

**Realistic Book Pages** rebalances the length and weight of every canonical Project Zomboid skill book. Basic books are shorter, lighter, and faster to read, helping them serve as useful early-game accelerators. Advanced books take longer because they represent deeper, more specialized material and provide access to stronger XP multipliers.

The result is a progression in which surviving, reading, and learning fit together more naturally.

## Features

- Hand-balanced page counts for all 35 canonical skills.
- Shorter beginner and practical-survival books.
- Larger advanced technical and professional references.
- Short, focused combat manuals based on comparable real-world books.
- Dynamic book weight based on page count.
- Server-wide Sandbox controls for every canonical skill and tier.
- Fixed page values and per-spawn page ranges.
- Automatic support for expansion mods that create skill books through the standard game API.
- A fallback balance for correctly implemented books that train non-canonical skills.
- Page-first variation for ordinary books, magazines, recipe magazines, and newspapers, with weight derived from the resulting length.
- Recipe-magazine length based on a configurable base plus pages per taught recipe.
- Uncapped weight-scaled boredom, stress, and unhappiness effects, applied as pages are read.

## Sandbox and multiplayer configuration

The bundled values remain the defaults. Hosts and dedicated-server admins can change them through three Sandbox pages: **Base Configuration**, **Skill Books**, and **Other Literature**.

Each skill uses one field containing five values in this order:

`Beginner / Intermediate / Advanced / Expert / Master`

For example:

`56 / 104 / 192 / 304 / 416`

Each tier accepts either a fixed page count or a range:

- `120` sets the book to exactly 120 pages.
- `>80<240` gives every newly spawned book an inclusive random value from 80 through 240.
- `>80` uses 80 as the minimum and the global maximum as the upper bound.
- `<240` uses the global minimum as the lower bound and 240 as the maximum.

Range results are rolled when each book instance spawns. In multiplayer, only the server rolls the value; clients retain the synchronized value assigned to that instance. Two copies of the same skill book can therefore have different lengths without creating client/server disagreement. All fixed and ranged results are clamped to the global **Minimum Pages** and **Maximum Pages** options.

Other literature uses the same fixed-or-range syntax:

- **Ordinary Book Pages** controls hardcovers and paperbacks.
- **Miscellaneous Magazine Pages** controls qualifying non-recipe magazines.
- **Newspaper Pages** controls tagged newspapers.
- **Recipe Magazine Base Pages** supplies general and introductory content.
- **Pages per Taught Recipe** is multiplied by the number of recipes in that magazine and added to its base pages.

For example, a recipe magazine with a 10-page base, 4 pages per recipe, and two taught recipes receives `10 + (4 × 2) = 18 pages`. Base pages and pages per recipe may each be fixed or ranged. The completed total is clamped to the global page limits, then its weight is calculated from that total.

The Base Configuration page also controls the global limits and dynamic-weight formula, while the Skill Books page contains the fallback curve for non-canonical skills. Sandbox settings are world-wide and apply to all players. Changes made through a live admin Sandbox interface affect books spawned after the updated values reach the server; books that already exist are not rerolled.

Dedicated servers can edit the generated `RealisticBookPages` section in their `<servername>_SandboxVars.lua` file or use the host Sandbox UI. Editing this file on disk still requires the server to reload it. Existing books already serialized into a save retain their assigned page count and weight; newly generated books use the current configuration.

## Page balance

Each book covers two skill levels: Beginner covers levels 1–2, Intermediate 3–4, Advanced 5–6, Expert 7–8, and Master 9–10.

| Skill | Beginner | Intermediate | Advanced | Expert | Master | Total |
|---|---:|---:|---:|---:|---:|---:|
| Carving | 56 | 104 | 192 | 304 | 416 | **1,072** |
| Flint Knapping | 56 | 112 | 176 | 232 | 304 | **880** |
| Trapping | 72 | 112 | 176 | 256 | 372 | **988** |
| Butchering | 80 | 104 | 160 | 256 | 384 | **984** |
| Fishing | 80 | 128 | 192 | 272 | 368 | **1,040** |
| Foraging | 88 | 160 | 248 | 352 | 480 | **1,328** |
| First Aid | 96 | 168 | 272 | 432 | 592 | **1,560** |
| Maintenance | 72 | 128 | 192 | 304 | 416 | **1,112** |
| Tailoring | 80 | 160 | 256 | 384 | 544 | **1,424** |
| Pottery | 88 | 128 | 208 | 320 | 448 | **1,192** |
| Cooking | 96 | 144 | 240 | 400 | 608 | **1,488** |
| Tracking | 104 | 144 | 224 | 336 | 480 | **1,288** |
| Metalworking | 112 | 216 | 304 | 480 | 656 | **1,768** |
| Mechanics | 136 | 240 | 336 | 504 | 672 | **1,888** |
| Electricity | 152 | 224 | 352 | 456 | 640 | **1,824** |
| Farming | 104 | 184 | 288 | 448 | 608 | **1,608** |
| Glassmaking | 96 | 176 | 288 | 456 | 640 | **1,656** |
| Husbandry | 112 | 192 | 320 | 488 | 648 | **1,760** |
| Blacksmithing | 120 | 176 | 298 | 464 | 656 | **1,714** |
| Carpentry | 96 | 176 | 288 | 448 | 608 | **1,616** |
| Masonry | 80 | 160 | 256 | 400 | 576 | **1,472** |
| Aiming | 80 | 120 | 176 | 248 | 352 | **976** |
| Reloading | 64 | 96 | 128 | 176 | 256 | **720** |
| Long Blade | 96 | 136 | 192 | 304 | 416 | **1,144** |
| Comparison | - | - | - | - | - | - |
| Default Game Values | 220 | 260 | 300 | 340 | 380 | **35040** |
| Realistic Book Values | >56<120 | >80<240 | >128<352 | >176<504 | >256<672 | **32502** |

### Extended for Skill Book Mods
| Skill | Beginner | Intermediate | Advanced | Expert | Master | Total |
|---|---:|---:|---:|---:|---:|---:|
| Spear | 64 | 88 | 144 | 208 | 288 | **792** |
| Short Blunt | 64 | 80 | 112 | 160 | 208 | **624** |
| Long Blunt | 72 | 96 | 128 | 176 | 256 | **728** |
| Axe | 72 | 104 | 128 | 176 | 256 | **736** |
| Short Blade | 80 | 104 | 144 | 208 | 304 | **840** |
| Strength | 96 | 128 | 168 | 272 | 416 | **1,080** |
| Fitness | 104 | 136 | 184 | 304 | 464 | **1,192** |
| Running | 72 | 112 | 176 | 248 | 352 | **960** |
| Nimble | 80 | 136 | 184 | 280 | 416 | **1,096** |
| Lightfooted | 88 | 112 | 152 | 192 | 272 | **816** |
| Sneaking | 96 | 120 | 176 | 256 | 352 | **1,000** |
| Total |  |  |  |  |  | **9864** |

## Balance philosophy

### Basic knowledge should be accessible

Beginner books contain less material and are faster to finish. Finding an introductory Carving, Flint Knapping, Trapping, or Fishing book early means the survivor can study briefly and then put that knowledge to use in the wilderness.

These books are intended to accelerate the opening stages of a skill. They still require time and safety to read, but they no longer feel like oversized academic textbooks.

### Technical depth requires more study

Mechanics, Electricity, Metalworking, Blacksmithing, Husbandry, and other technical subjects grow into substantial reference books at their higher tiers. A survivor attempting to master complex machinery or specialized production should expect more theory, procedures, diagrams, and reference material than someone learning the fundamentals of a narrow practical skill.

This also fits the usual stage of a playthrough. Deeply technical books are generally more valuable once a survivor has established enough safety to spend longer periods studying. Their additional pages also make them heavier.

### Skill books are not linear

Higher-tier books cover increasingly complex material and unlock stronger XP multipliers. Their reading time therefore grows with the depth and usefulness of the knowledge they contain. The tiers are deliberately not distributed through a single linear formula, and different skills do not share an artificial total-page target.

The balance was created by hand using three main references:

1. **Real-world book sizes and subject complexity.** Narrow practical guides are usually shorter than complete technical references.
2. **The point in a playthrough when a skill is normally used.** Immediate survival knowledge is quicker to access, while advanced industrial knowledge requires a larger investment.
3. **The existing in-game book titles.** Titles that imply essential guides, professional instruction, complete techniques, or comprehensive reference works influenced the relative size of each tier.

### The cooking exception

Cookbooks are often long without being equally dense in pure technical instruction. They contain photographs, illustrations, ingredient lists, individual recipes, variations, and generous page layouts. Cooking books are therefore allowed to grow substantially while still remaining faster to approach at their first tiers.

### Why are combat books shorter?

Real-world books about aiming, reloading, weapon handling, and basic fighting techniques are commonly thin field manuals or focused instructional guides. Much of the actual improvement comes from practice rather than reading hundreds of pages of theory.

Combat books are consequently shorter than books about advanced mechanics, electrical systems, or metalworking. Higher tiers still grow, but they do not become implausibly large encyclopedias.


## Dynamic book weight

Vanilla assigns every skill book a weight of 1.0 regardless of its length. This mod makes short guides lighter and large technical references heavier.

A 220-page book remains the reference weight of 1.0. A fixed portion represents the cover and binding, while the remaining weight scales with the number of pages:

`Weight = 0.25 + (0.75 × pages ÷ 220)`

| Example length | Resulting weight |
|---:|---:|
| 56 pages | 0.44 |
| 80 pages | 0.52 |
| 220 pages | 1.00 |
| 352 pages | 1.45 |
| 480 pages | 1.89 |
| 608 pages | 2.32 |
| 672 pages | 2.54 |

### Other literature and mood effects

Ordinary books, miscellaneous magazines weighing 0.5 by default, recipe magazines, and newspapers now roll their page count first. Their weight is then derived from the final length using the same reference-page formula. Recipe magazines additionally scale with the number of recipes they teach, avoiding large magazines with very little instructional content.

The original item weight remains the baseline for mood effects: a hardcover reduced from 1.0 to 0.5 weight provides half its original benefit, while a paperback whose original weight is already 0.5 retains its full benefit. The multiplier is uncapped, so larger variants provide proportionally larger total effects.

Boredom, stress, and unhappiness changes are granted for newly read pages instead of all at completion. Interrupted books resume from their saved page without rewarding the same pages again. Both weight scaling and gradual effects can be disabled under **Other Literature**.

## Expansion-mod compatibility

The mod discovers loaded skill books through Project Zomboid's item API instead of maintaining a hard-coded list of item IDs. Expansion mods are supported automatically when their books follow the standard game structure:

- `SkillTrained` identifies the trained skill;
- `LvlSkillTrained` starts at level 1, 3, 5, 7, or 9; and
- `NumLevelsTrained` is set to 2.

Books for canonical skills receive the corresponding hand-balanced curve, including common internal skill-name aliases such as `Woodwork`, `Doctor`, `SmallBlade`, and `Sprinting`.

Books for properly implemented non-canonical skills receive the fallback progression of **120 / 220 / 280 / 360 / 440 pages**. Their weight is calculated from those page counts in the same way as canonical books.

Mods that use nonstandard tier structures or do not expose their skill books through the expected game properties cannot be balanced reliably and are left outside the automatic compatibility scope.

Correctly tagged expansion-mod hardcovers, paperbacks, magazines, recipe magazines, and newspapers are also supported. Recipe magazines use the size of their standard `LearnedRecipes` collection; dynamically generated literature with one `learnedRecipe` entry is counted as teaching one recipe. Literature that does not expose its content through the standard item API may require explicit registration.

### Pre-initialization API

Expansion mods can register a five-tier curve before world initialization:

```lua
RealisticBookPages.registerSkill(
    "MyCustomSkill",
    { 80, ">100<180", 240, 360, 480 },
    { "MyCustomSkillAlias" }
)
```

Server-side code can override a complete curve with `setPageCurve`, one tier with `setPageSpec`, or the non-canonical fallback with `setFallbackCurve`. Lua callers may pass real numbers or range strings. Call `RealisticBookPages.apply()` if an override is registered after initialization; registering before `OnInitWorld` is preferred.

Other literature can be registered and configured before initialization:

```lua
RealisticBookPages.registerLiterature(
    "MyMod.RecipeMagazine",
    "recipeMagazine"
)

RealisticBookPages.setLiteraturePageSpec(
    "magazine",
    ">16<72"
)

RealisticBookPages.setRecipeMagazinePageSpecs(
    ">10<20",
    4
)
```

Supported literature kinds are `ordinaryBook`, `magazine`, `recipeMagazine`, and `newspaper`. `setLiteraturePageSpec` accepts a fixed number or range string. Recipe magazines use `setRecipeMagazinePageSpecs(basePages, pagesPerRecipe)` so both parts can be configured independently.

## What the mod changes

Qualifying skill books can change:

- `NumberOfPages`
- `Weight`

Qualifying ordinary books, magazines, recipe magazines, and newspapers also receive instance-specific pages and weight. Their boredom, stress, and unhappiness values scale from original weight and can be consumed progressively while reading. The mod does not replace complete vanilla item definitions.

## Installation

1. Subscribe to the mod and enable **Realistic Book Pages** from the Mods menu.
2. Start a new game or enable it for an existing save.
3. For multiplayer, the server must include `RealisticBookPages` in its `Mods` list.

Books generated after the mod is enabled use the new values. Books that were already serialized in an existing save may retain their previous page count and weight.
