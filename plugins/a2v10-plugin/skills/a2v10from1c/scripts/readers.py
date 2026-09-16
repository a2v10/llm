"""Читачі імені: чи живий реквізит (правило Ж-5).

Метадані про живість мовчать, маркера в імені може не бути. Ознака — хто його читає:
нуль читань або єдине читання в процедурі оновлення бази означає «мертвий».

    python readers.py --source source/Configuration ІмʼяРеквізиту [ще...] [--out файл]

Шукає в модулях вивантаження за межею слова. Це єдиний скрипт, який ходить у
вивантаження, а не в дамп: читачі там, коду в дампі немає.

ВАЖЛИВО: «мертвий» означає «не читається цією конфігурацією», а не «викинути» — рішення
про перенесення приймає власник. І реквізит, що живе заради друкованого бланка, читача в
модулях не має: спочатку бланки (П-3), потім це правило.
"""

import argparse
import collections
import io
import os
import re

import dumplib


def modules(source):
    for root, _dirs, files in os.walk(source):
        for name in files:
            if name.endswith(".bsl"):
                yield os.path.join(root, name)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default="source/Configuration")
    ap.add_argument("--context", type=int, default=0, help="скільки рядків показати довкола")
    ap.add_argument("--out")
    ap.add_argument("names", nargs="+")
    args = ap.parse_args()

    patterns = {n: re.compile(r"(?<![A-Za-zА-Яа-яЁё0-9_])" + re.escape(n)
                              + r"(?![A-Za-zА-Яа-яЁё0-9_])", re.IGNORECASE)
                for n in args.names}
    hits = collections.defaultdict(list)

    for path in modules(args.source):
        try:
            text = io.open(path, encoding="utf-8-sig", errors="ignore").read()
        except OSError:
            continue
        for name, pattern in patterns.items():
            if not pattern.search(text):
                continue
            for number, line in enumerate(text.splitlines(), 1):
                if pattern.search(line):
                    hits[name].append((path, number, line.strip()))

    lines = []
    for name in args.names:
        found = hits.get(name, [])
        lines.append("%s — входжень %d, файлів %d"
                     % (name, len(found), len({p for p, _n, _l in found})))
        for path, number, line in found[:args.context or 0]:
            lines.append("    %s:%d  %s" % (path, number, line[:120]))
        if not found:
            lines.append("    читачів немає — кандидат у мертві (спочатку перевірити бланки)")
        lines.append("")

    dumplib.report(args.out, "\n".join(lines))


if __name__ == "__main__":
    main()
