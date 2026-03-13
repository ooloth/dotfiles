# /// script
# requires-python = ">=3.14"
# dependencies = [
# "rich",
# ]
# ///

from __future__ import annotations

import subprocess
from dataclasses import dataclass
from enum import StrEnum
from pathlib import Path

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
    BRANCH: str = ""  # e.g. "fix-bug-123" or "add-feature-xyz"
    DEBUG_MODE: bool = True
    ITERATIONS: int = 50
    # MODEL: str # Vary MODEL per prompt by default? One env var per prompt?
    RALPH_DIR_PROJECT: Path = Path.cwd() / ".ralph"
    RALPH_DIR_GLOBAL: Path = Path.home() / "Repos/ooloth/dotfiles/features/ralph"


def parse_config() -> Config:
    return Config()


################
# CONTROL FLOW #
################


@dataclass
class ShouldContinueDecision:
    yes: bool
    reason: str


class PromptFile(StrEnum):
    BUILD = "BUILD.md"
    DISCUSS = "DISCUSS.md"
    GOAL = "GOAL.md"  # "${PWD}/.ralph/${config.BRANCH}/GOAL.md"
    PUBLISH = "PUBLISH.md"
    REVIEW = "REVIEW.md"
    UPDATE = "UPDATE.md"


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

    def should_continue(self) -> ShouldContinueDecision:
        if self.iteration > self.config.ITERATIONS:
            return ShouldContinueDecision(yes=False, reason="Reached max iterations")

        return ShouldContinueDecision(yes=True, reason="More iterations to go!")

    def next_prompt(self) -> str:
        """Based on tasks.json state, I imagine?"""

        def get_prompt_file_name() -> str:
            return PromptFile.BUILD

        def get_absolute_path(file_name: str) -> Path:
            match file_name:
                case PromptFile.GOAL:
                    prompt_file_path = (
                        self.config.RALPH_DIR_PROJECT / self.config.BRANCH / file_name
                    )
                    # print(f"Looking for GOAL.md at: {prompt_file_path}")
                    return prompt_file_path
                case _:
                    prompt_file_path = (
                        self.config.RALPH_DIR_GLOBAL / f"prompts/{file_name}"
                    )
                    # print(f"Looking for {file_name} at: {prompt_file_path}")
                    return prompt_file_path

        prompt_file = get_absolute_path(get_prompt_file_name()).resolve()

        if not prompt_file.exists():
            raise FileNotFoundError(f"Prompt file not found: {prompt_file}")

        return prompt_file.read_text()


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
        continue_decision = state.should_continue()

        # Continue?
        if continue_decision.yes:
            print(f"=== Iteration {state.iteration} ===")
            prompt = state.next_prompt()
            print(f"Prompt: {prompt}")

            # subprocess.run(
            #     [
            #         "cat",
            #         prompt_file_path_absolute,
            #         "|",
            #         "claude",
            #         "--dangerously-skip-permissions",
            #     ],
            #     # capture_output=True,
            #     # text=True,
            # ).stdout

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
