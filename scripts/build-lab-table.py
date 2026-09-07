#!/usr/bin/env python3
"""Generate the "which questions run where" table in each kit's lab-setup README.

The table answers one question: given the lab hosts you actually have, which
questions can you attempt today? It is derived from the `needs` tags in every
question's meta file, so it cannot drift from what the CLI enforces at runtime.

`./cks --env` and `sudo ./lfcs --env` remain authoritative for a specific host,
because they probe. This table is the static, offline version for planning.

Usage:
  python3 scripts/build-lab-table.py            # rewrite both READMEs
  python3 scripts/build-lab-table.py --check    # exit 1 if either is stale
  python3 scripts/build-lab-table.py cks        # one kit
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
START = "<!-- lab-table -->"
STOP = "<!-- lab-table stop -->"

# Tools present on only one of the two LFCS virtual machines. Taken from the
# package lists in lab-setup/provision-{ubuntu,rocky}.sh; keep them in step.
UBUNTU_ONLY = {"ufw", "apparmor_parser", "aa-status", "aa-complain", "netplan",
               "apt", "apt-get", "apt-mark", "apt-cache", "dpkg", "dpkg-query",
               "add-apt-repository", "update-grub"}
ROCKY_ONLY = {"firewall-cmd", "semanage", "sestatus", "getenforce", "setenforce",
              "setsebool", "getsebool", "restorecon", "chcon", "audit2allow",
              "dnf", "yum", "rpm", "rpm2cpio", "nmcli", "grub2-mkconfig"}

# How a need tag reads in the "Also needs" column. Tags that describe the host
# rather than an extra are dropped: they are already answered by the yes/no
# columns, and repeating them makes the table noisy.
LABEL = {
    "cni-netpol": "Calico", "cni-cilium": "Cilium", "ingress": "ingress-nginx",
    "admission:kyverno": "Kyverno", "admission:gatekeeper": "Gatekeeper",
    "istio": "Istio",
    "disk": "spare disk or loop file", "netns": "netns peer",
    "host2": "peer VM over SSH", "nic2": "second NIC", "virt": "libvirt",
}
DROP = {"kubectl", "linux", "node-root", "ubuntu", "rocky", "none", ""}


def read_metas(kit):
    qdir = ROOT / kit / "practice-cli" / "questions"
    out = []
    for d in sorted(qdir.glob("q*/")):
        meta = d / "meta"
        if not meta.is_file():
            continue
        kv = {}
        for line in meta.read_text().splitlines():
            if "=" not in line or line.lstrip().startswith("#"):
                continue
            k, _, v = line.partition("=")
            kv[k.strip()] = v.strip().strip('"')
        if not kv.get("id"):
            continue
        # A question whose scripts are not all written yet must not appear: the
        # table would send you to a lab to run something that does not exist.
        if not all((d / f).is_file() and (d / f).stat().st_size > 0
                   for f in ("question.md", "solution.md", "setup.sh",
                             "verify.sh", "cleanup.sh")):
            continue
        kv["needs"] = kv.get("needs", "").split()
        out.append(kv)
    return sorted(out, key=lambda q: int(q["id"]))


def extras(needs):
    parts = []
    for n in needs:
        if n in DROP:
            continue
        if n.startswith("tool:"):
            parts.append(f"`{n[5:]}`")
        elif n in LABEL:
            parts.append(LABEL[n])
        else:
            parts.append(n)
    return ", ".join(parts) if parts else "—"


def cks_table(qs):
    rows = []
    on_minikube = 0
    for q in qs:
        needs = q["needs"]
        # minikube runs as a container or VM you do not get a node shell in, so
        # anything needing root on the node is Killercoda-only.
        mk = "no" if "node-root" in needs else "yes"
        on_minikube += mk == "yes"
        # Killercoda's Killer Shell CKS scenario has no Cilium and no Istio;
        # those two live in their own upstream playgrounds.
        kc = "playground" if ({"cni-cilium", "istio"} & set(needs)) else "yes"
        rows.append((q, mk, kc))
    head = (f"`./cks --env` prints the authoritative answer for whatever host you are on, "
            f"by matching each question's `needs` tags against the environment. In summary, "
            f"**{on_minikube} of the {len(qs)} questions run on minikube** and the rest need "
            f"a root shell on a kubeadm node.")
    body = ["| # | Question | Domain | minikube | Killercoda | Also needs |",
            "|---|---|---|---|---|---|"]
    for q, mk, kc in rows:
        body.append(f"| Q{int(q['id'])} | {q['title']} | {q['domain_short']} | "
                    f"{mk} | {kc} | {extras(q['needs'])} |")
    tail = ("\nTwo rows deserve a note. The Cilium and Istio questions need a cluster running "
            "that software, so use the Killercoda Cilium playground for the first and read the "
            "recipe for the second; there is no free Istio scenario. Everything marked "
            "`node-root` is what the Killercoda Killer Shell CKS playground exists for.")
    return head, body, tail


def lfcs_table(qs):
    rows = []
    both = 0
    for q in qs:
        needs = set(q["needs"])
        tools = {n[5:] for n in needs if n.startswith("tool:")}
        ub = "no" if ("rocky" in needs or tools & ROCKY_ONLY) else "yes"
        ro = "no" if ("ubuntu" in needs or tools & UBUNTU_ONLY) else "yes"
        both += ub == "yes" and ro == "yes"
        rows.append((q, ub, ro))
    ubuntu_only = sum(1 for _, ub, ro in rows if ub == "yes" and ro == "no")
    rocky_only = sum(1 for _, ub, ro in rows if ro == "yes" and ub == "no")
    head = (f"`sudo ./lfcs --env` prints the authoritative answer for the host you are on, by "
            f"matching each question's `needs` tags against the environment. In summary, "
            f"**{both} of the {len(qs)} questions run on either virtual machine**, "
            f"{ubuntu_only} are Ubuntu-only and {rocky_only} are Rocky-only.")
    body = ["| # | Question | Domain | Ubuntu | Rocky | Also needs |",
            "|---|---|---|---|---|---|"]
    for q, ub, ro in rows:
        body.append(f"| Q{int(q['id'])} | {q['title']} | {q['domain_short']} | "
                    f"{ub} | {ro} | {extras(q['needs'])} |")
    tail = ("\nThe Rocky-only rows are the RHEL-family curriculum bullets: SELinux, firewalld, "
            "`nmcli` and `dnf`. The Ubuntu-only rows are its opposites: `ufw`, AppArmor and "
            "`apt`. Everything else is portable, which is the point of learning both.\n\n"
            "Rows needing a **spare disk or loop file** work on either VM without extra disks: "
            "the CLI prefers a genuinely unused disk and falls back to a loop-backed file. Rows "
            "needing a **netns peer** create their own second host inside the VM. Only the rows "
            "marked **peer VM over SSH** want both VMs running at once.")
    return head, body, tail


BUILDERS = {"cks": cks_table, "lfcs": lfcs_table}


def render(kit):
    qs = read_metas(kit)
    if not qs:
        raise SystemExit(f"build-lab-table: no complete questions found for {kit}")
    head, body, tail = BUILDERS[kit](qs)
    return "\n".join([START, "", head, "", *body, tail, "", STOP]) + "\n"


def inject(kit, check):
    path = ROOT / kit / "lab-setup" / "README.md"
    text = path.read_text()
    new = render(kit)
    if START in text and STOP in text:
        pattern = re.compile(re.escape(START) + r".*?" + re.escape(STOP) + r"\n?", re.S)
        updated = pattern.sub(lambda _: new, text, count=1)
    else:
        # First run: replace whatever sits under the heading, up to the next one.
        pattern = re.compile(r"(## Which questions run where\n)(.*?)(?=\n## )", re.S)
        if not pattern.search(text):
            raise SystemExit(f"build-lab-table: no 'Which questions run where' heading in {path}")
        updated = pattern.sub(lambda m: m.group(1) + "\n" + new, text, count=1)
    if updated == text:
        print(f"  {kit}: up to date")
        return 0
    if check:
        print(f"  {kit}: STALE - run python3 scripts/build-lab-table.py")
        return 1
    path.write_text(updated)
    print(f"  {kit}: rewrote {path.relative_to(ROOT)}")
    return 0


def main(argv):
    check = "--check" in argv
    kits = [a for a in argv if a in BUILDERS] or list(BUILDERS)
    return max(inject(k, check) for k in kits)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
