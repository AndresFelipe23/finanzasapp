```markdown
# Design System Specification: Latam Neo-Banking

## 1. Overview & Creative North Star: "The Digital Alchemist"
This design system is a high-energy synthesis of Colombian prosperity and cutting-edge financial technology. Our Creative North Star is **"The Digital Alchemist"**—a philosophy that transforms raw data into a vibrant, editorial-grade financial journey. 

Rather than following the rigid, boxy constraints of traditional banking, this system utilizes **intentional asymmetry** and **tonal layering**. We break the "template" look by overlapping glassmorphism elements over vibrant gradients, creating a UI that feels less like a utility and more like a premium lifestyle magazine. Every interaction should feel like a pulse of energy, moving away from flat, static grids toward a fluid, layered experience.

---

## 2. Colors: Vibrancy & Tonal Depth
Our palette is a celebration of momentum. We use high-chroma accents against a sophisticated neutral foundation to ensure professional credibility while maintaining a "vibrant" Latam spirit.

### Palette Strategy
*   **Electric Blue (Primary):** The engine of the UI. Used for critical actions and brand presence.
*   **Emerald Green (Secondary):** Symbolizing *Prosperidad*. Used for growth indicators, 'Metas' (goals), and positive financial shifts.
*   **Soft Violet (Tertiary):** Used for accents and "premium" features to add depth and a modern tech-edge.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to section content. Boundaries must be defined through:
1.  **Background Shifts:** Place a `surface-container-low` card on a `surface` background.
2.  **Tonal Transitions:** Use soft shifts in saturation to denote new sections.

### The "Glass & Gradient" Rule
To achieve "High-Gloss" sophistication, main CTAs and Hero sections should utilize a linear gradient (45°) transitioning from `primary` (#0546ed) to `primary-container` (#849aff). Floating elements (Modals, Overlays) must use **Glassmorphism**: a semi-transparent `surface` color with a 20px-40px backdrop-blur.

---

## 3. Typography: Editorial Tech
We use **Plus Jakarta Sans** for its geometric precision and modern "tech-forward" spirit. Our type scale is intentionally dramatic to create a clear information hierarchy.

| Role | Token | Size | Weight | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | 3.5rem | 700 | Large 'Patrimonio' totals. |
| **Headline** | `headline-md` | 1.75rem | 600 | Page titles like 'Tus Metas'. |
| **Title** | `title-md` | 1.125rem | 500 | Card headers and section names. |
| **Body** | `body-lg` | 1rem | 400 | Transaction details and descriptions. |
| **Label** | `label-md` | 0.75rem | 600 | All-caps navigation or metadata. |

**Hierarchy Note:** Use high-contrast scale shifts. A `display-lg` balance should sit near a `label-md` timestamp to create an authoritative, editorial feel.

---

## 4. Elevation & Depth: The Layering Principle
We move beyond shadows to "Tonal Layering." Depth is achieved by stacking `surface-container` tiers.

*   **Nesting Hierarchy:** 
    *   **Base:** `surface` (#f5f6f7)
    *   **Section:** `surface-container-low` (#eff1f2)
    *   **Card:** `surface-container-lowest` (#ffffff)
*   **Ambient Shadows:** When a "floating" effect is required (e.g., for a 'Cuentas' selector), use an extra-diffused shadow: `box-shadow: 0 20px 40px rgba(12, 15, 16, 0.06)`. Note the tint is derived from `inverse-surface`, not pure black.
*   **The Ghost Border:** If accessibility requires a stroke, use `outline-variant` (#abadae) at 15% opacity. Never 100%.

---

## 5. Components: Neo-Banking Elements

### High-Gloss Cards ('Tarjetas')
*   **Structure:** No borders. Background: `surface-container-lowest`. 
*   **Rounding:** Always `xl` (1.5rem / ROUND_SIXTEEN).
*   **Gloss:** Add a subtle 45° white-to-transparent gradient overlay at 5% opacity to mimic light hitting a physical card.

### Buttons ('Acciones')
*   **Primary:** `primary` fill with `on-primary` text. No border. Apply a subtle `primary-dim` glow on hover.
*   **Secondary:** Glassmorphism style. Semi-transparent `secondary-container` with `on-secondary-container` text.
*   **States:** Use `primary-fixed-dim` for active/pressed states to maintain high energy.

### Data Lists ('Movimientos')
*   **Rule:** Forbid divider lines.
*   **Spacing:** Use `0.75rem` (md) vertical padding and subtle background alternates (`surface` vs `surface-container-low`) to separate transaction items.
*   **Terminology:** Use 'Abono' for credits and 'Cargo' for debits.

### Financial Terminology (Localización)
*   **Patrimonio:** Total net worth display.
*   **Metas de Ahorro:** Savings goals with Emerald Green (`secondary`) progress bars.
*   **Cuentas Vinculadas:** Linked accounts.
*   **Transferir:** Primary call to action.

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical layouts where text is left-aligned and glass elements are slightly offset to the right.
*   **Do** use backdrop-blur on all navigation bars to let the vibrant "Electric Blue" background bleed through.
*   **Do** prioritize whitespace. If a screen feels crowded, increase the spacing between `surface-container` elements.

### Don't
*   **Don't** use black (#000000) for text. Always use `on-surface` (#2c2f30) for a softer, premium feel.
*   **Don't** use standard 1px gray dividers. They shatter the "Digital Alchemy" aesthetic.
*   **Don't** use sharp corners. Every container must adhere to the `xl` (1.5rem) or `lg` (1rem) rounding scale to feel "friendly and accessible."

---

## 7. Signature Interaction: The Prosperity Pulse
Whenever a user completes a 'Meta' (Goal), the UI should trigger a subtle radial gradient pulse using `secondary-fixed` (#64fcbf) that radiates from the center of the card, providing a haptic-visual "reward" that feels uniquely Colombian and high-energy.```