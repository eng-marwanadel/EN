import sys
import json
import base64
import re
import shutil
import urllib.request
from urllib.parse import unquote

REPO = "eng-marwanadel/EN"
BRANCH = "main"
DEFAULT_TARGETS = ["plugin_code_v6_0_1.json"]
DRY_RUN = False  # True = معاينة بس بدون كتابة

RAW_BASE = f"https://raw.githubusercontent.com/{REPO}/{BRANCH}/links/"
API_URL = f"https://api.github.com/repos/{REPO}/contents/links?ref={BRANCH}"

req = urllib.request.Request(API_URL, headers={"User-Agent": "fix-links"})
with urllib.request.urlopen(req) as r:
    names = {e["name"] for e in json.load(r) if e["type"] == "file"}
print(f"عدد الملفات في links/: {len(names)}")

url_re = re.compile(r'https?://[^\s"\'<>\\]+')
stats = {"replaced": 0, "unmatched": set(), "b64_fields": 0}


def swap_urls(text):
    def repl(m):
        url = m.group(0)
        clean = url.split("?")[0].split("#")[0]
        base = unquote(clean.rsplit("/", 1)[-1])
        if base in names:
            stats["replaced"] += 1
            return RAW_BASE + base
        if "mhdesign" in url:
            stats["unmatched"].add(url)
        return url
    return url_re.sub(repl, text)


def try_b64(s):
    try:
        return base64.b64decode(s, validate=True).decode("utf-8")
    except Exception:
        return None


def walk(obj):
    if isinstance(obj, dict):
        return {k: walk(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [walk(v) for v in obj]
    if isinstance(obj, str):
        decoded = try_b64(obj) if len(obj) > 20 else None
        if decoded and ("http" in decoded or ".rb" in decoded):
            before = stats["replaced"]
            new_decoded = swap_urls(decoded)
            if stats["replaced"] != before:
                stats["b64_fields"] += 1
                return base64.b64encode(new_decoded.encode("utf-8")).decode("ascii")
            return obj
        if "http" in obj:
            return swap_urls(obj)
    return obj


def process_text(path):
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        enc = "utf-16"
    elif raw.startswith(b"\xef\xbb\xbf"):
        enc = "utf-8-sig"
    else:
        enc = "utf-8"
    text = raw.decode(enc)
    return swap_urls(text).encode(enc), enc


def process_json(path):
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
        enc = "utf-16"
    elif raw.startswith(b"\xef\xbb\xbf"):
        enc = "utf-8-sig"
    else:
        enc = "utf-8"
    try:
        data = json.loads(raw.decode(enc))
    except (UnicodeDecodeError, json.JSONDecodeError):
        print(f"  [{path}] مش JSON صالح، هيتعامل معاه كنص عادي")
        return process_text(path)
    new_data = walk(data)
    out = json.dumps(new_data, ensure_ascii=False, indent=2).encode(enc)
    return out, enc


targets = sys.argv[1:] or DEFAULT_TARGETS

for path in targets:
    before = stats["replaced"]
    if path.lower().endswith(".json"):
        out, enc = process_json(path)
    else:
        out, enc = process_text(path)
    changed = stats["replaced"] - before
    print(f"[{path}] عدد الروابط اللي اتبدلت: {changed}")
    if changed and not DRY_RUN:
        shutil.copy(path, path + ".bak")
        with open(path, "wb") as f:
            f.write(out)
        print(f"  تم الحفظ. النسخة الأصلية في {path}.bak")

print(f"حقول base64 اتعدّلت: {stats['b64_fields']}")
print(f"إجمالي الروابط اللي اتبدلت: {stats['replaced']}")
if stats["unmatched"]:
    print("روابط mhdesign ما اتعرفتش عليها (مفيش ملف بنفس الاسم في links/):")
    for u in sorted(stats["unmatched"])[:40]:
        print("  -", u)