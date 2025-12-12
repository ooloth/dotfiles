## Summary

1. Parse at the I/O boundary
2. Transform into ergonomic, expressive, type-safe domain objects

## Parse real-world data at the I/O boundary

- Don't trust the assumed shape of data arriving from the outside the codebase
- This includes data from SDKs, APIs, config files, environment variables, etc
- Parse the incoming data as a way to (1) validate it and (2) persist the outcome of the validation via the type system
- Aim to resolve all "what is this? what is missing? what operations are safe?" questions so they don't need to be asked again after this step
- In Python, use Pydantic for this
- In JS/TS, use Zod

## Transform parsed API types into ergonomic domain types

- After parsing the incoming data, consider how to reshape it to better express its role in the domain
- In domain terms, what does this represent? Which properties can be discarded? Renamed? Unnested for easier lookups?
- The internal domain object does not have to match the shape of the outer world object
