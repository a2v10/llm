"""Склад розділу обліку: що підсистеми показують, включно зі шляхами повз їхній склад.

Підсистема — доказ, а не розділ (references/perimeter.md). Документ буває показано повз її
склад: загальна команда відкриває його форму або відкриває журнал, чий код вибирає документи
літералами типів. Обидва шляхи — у code.json команд і журналів.

Скрипт дає документи; кандидат у подію — документ плюс значення його виду операції.

    python section.py --dump build Покупки [Продажи ...] [--lang uk] [--out файл]

Аргумент — ключ підсистеми з subsystems.json, як він там записаний; береться з піддеревом.
"""

import argparse
import io
import json
import os

import dumplib


def code(dump, key):
    kind, name = key.split(".", 1)
    path = os.path.join(dump, kind, name, "code.json")
    return json.load(io.open(path, encoding="utf-8")) if os.path.exists(path) else {}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump", default="build")
    ap.add_argument("--lang")
    ap.add_argument("--out")
    ap.add_argument("subsystems", nargs="+", help="ключ підсистеми")
    args = ap.parse_args()

    subsystems = json.load(io.open(os.path.join(args.dump, "subsystems.json"), encoding="utf-8"))
    missing = [s for s in args.subsystems if s not in subsystems]
    if missing:
        raise SystemExit("немає підсистеми: " + ", ".join(missing))

    objects = dumplib.load(args.dump)
    keys = sorted(k for k in subsystems
                  if any(k == r or k.startswith(r + ".") for r in args.subsystems))

    def title(key):
        obj = objects.get(key)
        return key + ("  " + dumplib.synonym(obj, args.lang) if obj else "  (немає в дампі)")

    documents, commands = set(), set()
    for key in keys:
        content = subsystems[key].get("content") or {}
        documents.update("Document." + n for n in content.get("Document", []))
        commands.update("CommonCommand." + n for n in content.get("CommonCommand", []))

    opened, journals = set(), set()
    for command in commands:
        for module in code(args.dump, command).get("modules", []):
            for form in module.get("opens", []):
                target = dumplib.form_target(form["form"])
                if target is None:
                    continue
                if target.startswith("DocumentJournal."):
                    journals.add((target, command))
                elif target.startswith("Document.") and target not in documents:
                    opened.add((target, command))

    lines = ["підсистеми: " + ", ".join(keys), "", "документи в складі:"]
    lines += ["  " + title(k) for k in sorted(documents)]

    lines += ["", "відкриті командами повз склад:"]
    lines += ["  %s  ← %s" % (title(t), c) for t, c in sorted(opened)]

    lines += ["", "журнали, відкриті командами; набір вибирає код журналу за ключем команди:"]
    for journal, command in sorted(journals):
        lines.append("  %s  ← %s" % (title(journal), command))
        by_place = {}
        for module in code(args.dump, journal).get("modules", []):
            for literal in module.get("types", []):
                target = dumplib.type_target(literal["type"])
                if target:
                    place = module["module"] + "." + (literal.get("in") or "тіло модуля")
                    by_place.setdefault(place, set()).add(target)
        for place, targets in sorted(by_place.items()):
            lines.append("    %s: %s" % (place, ", ".join(sorted(targets))))

    dumplib.report(args.out, "\n".join(lines))


if __name__ == "__main__":
    main()
