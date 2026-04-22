# Observability

## Ideal state

- All code paths emit signals that prepare to answer likely questions about what happened
- Telemetry is emitted elegantly so the primary intent of the surrounding code remains clear
- Local dev tooling makes it easy to observe the system's behaviour across all environments (local → production)

## Common failure modes

- Code paths with no logging, tracing, or metrics — silent failures or invisible behaviour
- Gaps in signals sent to existing observability tools (e.g. errors tracked but not latency)
- Entire observability categories missing that would add value (e.g. no distributed tracing, no usage analytics)
- Telemetry entangled with business logic, obscuring the intent of the surrounding code
- No local dev tooling for observing system behaviour — debugging requires production access
- Missing "questions" the system should be able to answer about itself when deployed
