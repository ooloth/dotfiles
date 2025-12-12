# Architecture Rules

## Clear boundaries

- Aim to make the boundaries between one concern and another explicit in the codebase to avoid a tangle of interdependencies
- When possible, aim to provide a clear entrypoint/interface/api within the codebase for other codebase components to call when they need what the other component provides
- Be inspired by ideas like hexagonal architecture (ports and adapters), vertical slice architecture (feature folders), but do not follow any of them strictly - the point is to ensure dependencies within the codebase are clear and minimized

## Feature folders

- When feasible, prefer the ideas underlying feature folders / vertical slices / screaming architecture over layered/tiered approaches
- Optimize for findability (e.g. a human can find everything they need to touch when making a change by searching the file system for a folder/file named for that feature), updatability (related code is grouped cohesively and distant coupling is avoided) and deletability (deleting a folder is all or nearly all that's required to remove a behaviour)
- Aim to avoid human confusion about where to add new code by making the folder structure of the project very obvious and feature-oriented
