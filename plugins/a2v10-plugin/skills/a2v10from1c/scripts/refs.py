"""Хто на кого посилається: ядро предметних сутностей.

Сутності, на які посилаються поля багатьох об'єктів, і є предметним ядром застосунку —
з них збирається словник термінів (`references/common-layer.md`, рішення 1).

    python refs.py --dump build [--from Document] [--top 40] [--lang uk] [--out файл]

`--from` звужує, кого вважати тими, хто посилається (типово всі об'єкти дампу).
"""

import argparse
import collections

import dumplib


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump", default="build")
    ap.add_argument("--from", dest="source", help="вид об'єктів, що посилаються, наприклад Document")
    ap.add_argument("--top", type=int, default=40)
    ap.add_argument("--lang", help="мова синоніма у звіті")
    ap.add_argument("--out")
    args = ap.parse_args()

    objects = dumplib.load(args.dump)
    sources = {k: v for k, v in objects.items()
               if args.source is None or k.startswith(args.source + ".")}

    incoming = collections.Counter()
    for key, obj in sources.items():
        # Посилання рахуються за об'єктами, а не за полями: десять полів одного об'єкта на один
        # довідник — одне свідчення важливості, а не десять.
        for target in dumplib.refs(obj):
            if target != key:
                incoming[target] += 1

    lines = ["об'єктів, що посилаються: %d%s" % (len(sources), "" if args.source is None
                                             else " (вид %s)" % args.source),
             "цілей із вхідними: %d" % len(incoming), ""]
    lines.append("%-56s %6s  %s" % ("об'єкт", "посилань", "синонім"))
    for key, count in incoming.most_common(args.top):
        obj = objects.get(key)
        syn = dumplib.synonym(obj, args.lang) if obj else "— немає в дампі"
        lines.append("%-56s %6d  %s" % (key, count, syn))

    orphans = sorted(k for k in objects if k not in incoming and not k.startswith("Document."))
    lines += ["", "без жодного вхідного посилання (%d) — кандидати в самостійні або мертві:"
              % len(orphans)]
    lines += ["  " + x for x in orphans[:40]]

    dumplib.report(args.out, "\n".join(lines))


if __name__ == "__main__":
    main()
