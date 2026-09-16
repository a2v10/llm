"""Що приходить до подій розділу обліку: один крок за посиланнями.

Усередині — документи подій, регістри їхніх рухів і те, на що вони посилаються: довідники,
переліки, плани — таблицями з полями. Далі, і документи без подій розділу, — колонки без
таблиці, поки до об'єкта не дійде свій розділ (references/perimeter.md): таблиця, що прийшла
пізніше, впізнає свої рядки за ключем запису джерела.

    python closure.py --dump build Document.Ім'я [ще...] [--manual Document.Ім'я ...]
                      [--out файл] [--perimeter файл]

`--manual` — чорні ходи (ручна операція, правка рухів): подія, але її регістри не
рахуються — він пише куди завгодно за природою. `--perimeter` пише файл периметра: об'єкти
зберігання, що не увійшли всередину, рядками `объект` (ключове слово інструменту); наскрізні
види лишаються в дампі завжди.
"""

import argparse
import collections

import dumplib

# Периметр віднімає лише види зберігання. Наскрізні види — загальні модулі, функціональні
# опції, константи, команди, журнали, визначувані типи — посиланнями полів не знаходяться, а
# потрібні розбору будь-якого розділу: без них зникають делегований код, умовний склад полів і
# шляхи «підсистема → документ» повз її склад.
STORAGE = {
    "Document", "Catalog", "Enum", "InformationRegister", "AccumulationRegister",
    "AccountingRegister", "CalculationRegister", "ChartOfAccounts", "ChartOfCharacteristicTypes",
    "ChartOfCalculationTypes", "ExchangePlan", "BusinessProcess", "Task",
}


def targets(objects, key):
    """Прямі посилання об'єкта. Визначуваний тип розкривається: це ім'я набору типів, а не об'єкт."""
    found = set()
    for target in dumplib.refs(objects.get(key) or {}):
        if target.startswith("DefinedType."):
            found |= dumplib.refs(objects.get(target) or {})
        else:
            found.add(target)
    return found


def step(objects, events, manual):
    registers = set()
    for key in events:
        registers |= dumplib.movements(objects.get(key) or {})
    events = set(events) | set(manual)

    inside = events | registers
    tables, columns = set(), set()
    for key in inside:
        for target in targets(objects, key):
            if target in inside:
                continue
            (columns if target.startswith("Document.") else tables).add(target)
    return events, registers, tables, columns


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump", default="build")
    ap.add_argument("--out")
    ap.add_argument("--perimeter")
    ap.add_argument("--manual", nargs="*", default=[], help="Document.Ім'я — чорні ходи")
    ap.add_argument("events", nargs="+", help="Document.Ім'я — документи подій розділу")
    args = ap.parse_args()

    objects = dumplib.load(args.dump)
    missing = [s for s in args.events + args.manual if s not in objects]
    if missing:
        raise SystemExit("немає в дампі: " + ", ".join(missing))

    events, registers, tables, columns = step(objects, args.events, args.manual)
    inside = events | registers | tables
    unknown = sorted(k for k in inside if k not in objects)

    lines = ["документи подій: " + ", ".join(sorted(events)), ""]
    lines.append("регістри рухів (%d):" % len(registers))
    lines += ["  " + x for x in sorted(registers)]
    lines.append("")
    lines.append("таблицями з полями (%d), за видами:" % len(tables))
    for kind, count in sorted(collections.Counter(k.split(".", 1)[0] for k in tables).items(),
                              key=lambda x: -x[1]):
        lines.append("  %-32s %d" % (kind, count))
    lines += ["  " + x for x in sorted(tables)]
    lines.append("")
    lines.append("колонками без таблиці — документи поза подіями (%d):" % len(columns))
    lines += ["  " + x for x in sorted(columns)]
    if unknown:
        lines.append("")
        lines.append("за межами дампу (%d) — поза периметром або вид не читається:" % len(unknown))
        lines += ["  " + x for x in unknown]

    dumplib.report(args.out, "\n".join(lines))

    if args.perimeter:
        # Файл периметра перелічує те, що ЛИШАЄТЬСЯ ЗОВНІ: у інструменту правила віднімальні.
        # Слово «объект» у першій колонці — ключове слово інструменту, не перекладається.
        outside = sorted(k for k in set(objects) - inside if k.split(".", 1)[0] in STORAGE)
        rows = ["# периметр: усе, крім документів подій " + ", ".join(sorted(events))
                + ", їхніх регістрів і того, на що вони посилаються",
                "# вид рядка\tзначення\tчому"]
        rows += ["объект\t%s\tне приходить до подій розділу" % k for k in outside]
        dumplib.report(args.perimeter, "\n".join(rows))


if __name__ == "__main__":
    main()
