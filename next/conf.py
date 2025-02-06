# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'MoonBit'
author = 'International Digital Economy Academy'
copyright = '%Y, {author}'.format(author=author)
release = 'v0.1.20250113'

# I18N based on Readthedocs Environment
# https://docs.readthedocs.io/en/stable/reference/environment-variables.html
import os
if (os.getenv('READTHEDOCS_LANGUAGE') == 'zh-cn' or
    os.getenv('LANGUAGE') == 'zh_CN'): # For local build
    project = 'MoonBit 月兔'
    author = '粤港澳大湾区数字经济院'
    copyright = '%Y, {author}'.format(author=author)
    language = 'zh_CN'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

import sys
from pathlib import Path
sys.path.append(str(Path("_ext").resolve()))

extensions = ['myst_parser', 'lexer', 'check', 'indent', 'sphinx_copybutton']

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store', ".env", '.venv', "README.md", 'sources', 'download']

smartquotes_excludes = {
  'builders': ['man', 'text', 'markdown', 'latex'],
}

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_book_theme'
# html_static_path = ['_static']
html_theme_options = {
    "repository_url": "https://github.com/moonbitlang/moonbit-docs/",
    "path_to_docs": "next",
    "use_source_button": True,
    "use_edit_page_button": True,
    "use_issues_button": True,
    "logo": {
        "text":"MoonBit 月兔",
    }
}
html_logo = "_static/logo.png"
html_favicon = "_static/logo.png"

# -- Options for LaTeX output ------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-latex-output
latex_engine = 'xelatex'
latex_elements = {
    'preamble': r"\usepackage{xeCJK}",
    'fvset': "\\fvset{formatcom={\\CJKsetecglue{}}}" # avoid having spaces around text in code blocks
}

# -- Options for myst_parser -------------------------------------------------
myst_heading_anchors = 3

# -- Options for gettext -----------------------------------------------------
gettext_additional_targets = ["literal-block"]

# -- Options for sphinx_copybutton -------------------------------------------------
copybutton_prompt_text = "$ "
