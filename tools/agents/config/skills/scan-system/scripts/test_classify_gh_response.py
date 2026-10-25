"""Property tests for how security_feeds.py turns one `gh api` call into a feed result.

The script stays a single file, so it is loaded from its path rather than imported as a package.
Its dependencies (pydantic) are installed in the skill test environment alongside hypothesis.

Run:
  uv run --with pytest --with hypothesis --with pydantic pytest \
    tools/agents/config/skills/scan-system/scripts/test_classify_gh_response.py
"""

import importlib.util
import json
import sys
from pathlib import Path
from types import ModuleType
from typing import Any

from hypothesis import given
from hypothesis import strategies as st


def _load_script() -> ModuleType:
    path = Path(__file__).with_name("security_feeds.py")
    spec = importlib.util.spec_from_file_location("security_feeds", path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    # dataclasses resolve their annotations through sys.modules, so register before running
    sys.modules["security_feeds"] = module
    spec.loader.exec_module(module)
    return module


sf = _load_script()
FEEDS = st.sampled_from(sf.FEEDS)
COMMAND = "gh api repos/octo/widgets/dependabot/alerts?state=open&per_page=100 --paginate --slurp"

alerts = st.fixed_dictionaries(
    {"number": st.integers(min_value=1), "state": st.just("open")},
    optional={
        "dependency": st.fixed_dictionaries(
            {
                "package": st.fixed_dictionaries(
                    {
                        "ecosystem": st.sampled_from(["npm", "pip", "rust"]),
                        "name": st.text(min_size=1),
                    }
                )
            }
        )
    },
)
pages = st.lists(st.lists(alerts, max_size=5), max_size=4)
# What gh can leave on stdout: a valid-looking list of alerts, a half-written body, or anything
stdouts = st.one_of(pages.map(json.dumps), st.text(), pages.map(lambda p: json.dumps(p)[:-1]))
gh_errors = st.builds(
    lambda message, status: f"gh: {message} (HTTP {status})\n",
    st.text().filter(lambda m: "\n" not in m),
    st.integers(min_value=400, max_value=599),
)
stderrs = st.one_of(st.text(), gh_errors)


def _is_pages(stdout: str) -> bool:
    try:
        value: Any = json.loads(stdout)
    except json.JSONDecodeError:
        return False
    return isinstance(value, list) and all(isinstance(page, list) for page in value)


@given(FEEDS, st.integers(min_value=1, max_value=255), stdouts, stderrs)
def test_a_failed_call_is_never_counted_whatever_stdout_says(
    feed, returncode, stdout, stderr
) -> None:
    result = sf.classify_gh_response(feed, returncode, stdout, stderr, COMMAND)

    assert not isinstance(result, sf.Counted)


@given(st.data(), FEEDS, st.integers(min_value=400, max_value=599), stdouts)
def test_an_error_status_is_turned_off_only_for_githubs_own_message(
    data, feed, status, stdout
) -> None:
    # Random text almost never starts with GitHub's message, so draw it half the time on purpose
    one_line = st.text().filter(lambda m: "\n" not in m)
    message = data.draw(st.one_of(one_line, one_line.map(lambda t: feed.turned_off_message + t)))
    stderr = f"gh: {message} (HTTP {status})\n"

    result = sf.classify_gh_response(feed, 1, stdout, stderr, COMMAND)

    turned_off = status in (403, 404) and message.startswith(feed.turned_off_message)
    assert isinstance(result, sf.TurnedOff) == turned_off
    assert isinstance(result, sf.ReadFailed) == (not turned_off)


@given(FEEDS, pages)
def test_a_successful_call_counts_every_alert_on_every_page(feed, alert_pages) -> None:
    result = sf.classify_gh_response(feed, 0, json.dumps(alert_pages), "", COMMAND)

    assert isinstance(result, sf.Counted)
    assert len(result.alerts) == sum(len(page) for page in alert_pages)


@given(FEEDS, stdouts)
def test_a_successful_call_is_counted_only_when_its_body_is_pages_of_alerts(feed, stdout) -> None:
    result = sf.classify_gh_response(feed, 0, stdout, "", COMMAND)

    if isinstance(result, sf.Counted):
        assert _is_pages(stdout)
    else:
        assert isinstance(result, sf.ReadFailed)
