"""
This script updates the Cloud Resume Challenge post with the repo's README.
"""

from datetime import datetime
import re
import subprocess

try:
    git_root = subprocess.check_output(
        ["git", "rev-parse", "--show-toplevel"], text=True
    ).strip()
except subprocess.CalledProcessError:
    print("Error: Not a Git repository or command failed.")


def get_readme():
    with open(f"{git_root}/README.md", encoding="UTF-8") as f:
        readme = f.read()

    return readme


def remove_table_of_contents(readme):
    start = re.search(
        r"^## Contents <!-- omit from toc -->$", readme, re.MULTILINE
    ).start()

    matches = re.finditer(r"^#", readme, re.MULTILINE)

    for match in matches:
        if match.start() > start:
            end = match.start()
            break

    return readme[:start] + readme[end:]


def remove_title(readme):
    title = re.search(r"^# .*$", readme, re.MULTILINE)
    end = title.end()

    return readme[end:]


def get_frontmatter():
    with open(
        f"{git_root}/frontend/src/hugo_site/content/posts/cloud_resume_challenge/index.md",
        encoding="UTF-8",
    ) as f:
        post = f.read()

    matches = re.finditer(r"^\+\+\+$", post, re.MULTILINE)

    fm_start = next(matches).start()
    fm_end = next(matches).end()

    frontmatter = post[fm_start:fm_end]

    lastmod = re.search(r"(?<=^lastmod = )\".*?\"$", frontmatter, re.MULTILINE)
    lm_start = lastmod.start()
    lm_end = lastmod.end()
    date = f'"{datetime.today().strftime("%Y-%m-%d")}"'

    return frontmatter[:lm_start] + date + frontmatter[lm_end:]


def update_post():
    readme = get_readme()
    readme = remove_table_of_contents(readme)
    readme = remove_title(readme)
    post = get_frontmatter() + readme

    with open(
        f"{git_root}/frontend/src/hugo_site/content/posts/cloud_resume_challenge/index.md",
        encoding="UTF-8",
        mode="w",
    ) as f:
        f.write(post)


update_post()
