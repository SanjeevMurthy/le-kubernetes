#!/usr/bin/env python3
"""Fetch every external URL the documentation cites and report the dead ones.

check-links.py deliberately never touches the network: it is the offline gate
that runs before every commit. This is the other half, run on demand, because a
study kit whose documentation links rot is worse than useless the week before an
exam.

Lab and example addresses are skipped. A CKS recipe that curls 127.0.0.1:6443 or
a NetworkPolicy question that talks to http://backend is citing something inside
its own scenario, not a page anyone can open.

Usage:
  python3 scripts/check-external-links.py            # every markdown file
  python3 scripts/check-external-links.py cks lfcs   # some of them
  python3 scripts/check-external-links.py --list     # print URLs, fetch nothing
"""
import concurrent.futures
import os
import re
import ssl
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {'.git', 'node_modules', '.claude'}
# Parentheses are allowed in the pattern and trimmed afterwards only when
# unbalanced, so a markdown link's closing bracket is dropped while a URL that
# genuinely contains parentheses survives intact.
URL_RE = re.compile(r'https?://[^\s"\'`<>\]]+')
TIMEOUT = 20
WORKERS = 8
UA = "Mozilla/5.0 (compatible; le-kubernetes link check)"

# Addresses that exist only inside a lab scenario or an exam question.
SKIP_HOST = re.compile(
    r'^(?:'
    # Private, loopback, link-local and the RFC 5737 documentation ranges.
    r'127\.|10\.|192\.168\.|172\.(?:1[6-9]|2\d|3[01])\.|169\.254\.|0\.0\.0\.0|\[::1\]|'
    r'192\.0\.2\.|198\.51\.100\.|203\.0\.113\.|'
    # Names that only resolve inside a cluster or a lab.
    r'localhost|.*\.local$|.*\.internal$|.*\.svc$|.*\.svc\.cluster\.local$|.*\.default$|'
    r'example\.com$|.*\.example$|.*\.example\.com$|example\.org$|.*\.app$|'
    r'httpbin.*|.*-lab$|.*\.mesh-lab$|.*controlplane.*|.*-svc.*|.*_.*|.*\.prod$|'
    r'<[^>]*>|\$\{.*|.*,.*|'
    # A single label with no dot is a Kubernetes Service or a lab host, never a
    # site: http://backend, http://my-service, http://node1.
    r'[^.]+$'
    r')', re.I)


def md_files(paths):
    for p in paths:
        full = p if os.path.isabs(p) else os.path.join(ROOT, p)
        if os.path.isfile(full):
            yield full
            continue
        for d, dirs, files in os.walk(full):
            dirs[:] = [x for x in dirs if x not in SKIP_DIRS]
            for f in files:
                if f.endswith('.md'):
                    yield os.path.join(d, f)


def collect(paths):
    """url -> sorted list of "file:line" citations."""
    found = {}
    for f in md_files(paths):
        with open(f, encoding='utf-8', errors='replace') as fh:
            fence = False
            for n, line in enumerate(fh, 1):
                # A URL inside a fenced block is an argument to a command: an
                # apt repository base, a curl target inside a cluster, a
                # download path that only resolves with the rest of the path
                # appended. Those are not citations and answering them with an
                # HTTP status says nothing useful.
                if line.lstrip().startswith('```'):
                    fence = not fence
                    continue
                if fence:
                    continue
                for raw in URL_RE.findall(line):
                    url = raw.rstrip('.,;:*_')
                    while url.endswith(')') and url.count(')') > url.count('('):
                        url = url[:-1].rstrip('.,;:*_')
                    # Shell variables, command substitutions and ellipses are
                    # templates in an install script or a redacted example, not
                    # addresses anyone can fetch.
                    if any(c in url for c in '$`{}<>') or not url.isascii():
                        continue
                    host = url.split('//', 1)[-1].split('/')[0].split('@')[-1]
                    if not host or SKIP_HOST.match(host.split(':')[0]):
                        continue
                    found.setdefault(url, []).append(
                        f"{os.path.relpath(f, ROOT)}:{n}")
    return found


def fetch(url):
    """Return (state, note) where state is ok, dead, or unverified.

    "unverified" is the honest answer when the failure says more about this
    client than about the page: a bot wall, a rate limit, or a TLS handshake
    Python will not complete. Reporting those as rot would train the reader to
    ignore the report, which is worse than not running it.
    """
    ctx = ssl.create_default_context()
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method,
                                     headers={"User-Agent": UA,
                                              "Accept": "*/*"})
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as r:
                return "ok", str(r.status)
        except urllib.error.HTTPError as e:
            if e.code in (403, 405, 406) and method == "HEAD":
                continue          # some hosts answer GET but refuse HEAD
            if e.code in (401, 403, 429):
                return "unverified", f"HTTP {e.code}, refused this client"
            if method == "GET":
                return "dead", f"HTTP {e.code}"
        except urllib.error.URLError as e:
            reason = e.reason
            if method == "GET":
                if isinstance(reason, ssl.SSLError):
                    return "unverified", f"TLS handshake failed: {reason.reason}"
                if isinstance(reason, TimeoutError):
                    return "unverified", "timed out"
                return "dead", f"{type(reason).__name__}: {reason}"
        except TimeoutError:
            if method == "GET":
                return "unverified", "timed out"
        except Exception as e:                      # noqa: BLE001
            if method == "GET":
                return "dead", f"{type(e).__name__}: {e}"
    return "dead", "unreachable"


def main(argv):
    list_only = "--list" in argv
    paths = [a for a in argv if not a.startswith('--')] or ['.']
    urls = collect(paths)
    if list_only:
        for u in sorted(urls):
            print(u)
        print(f"check-external-links: {len(urls)} URL(s), fetched none")
        return 0

    dead, unverified = [], []
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as pool:
        for url, (state, note) in zip(urls, pool.map(fetch, urls)):
            if state == "dead":
                dead.append((url, note, urls[url]))
            elif state == "unverified":
                unverified.append((url, note))

    def show(rows):
        for url, note, where in sorted(rows):
            print(f"  {url}")
            print(f"      {note}")
            for w in sorted(set(where))[:4]:
                print(f"      cited at {w}")

    if dead:
        print("\nDead:")
        show(dead)
    if unverified:
        print("\nCould not verify from here (open these by hand if it matters):")
        for url, note in sorted(unverified):
            print(f"  {url}\n      {note}")
    print(f"\ncheck-external-links: {len(urls)} URL(s), {len(dead)} dead, "
          f"{len(unverified)} unverified")
    return 1 if dead else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
