#!/usr/bin/env python3
import sys
import re
from datetime import datetime
import subprocess

def get_git_info():
    try:
        name = subprocess.check_output(['git', 'config', 'user.name']).decode().strip()
        email = subprocess.check_output(['git', 'config', 'user.email']).decode().strip()
        return f"{name} <{email}>"
    except:
        return "fedoraBee <9395414+fedoraBee@users.noreply.github.com>"

def format_date(date_str):
    # CHANGELOG.md uses YYYY-MM-DD
    dt = datetime.strptime(date_str, '%Y-%m-%d')
    # RPM uses Day Mon DD YYYY (e.g., Fri Apr 17 2026)
    return dt.strftime('%a %b %d %Y')

def main():
    changelog_path = 'CHANGELOG.md'
    if len(sys.argv) > 1:
        changelog_path = sys.argv[1]

    with open(changelog_path, 'r') as f:
        content = f.read()

    # Regex to find version sections: ## [0.4.2] - 2026-04-17
    version_pattern = re.compile(r'## \[([\d\.]+)\] - (\d{4}-\d{2}-\d{2})')
    
    author = get_git_info()
    
    sections = version_pattern.split(content)
    # sections[0] is everything before the first version
    # then triplets of (version, date, text)
    
    rpm_changelog = []
    
    for i in range(1, len(sections), 3):
        version = sections[i]
        date_str = sections[i+1]
        text = sections[i+2].strip()
        
        rpm_date = format_date(date_str)
        
        # Parse the text to get bullet points
        # Keep a Changelog has categories like ### Added, ### Fixed, etc.
        # We want to flatten these or keep them.
        
        lines = text.split('\n')
        entries = []
        for line in lines:
            line = line.strip()
            if not line:
                continue
            if line.startswith('###'):
                # Category, skip or handle? Let's skip categories for a cleaner RPM changelog
                # or keep them if they contain entries.
                continue
            if line.startswith('- '):
                # Bullet point
                entries.append(line)
            elif entries:
                # Continuation of previous bullet point
                entries[-1] += ' ' + line

        # Join entries and clean up
        formatted_entries = []
        for entry in entries:
            # Remove markdown links like [scripts/git-clean-switch-tool.sh]
            entry = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', entry)
            # Remove backticks
            entry = entry.replace('`', '')
            formatted_entries.append(entry)

        rpm_changelog.append(f"* {rpm_date} {author} - {version}-1")
        for entry in formatted_entries:
            rpm_changelog.append(entry)
        rpm_changelog.append("")

    print('\n'.join(rpm_changelog))

if __name__ == '__main__':
    main()
