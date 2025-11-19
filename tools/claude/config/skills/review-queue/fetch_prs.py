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
          bodyText
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
            return "📅 Just now", 0
        elif hours == 1:
            return "📅 1 hour old", 0
        else:
            return f"📅 {hours} hours old", 0
    elif days == 1:
        return "📅 1 day old", 1
    elif days < 7:
        return f"📅 {days} days old", days
    elif days < 30:
        weeks = days // 7
        if weeks == 1:
            return "📅 1 week old", days
        else:
            return f"📅 {weeks} weeks old", days
    elif days < 365:
        months = days // 30
        if months == 1:
            return "📅 1 month old", days
        else:
            return f"📅 {months} months old", days
    else:
        years = days // 365
        if years == 1:
            return "📅 1 year old", days
        else:
            return f"📅 {years} years old", days


def calculate_time_estimate(additions: int, deletions: int) -> str:
    """Calculate review time estimate based on total lines changed."""
    total_lines = additions + deletions
    if total_lines <= 50:
        return "~5 min"
    elif total_lines <= 200:
        return "~10 min"
    elif total_lines <= 500:
        return "~20 min"
    elif total_lines <= 1000:
        return "~30 min"
    else:
        return "~45 min"


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

    # Count reviewers by their latest state
    approved_count = sum(1 for r in reviewer_states.values() if r["state"] == "APPROVED")
    changes_requested_count = sum(1 for r in reviewer_states.values() if r["state"] == "CHANGES_REQUESTED")
    commented_count = sum(1 for r in reviewer_states.values() if r["state"] == "COMMENTED")
    total_reviewers = len(reviewer_states)

    # Build review status string
    if review_decision == "APPROVED":
        status = "✅ Approved"
    elif review_decision == "CHANGES_REQUESTED":
        status = "⚠️ Changes requested"
    elif review_decision == "REVIEW_REQUIRED":
        status = "👀 Review required"
    else:
        status = "👀 Review required"

    # Add reviewer count details if there are reviewers
    if total_reviewers > 0:
        details = []
        if approved_count > 0:
            details.append(f"✅ {approved_count} approved")
        if changes_requested_count > 0:
            details.append(f"⚠️ {changes_requested_count} requested changes")
        if commented_count > 0:
            details.append(f"💬 {commented_count} commented")

        if details:
            status += f" • 👥 {total_reviewers} reviewers ({', '.join(details)})"

    # Build my engagement string
    my_engagement = None
    if my_latest_review and my_latest_timestamp:
        age_str, _ = calculate_age(my_latest_timestamp)
        age = age_str.replace("📅 ", "").replace(" old", "")
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
                age = age_str.replace("📅 ", "").replace(" old", "")
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


def extract_summary(body_text: Optional[str]) -> Optional[str]:
    """Extract first meaningful line from PR description."""
    if not body_text:
        return None

    lines = body_text.strip().split('\n')
    for line in lines:
        line = line.strip()
        # Skip empty lines, headers, and common sections
        if line and not line.startswith('#') and not line.startswith('What?') and not line.startswith('Why?') and not line.startswith('How?'):
            # Truncate if too long
            if len(line) > 100:
                return line[:97] + "..."
            return line

    return None


def is_action_required(pr: Dict[str, Any], age_days: int, ci_status: str, conflict_status: str) -> Tuple[bool, Optional[str]]:
    """Determine if PR requires immediate action."""
    # Failing CI
    if "❌" in ci_status:
        return True, "Failing CI"

    # Very old (>6 months)
    if age_days > 180:
        if "⚠️" in conflict_status:
            return True, "Very old PR with conflicts - close or ask author to update"
        return True, "Very old PR - close or ask author to update"

    # Old with conflicts (>3 months)
    if age_days > 90:
        if "⚠️" in conflict_status:
            return True, "Old PR with conflicts"

    return False, None


def categorize_pr(pr: Dict[str, Any]) -> str:
    """Categorize PR into: feature/bug, dependabot, or chore."""
    author = pr.get("author", {}).get("login", "")
    title = pr.get("title", "").lower()

    if author == "dependabot":
        return "dependabot"
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

        # Extract summary
        summary = extract_summary(pr_node.get("bodyText"))

        # Check if action required
        action_req, urgency_reason = is_action_required(pr_node, age_days, ci_status, conflict_status)

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
            "summary": summary,
            "my_engagement": my_engagement,
            "is_new": is_new,
            "action_required": action_req,
            "urgency_reason": urgency_reason,
            "category": category,
            "is_draft": pr_node.get("isDraft", False)
        })

    # Save updated history
    save_history(history)

    # Sort PRs by category and priority
    action_required = [p for p in prs if p["action_required"]]
    feature_prs = [p for p in prs if not p["action_required"] and p["category"] == "feature" and not p["is_draft"]]
    dependabot_prs = [p for p in prs if not p["action_required"] and p["category"] == "dependabot"]
    chore_prs = [p for p in prs if not p["action_required"] and p["category"] == "chore"]

    # Sort within each category (failing CI first, then by age)
    action_required.sort(key=lambda p: (-("❌" in p["ci_status"]), -p["age_days"]))
    feature_prs.sort(key=lambda p: (-("❌" in p["ci_status"]), -p["age_days"]))
    dependabot_prs.sort(key=lambda p: -p["age_days"])
    chore_prs.sort(key=lambda p: -p["age_days"])

    # Assign sequential numbers and build lookup mapping
    all_prs = action_required + feature_prs + dependabot_prs + chore_prs
    pr_mapping = {}
    total_time_mins = 0

    for idx, pr in enumerate(all_prs, start=1):
        pr["seq_num"] = idx
        pr_mapping[str(idx)] = f"{pr['repo_full']}#{pr['number']}"

        # Calculate total time
        mins = int(pr["time_estimate"].replace("~", "").replace(" min", ""))
        total_time_mins += mins

    # Calculate total time in hours and minutes
    total_hours = total_time_mins // 60
    total_mins = total_time_mins % 60
    if total_hours > 0:
        total_time_str = f"~{total_hours}h {total_mins}min"
    else:
        total_time_str = f"~{total_mins}min"

    # Save mapping to cache
    pr_mapping["total"] = len(all_prs)
    pr_mapping["generated_at"] = current_time
    save_mapping(pr_mapping)

    return {
        "prs": all_prs,
        "totals": {
            "action_required": len(action_required),
            "high_priority": len(feature_prs),
            "dependabot": len(dependabot_prs),
            "chores": len(chore_prs),
            "total": len(all_prs),
            "estimated_time_mins": total_time_mins,
            "estimated_time_str": total_time_str
        },
        "generated_at": current_time
    }


def main():
    """Main entry point."""
    try:
        # Fetch PRs from GitHub
        data = fetch_prs_from_github()

        # Process into structured format
        result = process_prs(data)

        # Output JSON
        print(json.dumps(result, indent=2))

    except subprocess.CalledProcessError as e:
        print(json.dumps({
            "error": "Failed to fetch PRs from GitHub",
            "details": e.stderr
        }), file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(json.dumps({
            "error": str(e),
            "type": type(e).__name__
        }), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
