#!/usr/bin/env python3
"""
Script to fetch recent rAthena commits for GitHub Actions matrix.
This can be run periodically to update the commit list.
"""
import subprocess
import json
import sys
from datetime import datetime, timedelta

def get_recent_commits(days_back=30, max_commits=10):
    """Get recent commits from rAthena repository."""
    try:
        # Use git to get recent commits
        cmd = [
            'git', 'ls-remote', '--heads', '--tags',
            'https://github.com/rathena/rathena.git',
            'refs/heads/master'
        ]

        # For actual implementation, we would clone and get commit history
        # For now, return some example commits
        # In production, this would fetch actual commits

        # Example commits (replace with actual fetch logic)
        example_commits = [
            "master",  # Latest
            "a1b2c3d4e5f67890123456789012345678901234",  # Example SHA
            "2024-12-01",  # Date-based
            "2024-11-15",
            "2024-11-01",
        ]

        return example_commits[:max_commits]

    except Exception as e:
        print(f"Error fetching commits: {e}", file=sys.stderr)
        return ["master"]  # Fallback to master

def main():
    """Main function to output commits as JSON for GitHub Actions."""
    commits = get_recent_commits()

    # Output as JSON for GitHub Actions matrix
    output = {
        "include": []
    }

    # Common configurations
    packet_versions = ["20180418", "20190605", "20200401"]
    server_modes = [
        {"name": "classic", "renewal": "false"},
        {"name": "renewal", "renewal": "true"}
    ]
    platforms = ["linux/amd64", "linux/arm64"]

    # Generate matrix combinations
    for commit in commits:
        for packet_version in packet_versions:
            for server_mode in server_modes:
                for platform in platforms:
                    output["include"].append({
                        "rathena_commit": commit,
                        "packet_version": packet_version,
                        "server_mode": server_mode["name"],
                        "renewal": server_mode["renewal"],
                        "platform": platform
                    })

    print(json.dumps(output, indent=2))

if __name__ == "__main__":
    main()