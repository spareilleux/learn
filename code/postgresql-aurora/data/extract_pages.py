"""Extracts the prose of two courses of this site, in English, French and Spanish, for lesson 7's full-text search.

Reads the pages at a fixed commit with git show, drops the front matter's other fields, code blocks, imports,
HTML and MDX tags, and writes data/pages.json. Run from the repository root: python code/postgresql-aurora/data/extract_pages.py
"""
import json
import re
import subprocess

COMMIT = 'a1df189'
COURSES = ['duckdb', 'postgresql-aurora']
LOCALES = {'en': '', 'fr': 'fr/', 'es': 'es/'}


def git(*args):
    return subprocess.run(['git', *args], capture_output=True, check=True).stdout.decode('utf-8')


pages = []
for course in COURSES:
    files = git('ls-tree', '--name-only', f'{COMMIT}:src/content/docs/{course}/').split()
    for locale, prefix in LOCALES.items():
        for name in sorted(files):
            text = git('show', f'{COMMIT}:src/content/docs/{prefix}{course}/{name}')
            front, body = re.match(r'^---\n(.*?)\n---\n(.*)$', text, re.S).groups()
            title = re.search(r'^title:\s*"?(.*?)"?\s*$', front, re.M).group(1)
            body = re.sub(r'^(`{3,}).*?^\1\s*$', '', body, flags=re.S | re.M)
            body = re.sub(r'^import .*$', '', body, flags=re.M)
            body = re.sub(r'</?[A-Za-z][^>]*>', '', body)
            body = re.sub(r'\]\([^)]*\)', ']', body)
            body = re.sub(r'\n{3,}', '\n\n', body).strip()
            slug = name.rsplit('.', 1)[0]
            pages.append({'course': course, 'locale': locale, 'slug': slug, 'title': title, 'body': body})

with open('code/postgresql-aurora/data/pages.json', 'w', encoding='utf-8', newline='\n') as f:
    json.dump({'commit': COMMIT, 'pages': pages}, f, ensure_ascii=False, indent=0)
    f.write('\n')
print(len(pages), 'pages')
