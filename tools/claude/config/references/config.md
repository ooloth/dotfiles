# Configuration

Configuration is correct when it is validated before the system accepts
traffic, expressed in types rather than raw strings, and complete enough
that a new developer can bootstrap the system from documentation alone.

## Must

**Required configuration is validated at startup.**
If a required environment variable or config value is absent or malformed,
the process fails immediately with a clear message identifying what is
missing and what it should look like. Startup is a safe time to fail;
discovering a missing value after accepting traffic is not.

**Configuration is parsed into typed values at the boundary.**
Raw environment variables and config files are read once and converted into
typed structs. Business logic receives typed values, not raw strings.
Scattered `env::var()` calls and inline string parsing don't appear deep
in the call stack.

## Should

**Required and optional config are distinct.**
Required config fails fast if absent. Optional config has an explicit,
documented default. The distinction is visible in the code and documentation,
not implied by whether the key happens to be set in a given environment.

**All config keys are documented.**
Every environment variable and config key the system reads is listed in
documentation a new developer can find without asking a long-tenured team
member. Undocumented config is a bus-factor risk.

## Consider

**Environmental differences are expressed through config, not branches.**
Business logic does not branch on `if env == "production"`. Environmental
differences are expressed as config values. The code path is the same in
all environments; the config differs.

**Config values have explicit documented defaults.**
Optional config values are not left to the runtime's or library's undocumented
defaults. The default is stated in the code and documented alongside the key.
