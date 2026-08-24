# PetJournal UI sizing system

This document is the sizing contract for the PetJournal redesign.

## Principle

PetJournal uses semantic design tokens instead of page-specific magic numbers.

- Typography uses `rem` so browser and accessibility font settings remain meaningful.
- Exact interface geometry uses `px` where pixel alignment matters: borders, icons, control heights, topbar height and touch targets.
- Responsive composition may use `clamp()`, `%`, `vw`, `min()` and `max()` when the size is intentionally fluid.
- A different unit is not an exception by itself; a different semantic size without a product reason is.

The canonical tokens live in:

`app/assets/stylesheets/petjournal/_tokens.scss`

The final normalization layer lives in:

`app/assets/stylesheets/petjournal/_ui_consistency.scss`

`ui_consistency` must remain the final PetJournal import in `application.scss` until all older redesign partials have been migrated directly to tokens.

## Typography

| Role | Token | Effective size |
| --- | --- | ---: |
| Status / compact badge | `--pj-font-status` | 11px |
| Caption / helper text | `--pj-font-caption` | 12px |
| Metadata / labels | `--pj-font-meta` | 13px |
| Body / controls | `--pj-font-body`, `--pj-font-control` | 14px |
| Large body | `--pj-font-body-lg` | 15px |
| Card title | `--pj-font-card-title` | 16px |
| Workspace topbar title | `--pj-font-topbar-title` | 17px |
| Subheading | `--pj-font-subheading` | 18px |
| Section title | `--pj-font-section-title` | 20px |
| Detail/entity title | `--pj-font-detail-title` | 24px |
| Page/form title | `--pj-font-page-title` | 28px |
| Intentional display heading | `--pj-font-display-title` | 34px |

Do not introduce values such as `9px`, `10.5px`, `11.5px`, `17.5px`, etc. for normal product text. If a new semantic role is genuinely required, add one token and reuse it everywhere.

The Settings text-size preview is a deliberate exception because its purpose is to demonstrate different text sizes.

## Controls

| Role | Token | Size |
| --- | --- | ---: |
| Compact control | `--pj-size-control-sm` | 36px |
| Standard list/filter/button control | `--pj-size-control` | 40px |
| Comfortable form control | `--pj-size-control-lg` | 44px |
| Minimum mobile touch target | `--pj-size-touch-target` | 44px |
| Header icon button | `--pj-size-icon-button` | 36px |
| Standalone icon action | `--pj-size-icon-action` | 40px |
| Standard icon | `--pj-size-icon` | 20px |
| Workspace topbar | `--pj-size-topbar` | 62px |

## Spacing

Use the shared spacing rhythm:

`4 / 8 / 12 / 16 / 20 / 24 / 28 / 32 / 36 / 40 / 48 / 64px`

The corresponding tokens are `--pj-space-*` in `_tokens.scss`.

Avoid introducing one-off `7px`, `9px`, `11px`, `13px`, `15px`, `17px`, `19px`, etc. for structural spacing unless it solves a real optical-alignment problem that cannot be expressed by the existing scale.

## Radius

| Role | Token | Radius |
| --- | --- | ---: |
| Small exceptional element | `--pj-radius-xs` | 6px |
| Inputs and buttons | `--pj-radius-control` | 8px |
| Icon actions | `--pj-radius-icon` | 10px |
| Cards/tables/filter panels | `--pj-radius-card` | 12px |
| Large panels/mobile groups | `--pj-radius-panel` | 16px |
| Large decorative surface | `--pj-radius-xl` | 20px |
| Pills/statuses | `--pj-radius-pill` | 999px |

## Workspace layout

- Desktop content max width: `--pj-content-max` = 1180px.
- All signed-in page and form content containers use the same 1180px maximum width. Forms must not introduce a narrower page-level container; compactness should be handled by the form's internal grid, card widths and field composition.
- `--pj-form-content-max` and `--pj-form-wide-content-max` are compatibility aliases to `--pj-content-max` and therefore also resolve to 1180px.
- Desktop side clearance: `--pj-workspace-page-side` = 36px.
- Mobile side clearance: `--pj-workspace-mobile-side` = 16px.
- Standard content top spacing: 28px.
- Standard content bottom spacing: 48px.
- Standard workspace topbar: 62px, `Prata`, 17px title, standard notification action on the right.

## Release rule

A signed-in page is considered visually complete only after checking:

1. workspace topbar and navigation alignment;
2. semantic typography roles;
3. controls and mobile touch targets;
4. spacing rhythm;
5. card/panel radii;
6. empty/error/loading states;
7. desktop and mobile layouts;
8. consistency with already approved PetJournal pages.

Page-specific CSS may define composition, but shared typography and geometry should resolve to the canonical system above.
