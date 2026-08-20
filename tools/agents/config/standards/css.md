# CSS

Styles carry their weight when a value's name says where it may legally be
used, a page stays legible at any viewport width and any reader's font size,
and nothing moves that the reader did not ask to have move.

## Must

**Every colour pair meets WCAG AA at the size it is actually rendered.**
Normal text clears 4.5:1. Text at or above 24px, or 19px bold, clears 3:1.
Non-text indicators — focus rings, control boundaries, status marks, chart
keys — clear 3:1. The ratio is measured against the background the element
actually composites onto, which is not always the one named nearest it in the
stylesheet.

**A layout that passes only because its text is oversized is treated as
failing.**
Meeting 3:1 through the large-text exemption is a property of the type scale,
not of the palette. When a page depends on it globally, the palette is the
defect: any later reduction in font size silently breaks contrast everywhere
at once.

**Contrast ratios stated in comments are measured against the surface the
element sits on.**
A figure quoted from memory, carried over from an earlier design, or measured
against a background the text never touches is worse than no figure, because
it stops the next reader from checking.

**No content is placed where it cannot be scrolled to.**
An element wider than its centring container overflows both edges; the browser
provides no scrollbar for the leading edge, so that half is unreachable at any
viewport size.

**Colour is not the only carrier of meaning.**
State, category and validity are conveyed by text, shape, position or icon as
well as hue. A reader who cannot distinguish the hues loses nothing.

**Motion respects `prefers-reduced-motion`.**
Animation and transition are reduced or removed when the operating system asks
for it. Indefinite animation on page furniture is absent regardless of the
setting: it reflows its own layout on every frame and holds attention that
belongs to the content.

**Keyboard focus is visible on every focusable element.**
Focus indicators are not suppressed without replacement, and an indicator is
not the same colour as the surface behind it.

## Should

**Colour, type, spacing and radius values come from named custom properties.**
Literals repeated across a sheet cannot be retuned as a set, and a value's
meaning is only recoverable by searching for its other uses.

**Token names state the role a value plays, not the value itself.**
`--color-link` travels its own constraint to the call site; `--blue-500` does
not. A value whose contrast permits only non-text use has no token named as
though it could be a text colour — the name is the enforcement mechanism,
since nothing else checks.

**Font sizes are expressed in `rem`.**
A reader who has raised their browser's default font size gets a page that
grows with it. `em` compounds through nesting, so a size becomes a function of
where the element sits rather than of what it is.

**Layout width is constrained by `max-width` rather than fixed `width`.**
A fixed width cannot shrink below itself, which is what turns a narrow viewport
into overflow instead of reflow.

**`box-sizing: border-box` is set globally.**
Under `content-box`, `width` and `padding` compose into a size neither states,
and the discrepancy surfaces as overflow or as an unexplained scrollbar.

**Interactive states do not reduce contrast.**
A hover, focus or active state leaves text at least as readable as its resting
state. A hover that lightens text against a light surface inverts the
affordance it is meant to signal.

**Values that exist to satisfy a constraint carry the constraint in a
comment.**
A magic opacity, a specific offset, or a colour chosen a shade off the obvious
one records what would break if it changed. Comments state the reason, not the
computation.

## Consider

**`color-scheme` is declared to match the palettes that actually exist.**
Claiming a scheme the sheet cannot honour leaves the user agent painting form
controls for a theme the rest of the page contradicts.

**Logical properties are used where the content may be translated.**
`padding-inline`, `margin-block` and `inset-inline-start` survive a
right-to-left locale; their physical equivalents silently do not.

**A global stylesheet is split when bare element selectors begin reaching
across components.**
Selectors like `button`, `table` and `input` at the top level apply to markup
their author never saw, so a component cannot be reasoned about from its own
file.

**Repeated markup-and-style pairs become components rather than repeated
class names.**
A pattern applied by hand in several places drifts in one of them.

## In scope

- Stylesheets and style blocks
- Inline style attributes and CSS-in-JS declarations
- Design token definitions
- Markup insofar as it carries classes, ARIA state used by selectors, or
  structural elements the layout depends on

## Out of scope

- Generated or vendored stylesheets
- Framework resets adopted wholesale and not modified
- Visual and brand judgment: which hue, which typeface, how much whitespace
