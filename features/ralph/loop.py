# /// script
# requires-python = ">=3.14"
# dependencies = [
# "rich",
# ]
# ///

from dataclasses import dataclass
from enum import StrEnum

from rich.pretty import pprint as print  # ty: ignore[unresolved-import]

##########
# CONFIG #
##########


@dataclass
class Config:
    pass


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
    return ShouldContinueDecision(decision=True, reason="Always continue for now")


class Prompt(StrEnum):
    BUILD = "build"
    REVIEW = "review"
    PUBLISH = "publish"
    UPDATE = "update"
    DISCUSS = "discuss"


def choose_prompt() -> Prompt:
    return Prompt.BUILD


def main():
    config = parse_config()

    for i in range(5):
        # continue_decision = should_continue()
        # if not continue_decision.choice == True:
        #     print("Stopping loop:", continue_decision.reason)
        #     break

        print(f"Loop iteration {i + 1}")


if __name__ == "__main__":
    main()
