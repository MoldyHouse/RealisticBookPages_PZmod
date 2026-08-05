# Realistic Book Pages

Skill books should feel like real books, not five copies of the same book with increasingly large page counts.

**Realistic Book Pages** rebalances the length and weight of every canonical Project Zomboid skill book. Basic books are shorter, lighter, and faster to read, helping them serve as useful early-game accelerators. Advanced books take longer because they represent deeper, more specialized material and provide access to stronger XP multipliers.

The result is a progression in which surviving, reading, and learning fit together more naturally.

## Features

- Hand-balanced page counts for all 35 canonical skills.
- Shorter beginner and practical-survival books.
- Larger advanced technical and professional references.
- Short, focused combat manuals based on comparable real-world books.
- Dynamic book weight based on page count.
- Automatic support for expansion mods that create skill books through the standard game API.
- A fallback balance for correctly implemented books that train non-canonical skills.
- Recipe magazines and unrelated literature remain unchanged.
- Build 42 compatible.

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
| Farming | 80 | 184 | 288 | 448 | 608 | **1,608** |
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
| Default Game Values | >56<120 | >80<240 | >128<352 | >176<504 | >256<672 | **32502** |

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

## Expansion-mod compatibility

The mod discovers loaded skill books through Project Zomboid's item API instead of maintaining a hard-coded list of item IDs. Expansion mods are supported automatically when their books follow the standard game structure:

- `SkillTrained` identifies the trained skill;
- `LvlSkillTrained` starts at level 1, 3, 5, 7, or 9; and
- `NumLevelsTrained` is set to 2.

Books for canonical skills receive the corresponding hand-balanced curve, including common internal skill-name aliases such as `Woodwork`, `Doctor`, `SmallBlade`, and `Sprinting`.

Books for properly implemented non-canonical skills receive the fallback progression of **120 / 220 / 280 / 360 / 440 pages**. Their weight is calculated from those page counts in the same way as canonical books.

Mods that use nonstandard tier structures or do not expose their skill books through the expected game properties cannot be balanced reliably and are left outside the automatic compatibility scope.

## What the mod changes

Only two properties are changed on qualifying skill books:

- `NumberOfPages`
- `Weight`

The mod does not replace complete vanilla item definitions. Recipe magazines, ordinary books, newspapers, journals, and other literature are not modified.

## Installation

1. Subscribe to the mod and enable **Realistic Book Pages** from the Mods menu.
2. Start a new game or enable it for an existing save.
3. For multiplayer, the server must include `RealisticBookPages` in its `Mods` list.

Books generated after the mod is enabled use the new values. Books that were already serialized in an existing save may retain their previous page count and weight.
