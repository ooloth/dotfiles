# /// script
# requires-python = ">=3.14"
# dependencies = [
# "rich",
# ]
# ///

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum

from rich.pretty import pprint  # ty: ignore[unresolved-import]

# TODO: https://github.com/lowspeclabs/Local-Ralph-Loop-With-RLM-RHC-Engram/blob/main/run_ralph.py
# TODO: https://github.com/lowspeclabs/Local-Ralph-Loop-With-RLM-RHC-Engram/blob/main/ralph/loop.py
# TODO: https://x.com/ryancarson/article/2008548371712135632
# TODO: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
# TODO: https://block.github.io/goose/docs/tutorials/ralph-loop/
# TODO: https://github.com/snarktank/ralph
# TODO: https://ghuntley.com/ralph/
# TODO: https://ghuntley.com/loop/
# TODO: https://ghuntley.com/tag/ai/

##########
# CONFIG #
##########


@dataclass
class Config:
    """Config for the loop."""

    BRANCH: str = ""  # e.g. "fix-bug-123" or "add-feature-xyz"
    ITERATIONS: int = 50
    # MODEL: str # Vary MODEL per prompt by default? One env var per prompt?


def parse_config() -> Config:
    return Config()


################
# CONTROL FLOW #
################

# TODO: loop logic as state machine to avoid bool combos


@dataclass
class LoopState:
    config: Config
    iteration: int

    def dispatch(self, action: str) -> LoopState:
        """State machine reducer"""
        match action:
            case "increment_iteration":
                return LoopState(config=self.config, iteration=self.iteration + 1)
            case _:
                raise ValueError(f"Unknown action: {action}")


@dataclass
class ShouldContinueDecision:
    yes: bool
    reason: str


def should_continue(
    config: Config,
    state: LoopState,
) -> ShouldContinueDecision:
    """State machine? Reducer?"""
    if state.iteration > config.ITERATIONS:
        return ShouldContinueDecision(yes=False, reason="Reached max iterations")

    return ShouldContinueDecision(yes=True, reason="More iterations to go!")


class PromptFile(StrEnum):
    BUILD = "BUILD.md"
    DISCUSS = "DISCUSS.md"
    PUBLISH = "PUBLISH.md"
    REVIEW = "REVIEW.md"
    UPDATE = "UPDATE.md"


def choose_prompt() -> PromptFile:
    """Based on tasks.json state, I imagine?"""
    return PromptFile.DISCUSS


def summarize_session():
    """See: https://github.com/lowspeclabs/Local-Ralph-Loop-With-RLM-RHC-Engram/blob/main/ralph/loop.py"""
    pass


def loop(config: Config, initial_state: LoopState):
    """Main loop logic."""
    print()
    pprint(config)
    pprint(initial_state)
    print()

    state = initial_state

    while True:
        state = state.dispatch("increment_iteration")
        continue_decision = should_continue(config, state)

        # Continue?
        if continue_decision.yes:
            print(f"=== Iteration {state.iteration} ===")
        else:
            print(f"\nStopping loop: {continue_decision.reason}")
            break


def main():
    config = parse_config()
    initial_state = LoopState(config, iteration=0)

    loop(config, initial_state)
    summarize_session()


if __name__ == "__main__":
    main()
