#!/usr/bin/env python3
"""
Fetch and process GitHub pull requests waiting for review.

This script:
1. Fetches PRs via GitHub GraphQL API
2. Processes and enriches the data
3. Groups and prioritizes PRs
4. Tracks viewing history
5. Returns structured JSON
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple


# Configuration
MY_USERNAME = "ooloth"
IGNORED_REPOS = ["recursionpharma/build-pipelines"]
CACHE_DIR = os.path.expanduser("~/.claude/.cache")
CACHE_FILE = os.path.join(CACHE_DIR, "review-queue.json")
HISTORY_FILE = os.path.join(CACHE_DIR, "review-queue-history.json")


def fetch_prs_from_github() -> Dict[str, Any]:
    """Fetch PRs from GitHub using GraphQL API."""
    # Build the ignored repos filter
    ignored_filter = " ".join(f"-repo:{repo}" for repo in IGNORED_REPOS)

    query = f'''query {{
  search(query: "is:pr is:open archived:false user:recursionpharma review-requested:{MY_USERNAME} {ignored_filter} sort:created-desc", type: ISSUE, first: 50) {{
    issueCount
    edges {{
      node {{
        ... on PullRequest {{
          number
          title
          url
          createdAt
          isDraft
          additions
          deletions
          changedFiles
          mergeable
          reviewDecision
          comments(last: 20) {{
            totalCount
            nodes {{
              author {{
                login
              }}
              createdAt
            }}
          }}
          reviews(last: 20) {{
            totalCount
            nodes {{
              state
              author {{
                login
              }}
              submittedAt
            }}
          }}
          repository {{
            nameWithOwner
          }}
          author {{
            login
          }}
          commits(last: 1) {{
            nodes {{
              commit {{
                statusCheckRollup {{
                  state
                }}
              }}
            }}
          }}
        }}
      }}
    }}
  }}
}}'''

    result = subprocess.run(
        ['gh', 'api', 'graphql', '-f', f'query={query}'],
        capture_output=True,
        text=True,
        check=True
    )

    return json.loads(result.stdout)


def calculate_age(created_at_str: str) -> Tuple[str, int]:
    """Calculate human-readable age and days from ISO timestamp."""
    created = datetime.fromisoformat(created_at_str.replace('Z', '+00:00'))
    now = datetime.now(timezone.utc)
    delta = now - created

    days = delta.days
    if days == 0:
        hours = delta.seconds // 3600
        if hours == 0:
            return "📅 <1h", 0
        else:
            return f"📅 {hours}h", 0
    elif days < 7:
        return f"📅 {days}d", days
    elif days < 30:
        weeks = days // 7
        return f"📅 {weeks}w", days
    elif days < 365:
        months = days // 30
        return f"📅 {months}mo", days
    else:
        years = days // 365
        return f"📅 {years}y", days


def calculate_time_estimate(additions: int, deletions: int) -> str:
    """Calculate review time estimate based on total lines changed."""
    total_lines = additions + deletions
    if total_lines <= 50:
        return "5m"
    elif total_lines <= 200:
        return "10m"
    elif total_lines <= 500:
        return "20m"
    elif total_lines <= 1000:
        return "30m"
    else:
        return "45m"


def get_ci_status(pr: Dict[str, Any]) -> str:
    """Get CI status with emoji."""
    if pr.get("isDraft"):
        return "⏸️ Draft"

    commits = pr.get("commits", {}).get("nodes", [])
    if not commits:
        return "⏳ CI pending"

    rollup = commits[0].get("commit", {}).get("statusCheckRollup")
    if not rollup:
        return "⏳ CI pending"

    state = rollup.get("state")
    if state == "SUCCESS":
        return "✅ CI passing"
    elif state == "FAILURE":
        return "❌ CI failing"
    else:
        return "⏳ CI pending"


def get_review_status(pr: Dict[str, Any], my_username: str = MY_USERNAME) -> Tuple[str, Optional[str]]:
    """
    Get review status with emoji and details.

    Returns:
        (review_status_string, my_engagement_string)
    """
    review_decision = pr.get("reviewDecision")
    reviews = pr.get("reviews", {}).get("nodes", [])

    # Track unique reviewers and their most recent state
    reviewer_states = {}  # {username: latest_state}
    my_latest_review = None
    my_latest_timestamp = None

    for review in reviews:
        author_login = review.get("author", {}).get("login", "")
        state = review.get("state")
        submitted_at = review.get("submittedAt")

        # Skip bot reviews
        if author_login == "copilot-pull-request-reviewer":
            continue

        # Track my engagement
        if author_login == my_username:
            if my_latest_timestamp is None or submitted_at > my_latest_timestamp:
                my_latest_timestamp = submitted_at
                my_latest_review = state

        # Track each reviewer's most recent state
        if author_login not in reviewer_states or submitted_at > reviewer_states[author_login]["timestamp"]:
            reviewer_states[author_login] = {
                "state": state,
                "timestamp": submitted_at
            }

    # Build review status string with reviewer names
    total_reviewers = len(reviewer_states)

    if total_reviewers > 0:
        # Build list of reviewer actions with names
        reviewer_actions = []
        for username, info in reviewer_states.items():
            if info["state"] == "APPROVED":
                reviewer_actions.append(f"✅ {username}")
            elif info["state"] == "CHANGES_REQUESTED":
                reviewer_actions.append(f"⚠️ {username}")
            elif info["state"] == "COMMENTED":
                reviewer_actions.append(f"💬 {username}")

        if reviewer_actions:
            status = f"👥 {total_reviewers} reviewers ({', '.join(reviewer_actions)})"
        else:
            status = f"👥 {total_reviewers} reviewers"
    else:
        # No reviewers yet
        status = ""

    # Build my engagement string
    my_engagement = None
    if my_latest_review and my_latest_timestamp:
        age_str, _ = calculate_age(my_latest_timestamp)
        age = age_str.replace("📅 ", "")
        if my_latest_review == "APPROVED":
            my_engagement = f"✅ You approved {age} ago"
        elif my_latest_review == "CHANGES_REQUESTED":
            my_engagement = f"⚠️ You requested changes {age} ago"
        elif my_latest_review == "COMMENTED":
            my_engagement = f"💬 You reviewed {age} ago"

    # Also check for comments (not reviews)
    if not my_engagement:
        comments = pr.get("comments", {}).get("nodes", [])
        for comment in comments:
            if comment.get("author", {}).get("login") == my_username:
                age_str, _ = calculate_age(comment.get("createdAt"))
                age = age_str.replace("📅 ", "")
                my_engagement = f"💬 You commented {age} ago"
                break

    return status, my_engagement


def get_conflict_status(pr: Dict[str, Any]) -> str:
    """Get conflict status with emoji."""
    mergeable = pr.get("mergeable")
    if mergeable == "MERGEABLE":
        return "✅ No conflicts"
    elif mergeable == "CONFLICTING":
        return "⚠️ Conflicts"
    else:
        return "❓ Unknown"


def categorize_pr(pr: Dict[str, Any]) -> str:
    """Categorize PR into: feature/bug, dependency_updates, or chore."""
    author = pr.get("author", {}).get("login", "")
    title = pr.get("title", "").lower()

    if author == "dependabot" or title.startswith("bump "):
        return "dependency_updates"
    elif title.startswith("chore:"):
        return "chore"
    else:
        return "feature"


def load_or_create_history() -> Dict[str, Any]:
    """Load viewing history from cache or create new."""
    if os.path.exists(HISTORY_FILE):
        with open(HISTORY_FILE, 'r') as f:
            return json.load(f)
    return {}


def save_history(history: Dict[str, Any]) -> None:
    """Save viewing history to cache."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(HISTORY_FILE, 'w') as f:
        json.dump(history, f, indent=2)


def save_mapping(mapping: Dict[str, Any]) -> None:
    """Save PR lookup mapping to cache."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(CACHE_FILE, 'w') as f:
        json.dump(mapping, f, indent=2)


def process_prs(data: Dict[str, Any]) -> Dict[str, Any]:
    """Process raw GitHub data into structured PR list."""
    history = load_or_create_history()
    current_time = datetime.now(timezone.utc).isoformat()

    prs = []
    for edge in data["data"]["search"]["edges"]:
        pr_node = edge["node"]

        # Calculate age
        age_str, age_days = calculate_age(pr_node["createdAt"])

        # Calculate time estimate
        time_estimate = calculate_time_estimate(pr_node["additions"], pr_node["deletions"])

        # Get statuses
        ci_status = get_ci_status(pr_node)
        review_status, my_engagement = get_review_status(pr_node)
        conflict_status = get_conflict_status(pr_node)

        # Categorize
        category = categorize_pr(pr_node)

        # Extract repo info
        repo_full = pr_node["repository"]["nameWithOwner"]
        repo_short = repo_full.split("/")[1]

        # Check if new
        pr_key = f"{repo_full}#{pr_node['number']}"
        is_new = pr_key not in history

        # Update history
        if pr_key not in history:
            history[pr_key] = {
                "first_seen": current_time,
                "last_seen": current_time
            }
        else:
            history[pr_key]["last_seen"] = current_time

        prs.append({
            "number": pr_node["number"],
            "title": pr_node["title"],
            "url": pr_node["url"],
            "repo_full": repo_full,
            "repo_short": repo_short,
            "author": pr_node["author"]["login"],
            "additions": pr_node["additions"],
            "deletions": pr_node["deletions"],
            "files": pr_node["changedFiles"],
            "age_str": age_str,
            "age_days": age_days,
            "time_estimate": time_estimate,
            "ci_status": ci_status,
            "review_status": review_status,
            "conflict_status": conflict_status,
            "my_engagement": my_engagement,
            "is_new": is_new,
            "category": category,
            "is_draft": pr_node.get("isDraft", False)
        })

    # Save updated history
    save_history(history)

    # Sort PRs by category
    feature_prs = [p for p in prs if p["category"] == "feature" and not p["is_draft"]]
    chore_prs = [p for p in prs if p["category"] == "chore"]
    dependency_prs = [p for p in prs if p["category"] == "dependency_updates"]

    # Sort within each category by age (oldest first)
    feature_prs.sort(key=lambda p: -p["age_days"])
    chore_prs.sort(key=lambda p: -p["age_days"])
    dependency_prs.sort(key=lambda p: -p["age_days"])

    # Assign sequential numbers and build lookup mapping
    all_prs = feature_prs + chore_prs + dependency_prs
    pr_mapping = {}

    for idx, pr in enumerate(all_prs, start=1):
        pr["seq_num"] = idx
        pr_mapping[str(idx)] = f"{pr['repo_full']}#{pr['number']}"

    # Save mapping to cache
    pr_mapping["total"] = len(all_prs)
    pr_mapping["generated_at"] = current_time
    save_mapping(pr_mapping)

    # Format as markdown
    output_lines = []

    # Helper function to format a PR
    def format_pr(pr: Dict[str, Any]) -> str:
        lines = []
        new_badge = "🆕 " if pr["is_new"] else ""

        # Title line (non-breaking space at start to prevent list formatting)
        lines.append(f"\u00A0{pr['seq_num']}. {new_badge}**@{pr['author']} • \"{pr['title']}\"**")

        # Review activity line (reviewers + my engagement) - first line after title
        review_activity_parts = []
        if pr['review_status']:
            review_activity_parts.append(pr['review_status'])
        if pr["my_engagement"]:
            review_activity_parts.append(pr['my_engagement'])
        if review_activity_parts:
            lines.append(f"   • {' • '.join(review_activity_parts)}")

        # Metadata line: age, time estimate, diff stats, CI status, conflict status
        diff_stats = f"🟢 +{pr['additions']}  🔴 -{pr['deletions']}  📄 {pr['files']}"
        metadata_parts = [pr['age_str'], f"⏱️ {pr['time_estimate']}", diff_stats, pr['ci_status'], pr['conflict_status']]
        lines.append(f"   • {' • '.join(metadata_parts)}")

        # URL
        lines.append(f"   • 🔗 {pr['url']}")
        lines.append("")  # Blank line after each PR

        return "\n".join(lines)

    # Feature/Bug PRs
    if feature_prs:
        output_lines.append("**🎯 FEATURE/BUG PRs**")
        output_lines.append("")
        for pr in feature_prs:
            output_lines.append(format_pr(pr))

    # Chores
    if chore_prs:
        output_lines.append("**🔧 CHORES**")
        output_lines.append("")
        for pr in chore_prs:
            output_lines.append(format_pr(pr))

    # Dependency Updates
    if dependency_prs:
        output_lines.append("**📦 DEPENDENCY UPDATES**")
        output_lines.append("")
        for pr in dependency_prs:
            output_lines.append(format_pr(pr))

    # Footer commands
    output_lines.append("Commands:")
    output_lines.append(f"- Type a number (1-{len(all_prs)}) to review that PR")
    output_lines.append("- After each review, I'll prompt: \"Continue? (y/n/list/number)\" to review more PRs")
    output_lines.append("")
    output_lines.append("💡 Interactive workflow: Type a number → review PR → prompted for next → repeat until done")

    return "\n".join(output_lines)


def main():
    """Main entry point."""
    try:
        # Fetch PRs from GitHub
        data = fetch_prs_from_github()

        # Process into formatted markdown
        markdown_output = process_prs(data)

        # Output markdown
        print(markdown_output)

    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to fetch PRs from GitHub\n{e.stderr}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
