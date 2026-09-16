"""Кандидати господарських подій: що дамп пропонує вважати однією подією.

Рахує три ознаки окремо й показує, що дає кожна. Відповіді не дає і дати не може: межу
події проводить людина (`references/common-layer.md`).

    python candidates.py --dump build [--reg-cap 3] [--out файл]

Дивитися треба на найбільшу компоненту: якщо одна ознака склеює половину документів,
вона виражає зручність введення чи перегляду, а не належність до події.
"""

import argparse
import collections

import dumplib


def pairs(members):
    members = sorted(members)
    return {(members[i], members[j])
            for i in range(len(members)) for j in range(i + 1, len(members))}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump", default="build")
    ap.add_argument("--reg-cap", type=int, default=3,
                    help="регістр вважається свідченням, якщо записувачів не більше за це")
    ap.add_argument("--out")
    args = ap.parse_args()

    objects = dumplib.load(args.dump)
    docs = {k: v for k, v in objects.items() if k.startswith("Document.")}

    # 1. Введення на підставі.
    based = set()
    base_count = collections.Counter()
    for key, obj in docs.items():
        for other in dumplib.based_on(obj):
            if other in docs:
                based.add(tuple(sorted((key, other))))
                base_count[key] += 1

    # 2. Журнали.
    journals = set()
    for key, obj in objects.items():
        if not key.startswith("DocumentJournal."):
            continue
        members = [d for d in (obj.get("registeredDocuments") or []) if d in docs]
        journals |= pairs(members)

    # 3. Спільний регістр рухів.
    writers = collections.defaultdict(list)
    for key, obj in docs.items():
        for reg in dumplib.movements(obj):
            writers[reg].append(key)
    narrow = set()
    witnesses = []
    for reg, ds in sorted(writers.items()):
        if 2 <= len(ds) <= args.reg_cap:
            witnesses.append((reg, sorted(ds)))
            narrow |= pairs(ds)

    lines = ["документів у дампі: %d" % len(docs), ""]
    for name, edges in (("введення на підставі", based), ("журнали", journals),
                        ("регістр із ≤%d записувачами" % args.reg_cap, narrow)):
        comps = dumplib.components(set(docs), edges)
        biggest = len(comps[0]) if comps else 0
        alone = sum(1 for c in comps if len(c) == 1)
        lines.append("%-32s ребер %5d  груп %3d  найбільша %3d  поодиноких %3d"
                     % (name, len(edges), len(comps), biggest, alone))

    lines += ["", "найчастіше вводяться на підставі інших (це самостійні події,"
                  " а не частини чужих):"]
    for key, count in base_count.most_common(10):
        lines.append("  %-48s підстав %d" % (key, count))

    lines += ["", "регістри-свідки та їхні записувачі:"]
    for reg, ds in witnesses:
        lines.append("  %s" % reg)
        lines.append("      " + ", ".join(ds))

    lines += ["", "групи за вузьким регістром (≥2):"]
    for comp in dumplib.components(set(docs), narrow):
        if len(comp) > 1:
            lines.append("  [%d] %s" % (len(comp), ", ".join(sorted(comp))))

    lines += ["", "УВАГА: документ, який пише куди завгодно за своєю природою (ручна"
                  " операція, ручна правка рухів), свідченням не є — його треба"
                  " розпізнати очима й виключити зі склеювання."]

    dumplib.report(args.out, "\n".join(lines))


if __name__ == "__main__":
    main()
