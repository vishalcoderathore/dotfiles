#!/usr/bin/env python3
"""Render markdown from stdin as ANSI for the `on` note preview.

Usage: render-md.py [width]

glow is capped at 16 colours once its stdout is a pipe (see obsidian-note.sh),
so this uses rich instead: forcing the colour system to truecolor lets the
palette below match the Monokai theme bat uses for `v`.
"""
import re
import sys

from rich.console import Console
from rich.markdown import Heading, Markdown
from rich.theme import Theme

THEME = Theme({
    "markdown.h1": "bold #f92672",
    "markdown.h1.border": "#f92672",
    "markdown.h2": "bold #fd971f",
    "markdown.h3": "bold #a6e22e",
    "markdown.h4": "bold #66d9ef",
    "markdown.h5": "bold #ae81ff",
    "markdown.h6": "bold #75715e",
    "markdown.link": "#66d9ef",
    "markdown.link_url": "underline #66d9ef",
    "markdown.item.bullet": "bold #fd971f",
    "markdown.item.number": "bold #fd971f",
    "markdown.code": "bold #a6e22e",
    "markdown.block_quote": "italic #75715e",
    "markdown.hr": "#75715e",
})


class LeftHeading(Heading):
    """rich centres every heading; a narrow preview pane reads better flush left."""

    def __rich_console__(self, console, options):
        self.text.justify = "left"
        if self.tag == "h2":
            yield ""
        yield self.text


Markdown.elements["heading_open"] = LeftHeading

# Obsidian properties sit in a leading ---/--- block. Markdown would render that
# as a rule plus a setext heading, so drop it. Excalidraw notes have it too.
FRONTMATTER = re.compile(r"\A---\n.*?\n---\n", re.DOTALL)

width = int(sys.argv[1]) if len(sys.argv) > 1 else 80
text = FRONTMATTER.sub("", sys.stdin.read(), count=1)

Console(force_terminal=True, color_system="truecolor", width=width, theme=THEME).print(
    Markdown(text, code_theme="monokai", hyperlinks=False))
