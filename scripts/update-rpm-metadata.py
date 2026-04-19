#!/usr/bin/env python3
import sys
import re
from datetime import datetime
import subprocess
import argparse

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

def get_version_from_makefile(makefile='Makefile'):
    with open(makefile, 'r') as f:
        for line in f:
            match = re.match(r'^VERSION := (\d+\.\d+\.\d+)', line)
            if match:
                return match.group(1)
    return None

def update_spec_version(spec, version):
    with open(spec, 'r') as f:
        lines = f.readlines()

    with open(spec, 'w') as f:
        for line in lines:
            if line.startswith('Version:'):
                f.write(f"Version:        {version}\n")
            else:
                f.write(line)

def generate_rpm_changelog(changelog='CHANGELOG.md'):
    with open(changelog, 'r') as f:
        content = f.read()

    version_pattern = re.compile(r'## \[([\d\.]+)\] - (\d{4}-\d{2}-\d{2})')
    author = get_git_info()
    sections = version_pattern.split(content)
    
    rpm_changelog = []
    
    for i in range(1, len(sections), 3):
        version = sections[i]
        date_str = sections[i+1]
        text = sections[i+2].strip()
        
        rpm_date = format_date(date_str)
        
        lines = text.split('\n')
        entries = []
        for line in lines:
            line = line.strip()
            if not line:
                continue
            if line.startswith('###'):
                continue
            if line.startswith('- '):
                entries.append(line)
            elif entries:
                entries[-1] += ' ' + line

        formatted_entries = []
        for entry in entries:
            entry = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', entry)
            entry = entry.replace('`', '')
            formatted_entries.append(entry)

        rpm_changelog.append(f"* {rpm_date} {author} - {version}-1")
        for entry in formatted_entries:
            rpm_changelog.append(entry)
        rpm_changelog.append("")
    
    return '\n'.join(rpm_changelog)

def main(version=None,
         spec='default-app.spec',
         changelog_in='CHANGELOG.md',
         makefile='Makefile',
         changelog_out='changelog'
         ):
   
    if not version:
        version = get_version_from_makefile(makefile)
        if not version:
            print("Error: Could not find VERSION in Makefile.", file=sys.stderr)
            sys.exit(1)
        update_spec_version(spec, version)

    rpm_changelog_content = generate_rpm_changelog(changelog_in)
    with open(changelog_out, 'w') as f:
        f.write(rpm_changelog_content)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Update RPM version and generate changelog')
    parser.add_argument('--version', dest='version', help='Update RPM version in spec file')
    parser.add_argument('--spec', default='rpm/podman-ai-stack.spec', help='Path to spec file')
    parser.add_argument('--changelog-in', default='CHANGELOG.md', help='Path to changelog file')
    parser.add_argument('--makefile', default='Makefile', help='Path to Makefile')
    parser.add_argument('--changelog-out', default='rpmbuild/changelog', help='Path to output changelog file')

    args = parser.parse_args()

    main(version=args.version,
         spec=args.spec,
         changelog_in=args.changelog_in,
         makefile=args.makefile,
         changelog_out=args.changelog_out)