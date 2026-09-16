"""Зведення за дампом — матеріал для першої доповіді про систему (§3.1 скіла).

Доповідь людині пишеться словами, а не цією таблицею: звідси беруться числа й імена, щоб
не переказувати дамп з пам'яті.

    python overview.py --dump build [--lang uk] [--top 15] [--out файл]
"""

import argparse
import collections
import io
import json
import os

import dumplib


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump", default="build")
    ap.add_argument("--lang")
    ap.add_argument("--top", type=int, default=15)
    ap.add_argument("--out")
    args = ap.parse_args()

    objects = dumplib.load(args.dump)
    by_kind = collections.Counter(k.split(".", 1)[0] for k in objects)

    lines = []

    manifest_path = os.path.join(args.dump, "manifest.json")
    if os.path.exists(manifest_path):
        manifest = json.load(io.open(manifest_path, encoding="utf-8"))
        lines.append("інструмент: %s" % manifest.get("tool"))
        perimeter = manifest.get("perimeter")
        if perimeter:
            lines.append("периметр застосовано: правил %d, виключено %d"
                         % (len(perimeter.get("rules") or []), perimeter.get("excluded", 0)))
        else:
            lines.append("периметр не застосовувався — у дампі всі об'єкти видів, які читаються")
        if manifest.get("only"):
            lines.append("УВАГА: дамп частковий, відбір --only")
        lines.append("")

    lines.append("склад дампу:")
    for kind, count in sorted(by_kind.items(), key=lambda x: -x[1]):
        lines.append("  %-32s %d" % (kind, count))

    # Найбільші об'єкти: за кількістю полів — за ними видно, чим система зайнята.
    def members(obj):
        total = len(obj.get("fields") or []) + len(obj.get("dimensions") or []) \
            + len(obj.get("resources") or []) + len(obj.get("values") or [])
        for table in obj.get("tables") or []:
            total += len(table.get("fields") or [])
        return total

    biggest = sorted(objects.items(), key=lambda kv: -members(kv[1]))[:args.top]
    lines += ["", "найбільші об'єкти (полів усього, включно з табличними частинами):"]
    for key, obj in biggest:
        lines.append("  %-52s %4d  %s" % (key, members(obj), dumplib.synonym(obj, args.lang)))

    # Що є в об'єктів понад оголошення.
    extra = collections.Counter()
    for key in objects:
        for filename in ("code.json", "forms.json", "templates.json", "predefined.json"):
            if dumplib.has_file(args.dump, key, filename):
                extra[filename] += 1
    lines += ["", "понад оголошення:"]
    for filename, count in sorted(extra.items()):
        lines.append("  %-20s у %d об'єктів" % (filename, count))

    subsystems_path = os.path.join(args.dump, "subsystems.json")
    if os.path.exists(subsystems_path):
        subsystems = json.load(io.open(subsystems_path, encoding="utf-8"))
        # Ключ підсистеми — шлях у дереві: у вкладеної він із крапкою.
        roots = [k for k in subsystems if "." not in k]
        visible = [k for k, v in subsystems.items() if v.get("includeInCommandInterface")]
        lines += ["", "підсистеми: усього %d, верхнього рівня %d, у командному інтерфейсі %d"
                  % (len(subsystems), len(roots), len(visible))]
        for key in sorted(roots):
            content = subsystems[key].get("content") or {}
            lines.append("  %-40s об'єктів %d  %s"
                         % (key, sum(len(v) for v in content.values()),
                            dumplib.synonym(subsystems[key], args.lang)))

    log = os.path.join(args.dump, "log", "source-assert.txt")
    if os.path.exists(log):
        unknown = [x for x in io.open(log, encoding="utf-8").read().splitlines() if x.strip()]
        lines += ["", "імен поза списком читання інструменту: %d" % len(unknown)]

    dumplib.report(args.out, "\n".join(lines))


if __name__ == "__main__":
    main()
