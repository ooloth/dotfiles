# TypeScript

TypeScript-specific invariants. Read alongside the general reference files.

## Must

**`strict: true` is set in tsconfig, and is not locally overridden.**
All strict checks — `strictNullChecks`, `noImplicitAny`, `strictFunctionTypes`,
and the rest — are enabled project-wide. Individual files and directories do
not override with looser settings. Strict mode violations do not merge.

**`unknown` is used instead of `any` for unvalidated external data.**
Data from API responses, JSON parsing, environment variables, and other
external sources enters as `unknown`, not `any`. `any` disables type checking
silently; `unknown` forces the caller to narrow before use.

**`as` casts are not used to silence type errors.**
Type assertions are not used to paper over a type mismatch. When a cast seems
necessary, the type signature or data flow is fixed instead. The rare legitimate
cast is accompanied by a comment explaining why it is safe.

**Sum types use discriminated unions.**
Mutually exclusive states are modelled as a union of object types, each with
a literal discriminant field (`type: "loading"`, `type: "error"`, etc.).
Boolean flags, optional fields, and parallel arrays are not used to represent
exclusive states. Exhaustive handling is enforced with a `never` check.

**External data is validated at the boundary with a schema library.**
All data entering from outside the process — API responses, form inputs, env
vars, config files — passes through a runtime validator (Zod or equivalent)
before entering domain code. TypeScript types alone give no runtime guarantee.

**Exhaustive unions are checked with `never`.**
Every `switch` or `if`/`else if` chain over a union type has a final branch
that assigns the remaining value to `never`. A new variant added to the union
becomes a compile error, not a silent fallthrough.

## Should

**`satisfies` is used to validate literals without widening.**
When a value should conform to a type but retain its literal type, `satisfies`
is used rather than a type annotation. `const config = { mode: "strict" }
satisfies Config` preserves `"strict"` where `: Config` would widen to `string`.

**`readonly` is the default for arrays and object properties.**
`readonly T[]` and `Readonly<T>` are used unless mutation is genuinely needed.
Immutability is opt-out, not opt-in.

**Opaque types wrap primitives that carry domain meaning.**
A user ID is not a `string`. An email is not a `string`. Branded or opaque
types (`type UserId = string & { readonly _brand: "UserId" }`) prevent one
primitive from being substituted for another across domain boundaries.

**Type-only imports are marked with an inline `type` keyword.**
`import { type Foo } from "./foo"` is used, with `type` inside the braces
before each type being imported. This makes the import's purpose explicit,
enables better tree-shaking, and avoids accidental value imports. The inline
form is preferred over the statement-level `import type { Foo }` because it
marks each specifier individually, so a module's types and its runtime values
stay in one import statement and remain distinguishable at a glance —
`import { fetchUsers, type IUser } from "./users"`.

**Utility types are used over duplicating structure.**
`Pick<T, K>`, `Omit<T, K>`, `Partial<T>`, `Required<T>`, and similar built-in
utilities are used when a type is structurally derived from another. Manually
duplicating fields creates drift when the source type changes.

## Consider

**`noUncheckedIndexedAccess` is enabled.**
Array index and object key access returns `T | undefined` rather than `T`.
This forces handling of the case where an index is out of bounds or a key
is absent, eliminating a common source of runtime errors.

**Template literal types are used for string-shaped domain values.**
When a string follows a known pattern — a route like `"/users/${string}"`, a
locale like `"${Language}-${Region}"` — a template literal type encodes the
structure. Bare `string` is used only when the value is genuinely unconstrained.

## In scope

- All `.ts` and `.tsx` files in the repo

## Out of scope

- Auto-generated `.ts` files (e.g. from protobuf, OpenAPI, or codegen tools)
- Vendored TypeScript not maintained in this repo
- `.js` files where TypeScript is not in use
