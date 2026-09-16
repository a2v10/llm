"""Спільне для скриптів вимірів: читання дампу й розбір посилань.

Дамп лише читається. Жоден скрипт у цій теці нічого в ньому не змінює.
"""

import io
import json
import os
import re

# Токен типу в дампі: cfg:<Що>.<Ім'я>. Посилальні види закінчуються на Ref; ще два
# види адресують не об'єкт-сховище, а множину типів.
_TOKEN = re.compile(r"^cfg:([A-Za-z]+)\.(.+)$")
_ALIAS = {"Characteristic": "ChartOfCharacteristicTypes", "DefinedType": "DefinedType"}


# Клас метаданих у рядку коду → вид у дампі: форма в ОткрытьФорму і літерал Тип адресують
# об'єкт російською. Та сама таблиця, за якою confdump будує ребра «открывает» і «тип в».
# Ключі — слова мови 1С, не перекладаються.
_CLASSES = {
    "справочник": "Catalog", "документ": "Document", "журналдокументов": "DocumentJournal",
    "перечисление": "Enum", "планвидовхарактеристик": "ChartOfCharacteristicTypes",
    "плансчетов": "ChartOfAccounts", "планвидоврасчета": "ChartOfCalculationTypes",
    "планобмена": "ExchangePlan", "регистрсведений": "InformationRegister",
    "регистрнакопления": "AccumulationRegister", "регистрбухгалтерии": "AccountingRegister",
    "регистррасчета": "CalculationRegister", "константа": "Constant",
    "последовательность": "Sequence", "бизнеспроцесс": "BusinessProcess", "задача": "Task",
    "обработка": "DataProcessor", "отчет": "Report", "общаяформа": "CommonForm",
}
_TYPE_SUFFIXES = {"ссылка", "объект", "менеджер", "наборзаписей", "ключзаписи",
                  "менеджерзаписи", "менеджерзначения", "выборка", "список"}


def form_target(literal):
    """«Документ.X.ФормаСписка» → «Document.X»; клас поза таблицею — None."""
    parts = literal.split(".")
    kind = _CLASSES.get(parts[0].lower()) if len(parts) >= 2 else None
    return kind + "." + parts[1] if kind else None


def type_target(literal):
    """«ДокументСсылка.X» → «Document.X»; примітив і клас поза таблицею — None."""
    prefix, dot, name = literal.partition(".")
    if not dot or not name:
        return None
    low = prefix.lower()
    for cls, kind in _CLASSES.items():
        if low.startswith(cls) and low[len(cls):] in _TYPE_SUFFIXES:
            return kind + "." + name
    return None


def load(dump):
    """Усі об'єкти дампу: ключ «Вид.Ім'я» → оголошення."""
    out = {}
    for kind in sorted(os.listdir(dump)):
        kdir = os.path.join(dump, kind)
        if not os.path.isdir(kdir) or kind == "log":
            continue
        for name in sorted(os.listdir(kdir)):
            path = os.path.join(kdir, name, "object.json")
            if os.path.exists(path):
                out[kind + "." + name] = json.load(io.open(path, encoding="utf-8"))
    return out


def has_file(dump, key, filename):
    kind, name = key.split(".", 1)
    return os.path.exists(os.path.join(dump, kind, name, filename))


def synonym(obj, lang=None):
    """Синонім об'єкта: зазначеною мовою, інакше перший, який є."""
    items = obj.get("synonym") or []
    for item in items:
        if lang is None or item.get("lang") == lang:
            return item.get("content", "")
    return items[0].get("content", "") if items else ""


def refs(obj):
    """Об'єкти, на які оголошення посилається типами своїх полів."""
    found = set()

    def walk(node):
        if isinstance(node, dict):
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)
        elif isinstance(node, str):
            m = _TOKEN.match(node)
            if not m:
                return
            what, name = m.group(1), m.group(2)
            if what.endswith("Ref"):
                found.add(what[:-3] + "." + name)
            elif what in _ALIAS:
                found.add(_ALIAS[what] + "." + name)

    walk(obj)
    return found


def movements(obj):
    """Регістри, у які об'єкт оголошує рухи."""
    return set(obj.get("registerRecords") or [])


def based_on(obj):
    """Чим об'єкт може вводитися на підставі."""
    return set(obj.get("basedOn") or [])


def components(nodes, edges):
    """Зв'язні компоненти, від більшої до меншої."""
    parent = {n: n for n in nodes}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for a, b in edges:
        if a in parent and b in parent:
            ra, rb = find(a), find(b)
            if ra != rb:
                parent[ra] = rb

    groups = {}
    for n in nodes:
        groups.setdefault(find(n), []).append(n)
    return sorted(groups.values(), key=len, reverse=True)


def report(path, text):
    """Вимір пишеться у файл, а не в діалог: повні списки в листуванні палять контекст."""
    if path:
        io.open(path, "w", encoding="utf-8").write(text)
        print("записано: " + path)
    else:
        print(text)
