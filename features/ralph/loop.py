# /// script
# requires-python = ">=3.14"
# dependencies = [
# "rich",
# ]
# ///

from dataclasses import dataclass
from enum import StrEnum

from rich.pretty import pprint as print  # ty: ignore[unresolved-import]

# TODO: https://github.com/lowspeclabs/Local-Ralph-Loop-With-RLM-RHC-Engram/blob/main/run_ralph.py
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
class ShouldContinueDecision:
    decision: bool
    reason: str


def should_continue() -> ShouldContinueDecision:
    """State machine? Reducer?"""
    return ShouldContinueDecision(decision=True, reason="Always continue for now")


class PromptFile(StrEnum):
    BUILD = "BUILD.md"
    DISCUSS = "DISCUSS.md"
    PUBLISH = "PUBLISH.md"
    REVIEW = "REVIEW.md"
    UPDATE = "UPDATE.md"


def choose_prompt() -> PromptFile:
    return PromptFile.DISCUSS


def main():
    config = parse_config()

    for i in range(config.ITERATIONS):
        # continue_decision = should_continue()
        # if not continue_decision.choice == True:
        #     print("Stopping loop:", continue_decision.reason)
        #     break

        print(f"Loop iteration {i + 1}")


if __name__ == "__main__":
    main()
