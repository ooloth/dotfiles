# Testing Rules

## Libraries

- In Python, use `pytest` for unit tests
- In JS/TS, use `vitest` for unit tests (unless `jest` is already installed in the project)
- In React, use `@testing-library/react` for component tests

## Test concisely

### Property-based testing

- Consider testing properties/characteristics/invariants (with auto-generated example inputs) rather only testing a handful of specific input/output examples
- Would that be more thorough way to build confidence in how a given scenario is handled?
- Would that help maintainers better understand the fundamental behaviour of that code?
- In Python, use `hypothesis` for this
- In JS/TS, use `fast-check`

### Iterative example-based testing

- When testing multiple cases with the same outcome (e.g. X handles all forms of "empty" input in Y way), prefer one test case that iterates over all input-output scenarios rather than a separate test case for each input-output pair

## React Component Testing

**Always use @testing-library/react for testing React components.**

### Core Principle

Test user-facing behavior, not implementation details. Query the rendered DOM as users would interact with it, not React's internal object structure.

### ✅ DO

```typescript
import { render, screen } from '@testing-library/react'

it('renders blog posts', async () => {
  const mockPosts: PostListItem[] = [...]
  vi.mocked(getPosts).mockResolvedValue(Ok(mockPosts))

  const jsx = await MyComponent({ props })
  render(jsx)

  // Query by role, text, label - what users see
  expect(screen.getByRole('main')).toBeInTheDocument()
  expect(screen.getByRole('heading', { level: 1, name: /blog/i })).toBeInTheDocument()
  expect(screen.getByRole('link', { name: 'Post Title' })).toHaveAttribute('href', '/blog/post')
})
```

### ❌ DON'T

```typescript
// Don't access React internals
const result = (await MyComponent({ props })) as ReactElement
expect(result.type).toBe('main')
expect(result.props.className).toBe('flex-auto')
expect((result.props as { children: unknown }).children).toBeDefined()
```

### Testing Server Components

Server Components return JSX that can be rendered directly:

```typescript
// 1. Await the Server Component to get JSX
const jsx = await ServerComponent({ searchParams: Promise.resolve({}) })

// 2. Render the JSX
render(jsx)

// 3. Query the rendered DOM
expect(screen.getByText('Expected content')).toBeInTheDocument()
```

### Query Priority

Follow Testing Library's query priority (from most to most resilient):

1. **Accessible queries** (preferred):
   - `getByRole` - `screen.getByRole('button', { name: /submit/i })`
   - `getByLabelText` - `screen.getByLabelText('Email')`
   - `getByPlaceholderText`
   - `getByText` - for non-interactive elements

2. **Semantic queries**:
   - `getByAltText` - for images
   - `getByTitle`

3. **Test IDs** (last resort):
   - `getByTestId` - only when semantic queries aren't possible

### Benefits

- **Refactor-friendly**: Change implementation, tests still pass if behavior is same
- **Accessibility-focused**: Encourages proper semantic HTML and ARIA
- **User-centric**: Tests what users actually experience
- **No type gymnastics**: No need for `as ReactElement` or complex type assertions
- **Maintainable**: Tests break only when user-facing behavior changes

### When NOT to Use Testing Library

Testing Library is for components that render. Don't use it for:

- Pure functions (use regular assertions)
- API clients (mock fetch/axios and assert calls)
- Utility functions (test inputs/outputs directly)
