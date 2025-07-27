---
description: Identify and resolve performance bottlenecks
---

## Systematic Performance Optimization Process

### Phase 0: Planning & Strategy Assessment
**Before optimizing performance, confirm approach:**
- **Have you planned your optimization strategy?** If not, start here:
  1. **Quick assessment** - Is this micro-optimization or major performance issue?
  2. **Consider alternatives**:
     - Profile first (measure before optimizing - recommended)
     - Quick wins (obvious improvements like caching, indexing)
     - Algorithmic changes (better data structures/algorithms)
     - Infrastructure scaling (more CPU/memory/servers)
     - Requirements review (do we really need this performance?)
  3. **Choose optimal approach** based on:
     - Performance requirements and current metrics
     - Development time vs infrastructure cost
     - User impact and business priority
     - Team expertise with optimization techniques
  4. **Set performance targets** - What's good enough? Measure success.

### Phase 1: Measurement & Profiling
1. **Establish baseline** - Current performance metrics
2. **Profile the code** - Identify actual bottlenecks
3. **Analyze patterns** - CPU, memory, I/O, network usage
4. **Set targets** - Define acceptable performance goals

### Phase 2: Bottleneck Analysis
- **Algorithm complexity** - O(n²) loops, inefficient sorts
- **Database queries** - N+1 problems, missing indexes
- **Memory usage** - Leaks, excessive allocations
- **I/O operations** - Synchronous when could be async
- **Network calls** - Excessive requests, large payloads

### Phase 3: Optimization Strategy
1. **Quick wins first** - Low effort, high impact changes
2. **Algorithmic improvements** - Better data structures
3. **Caching strategy** - What, where, how long
4. **Parallel processing** - When appropriate
5. **Architecture changes** - If fundamental issues

### Phase 4: Implementation & Validation
- **Make one change at a time** - Isolate impact
- **Measure after each change** - Verify improvement
- **Consider trade-offs** - Memory vs speed
- **Document changes** - Why optimizations were made
- **Add performance tests** - Prevent regressions

### When to consult specialists:
- **design-architect**: For architectural bottlenecks, system-wide performance
- **researcher**: For framework-specific optimization techniques

### Common Optimizations:
- Batch operations instead of individual calls
- Add appropriate indexes to databases
- Use pagination for large datasets
- Implement caching at right layers
- Optimize images and assets
- Use CDN for static content

Performance issue: $ARGUMENTS