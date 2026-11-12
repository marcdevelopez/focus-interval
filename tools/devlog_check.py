#!/usr/bin/env python3
"""devlog_check.py - read-only integrity checks for docs/dev_log.md (Focus Interval).

Run from the repository root:
  python3 -I tools/devlog_check.py check RESULT BASE SOURCE [SOURCE ...]
  python3 -I tools/devlog_check.py next [REPO_DIR]
  python3 -I tools/devlog_check.py headings FILE [FROM_NUMBER]
  python3 -I tools/devlog_check.py selftest

check     Verify a dev log after a merge, PR or branch sync. RESULT is the dev log to verify, BASE is
          the develop version it must extend unchanged, and each SOURCE is a branch version whose new
          blocks RESULT must contain byte for byte. Extract the versions with
          `git show <ref>:docs/dev_log.md > FILE` into a temporary directory outside the repository.
          Exit code 0 only when all 14 checks pass (RESULT: ALL PASS).
next      Print the highest block number on origin/develop and on every branch not merged into it,
          then NEXT_BLOCK. Run `git fetch --all --prune` first.
headings  List block headings with their line numbers.
selftest  Run the built-in cases (altered, lost, duplicated, reordered and foreign blocks, among
          others). Prints SELFTEST: PASS and exits 0 only if every case behaves as expected.

The tool never writes files and never uses the network; `next` only runs read-only git commands.
Rules: AGENTS.md (strict integration gate) and the formatting rules at the top of docs/dev_log.md.
"""
import difflib
import re
import subprocess
import sys

HEADING = re.compile(r'^#{1,2} (?:\U0001F539 )?Block (\d+)\b')
NEW_HEADING = re.compile(r'^## Block (\d+) \u2014 .+\(([^()]*)\)$')
DATE_END = re.compile(r'(\d{1,2})/(\d{1,2})/(\d{4})$')
HEADER_KEYS = ('Current focus:', 'Last update:')
CONFLICT = re.compile(r'^(<{7}|={7}|>{7})( |$)', re.M)
SEP = '\n\n---\n\n'


class StopCheck(Exception):
    """The input cannot be checked (for example, it has no block headings)."""


def read(path):
    with open(path, encoding='utf-8', newline='') as f:
        return f.read()


def parse(text):
    """(preamble, [(number, raw)]) - lossless: preamble + all raws == text."""
    lines = text.split('\n')
    idx = [i for i, line in enumerate(lines) if HEADING.match(line)]
    if not idx:
        raise StopCheck('no block headings found')
    pre = '\n'.join(lines[:idx[0]]) + '\n'
    blocks = []
    for k, i in enumerate(idx):
        j = idx[k + 1] if k + 1 < len(idx) else len(lines)
        raw = '\n'.join(lines[i:j]) + ('\n' if k + 1 < len(idx) else '')
        blocks.append((int(HEADING.match(lines[i]).group(1)), raw))
    if pre + ''.join(r for _, r in blocks) != text:
        raise StopCheck('parser is not lossless for this file')
    return pre, blocks


def content(raw):
    """Block text without its trailing separator (trailing blank and '---' lines)."""
    lines = raw.split('\n')
    while lines and lines[-1].strip() in ('', '---'):
        lines.pop()
    return '\n'.join(lines)


def junction(raw, followed):
    return content(raw) + (SEP if followed else '\n')


def heading(raw):
    return raw.split('\n', 1)[0]


def heading_date(raw):
    m = NEW_HEADING.match(heading(raw))
    d = DATE_END.search(m.group(2)) if m else None
    return (int(d.group(3)), int(d.group(2)), int(d.group(1))) if d else None


def masked(pre):
    return [line for line in pre.split('\n') if not line.startswith(HEADER_KEYS)]


def evaluate(text, base_text, source_texts):
    """Run checks C1-C14 and return [(name, ok, detail)]."""
    results = []

    def report(name, ok, detail=''):
        results.append((name, bool(ok), detail))

    report('C1 no merge-conflict markers', not CONFLICT.search(text))
    report('C2 file ends with exactly one newline', text.endswith('\n') and not text.endswith('\n\n'))
    pre, blocks = parse(text)
    bpre, bblocks = parse(base_text)
    n, last_base = len(bblocks), bblocks[-1][0]
    counts = {k: sum(1 for line in pre.split('\n') if line.startswith(k)) for k in HEADER_KEYS}
    report('C3 header has exactly one "Current focus:" and one "Last update:" line',
           all(v == 1 for v in counts.values()), str(counts))
    ops = difflib.SequenceMatcher(None, masked(bpre), masked(pre), autojunk=False).get_opcodes()
    report('C4 preamble keeps every base line in order (only insertions and the two header lines change)',
           all(tag in ('equal', 'insert') for tag, *_ in ops))
    old_hist = ''.join(r for _, r in bblocks[:-1]) + content(bblocks[-1][1])
    new_hist = ''.join(r for _, r in blocks[:n - 1]) + content(blocks[n - 1][1]) if len(blocks) >= n else None
    report(f'C5 historical content byte-identical (blocks up to {last_base}, {n} headings, anomalies included)',
           new_hist == old_hist)
    report('C6 historical headings identical and in the same order',
           [heading(r) for _, r in blocks[:n]] == [heading(r) for _, r in bblocks])
    new = blocks[n:]
    nums = [x for x, _ in new]
    report('C7 new blocks strictly increasing and contiguous after the base',
           nums == list(range(last_base + 1, last_base + 1 + len(nums))), f'{last_base} -> {nums}')
    report('C8 no new number repeats an existing one', not set(nums) & {x for x, _ in bblocks} and len(set(nums)) == len(nums))
    fmt = [x for x, r in new if not NEW_HEADING.match(heading(r)) or heading_date(r) is None]
    report('C9 new headings follow "## Block N <em dash> title (dd/mm/yyyy)"', not fmt, f'bad: {fmt}' if fmt else '')
    dates = [heading_date(r) for _, r in new]
    report('C10 new block dates do not go backwards', all(a <= b for a, b in zip(dates, dates[1:])) if None not in dates else False)
    lu = re.search(r'Last update: \*\*(\d{2})/(\d{2})/(\d{4})\*\*', pre)
    lu = (int(lu.group(3)), int(lu.group(2)), int(lu.group(1))) if lu else None
    report('C11 "Last update" is not older than the newest block date',
           bool(lu) and (not dates or None in dates or lu >= max(dates)), f'last update {lu}, newest {max(dates) if dates and None not in dates else None}')
    report(f'C12 separator after Block {last_base} is the standard one', len(blocks) >= n and blocks[n - 1][1] == junction(blocks[n - 1][1], bool(new)))
    index = {}
    for source in source_texts:
        sblocks = parse(source)[1]
        for k in range(n, len(sblocks)):
            index.setdefault(sblocks[k][0], []).append((sblocks[k][1], sblocks[k + 1][0] if k + 1 < len(sblocks) else None))
    bad = []
    for k, (num, raw) in enumerate(new):
        nxt = new[k + 1][0] if k + 1 < len(new) else None
        cands = index.get(num, [])
        if not cands or any(content(r) != content(raw) for r, _ in cands):
            bad.append(num)
        elif not any((nx == nxt and r == raw) or (nx != nxt and raw == junction(r, nxt is not None)) for r, nx in cands):
            bad.append(num)
    report('C13 every new block byte-identical to its source, separators included '
           '(standard separator only where blocks from different branches meet)', not bad, f'mismatch: {bad}' if bad else '')
    report('C14 no block lost and no foreign block', set(index) == set(nums), f'sources {sorted(index)}, result {nums}')
    return results


def cmd_check(result_path, base_path, *source_paths):
    if not source_paths:
        sys.exit('STOP: give at least one SOURCE')
    try:
        results = evaluate(read(result_path), read(base_path), [read(p) for p in source_paths])
    except StopCheck as exc:
        sys.exit(f'STOP: {exc}')
    for name, ok, detail in results:
        print(f"  [{'PASS' if ok else 'FAIL'}] {name}" + (f' - {detail}' if detail else ''))
    failures = [name for name, ok, _ in results if not ok]
    print('RESULT: ALL PASS' if not failures else f'RESULT: FAILED ({len(failures)})')
    return 0 if not failures else 1


def cmd_headings(path, start='0'):
    for n, line in enumerate(read(path).split('\n'), 1):
        m = HEADING.match(line)
        if m and int(m.group(1)) >= int(start):
            print(f'{n:>6}  {line[:110]}')
    return 0


def git(repo, *args):
    return subprocess.run(['git', '-C', repo, *args], capture_output=True, text=True)


def cmd_next(repo='.'):
    refs = ['origin/develop'] + [r for r in git(repo, 'branch', '-a', '--no-merged', 'origin/develop',
                                                '--format=%(refname:short)').stdout.split() if r]
    best = 0
    for ref in refs:
        out = git(repo, 'show', f'{ref}:docs/dev_log.md')
        nums = [int(m.group(1)) for m in map(HEADING.match, out.stdout.split('\n')) if m] if out.returncode == 0 else []
        top = max(nums) if nums else None
        print(f'  {ref:<45} highest block: {top}')
        best = max(best, top or 0)
    print(f'NEXT_BLOCK={best + 1}')
    return 0


def selftest_cases():
    """Synthetic dev logs with the same shape as docs/dev_log.md, including its historical anomalies."""
    dash = '\u2014'
    pre = '\n'.join([
        '# Dev log (selftest)', '', 'Formatting rules:', '',
        '- Append new blocks at the end of this file.', '- Never insert new blocks above existing ones.',
        '', '---', '', '# Current status', '',
        'Current focus: **selftest**', 'Last update: **10/11/2026**', '', '---', '']) + '\n'
    hist = [
        f'# \U0001F539 Block 1 {dash} first block (01/01/2026)\n\nBody 1.\n\n---\n\n',
        f'## \U0001F539 Block 3 {dash} written before Block 2 (02/01/2026)\n\nBody 3.\n\n',
        f'# \U0001F539 Block 2 {dash} out of order (02/01/2026)\n\nBody 2.\n\n---\n\n',
        f'## Block 4 {dash} first use of number 4 (03/01/2026)\n\nBody 4a.\n\n---\n\n',
        f'## Block 4 {dash} number used twice (03/01/2026)\n\nBody 4b.\n\n',
        f'## Block 6 {dash} number 5 never used (04/01/2026)\n\nBody 6.\n\n---\n\n',
        f'## Block 7 {dash} last base block (10/11/2026)\n\nBody 7.\n',
    ]
    base = pre + ''.join(hist)

    def block(num, title, date):
        return f'## Block {num} {dash} {title} ({date})\n\nBody {num}.\n'

    def update(text, date):
        return text.replace('Last update: **10/11/2026**', f'Last update: **{date}**')

    b8 = block(8, 'new block on branch A', '11/11/2026')
    b9 = block(9, 'new block on branch B', '12/11/2026')
    b9_early = block(9, 'new block on branch B', '09/11/2026')
    a = update(base, '11/11/2026') + '\n---\n\n' + b8
    b = update(base, '12/11/2026') + '\n---\n\n' + b9
    b_early = update(base, '11/11/2026') + '\n---\n\n' + b9_early
    ab = update(base, '12/11/2026') + '\n---\n\n' + b8 + '\n---\n\n' + b9
    ab_early = update(base, '11/11/2026') + '\n---\n\n' + b8 + '\n---\n\n' + b9_early
    swapped = update(pre, '11/11/2026') + hist[0] + hist[2] + hist[1] + ''.join(hist[3:])
    renumbered = update(base, '11/11/2026').replace(f'## Block 4 {dash} number used twice', f'## Block 5 {dash} number used twice')
    rule = '- Never insert new blocks above existing ones.\n'
    undated = a.replace('branch A (11/11/2026)', 'branch A')
    return base, [
        ('P1 one new block appended', a, [a], set()),
        ('P2 two branches merged in numeric order', ab, [a, b], set()),
        ('P3 preamble rule inserted and header updated', a.replace(rule, rule + '- New rule.\n'), [a], set()),
        ('N1 historical body altered by one character', a.replace('Body 3.', 'Body 3!'), [a], {'C5'}),
        ('N2 historical heading altered', a.replace('out of order (02/01', 'moved (02/01'), [a], {'C5', 'C6'}),
        ('N3 historical block lost', a.replace(hist[5], ''), [a], {'C5', 'C6', 'C14'}),
        ('N4 historical anomaly "corrected" by reordering', swapped + '\n---\n\n' + b8, [a], {'C5', 'C6'}),
        ('N5 historical block renumbered', renumbered + '\n---\n\n' + b8, [a], {'C5', 'C6'}),
        ('N6 new block lost', update(base, '11/11/2026'), [a], {'C14'}),
        ('N7 new block duplicated', a + '\n---\n\n' + b8, [a], {'C7', 'C8'}),
        ('N8 new blocks out of order', update(base, '12/11/2026') + '\n---\n\n' + b9 + '\n---\n\n' + b8, [a, b], {'C7', 'C10'}),
        ('N9 foreign new block not in any source', ab, [a], {'C13', 'C14'}),
        ('N10 merge-conflict marker left behind', a.replace('\n---\n\n## Block 8', '\n<<<<<<< HEAD\n---\n\n## Block 8'), [a], {'C1', 'C5', 'C12'}),
        ('N11 header line duplicated', a.replace('Current focus: **selftest**', 'Current focus: **selftest**\nCurrent focus: **again**'), [a], {'C3'}),
        ('N12 preamble rule deleted', a.replace(rule, ''), [a], {'C4'}),
        ('N13 extra separator between new blocks', ab.replace('\n---\n\n## Block 9', '\n---\n\n---\n\n## Block 9'), [a, b], {'C13'}),
        ('N14 new heading without date', undated, [undated], {'C9', 'C10'}),
        ('N15 "Last update" older than the newest block', ab.replace('Last update: **12/11/2026**', 'Last update: **11/11/2026**'), [a, b], {'C11'}),
        ('N16 new block dates go backwards', ab_early, [a, b_early], {'C10'}),
        ('N17 final newline missing', a[:-1], [a], {'C2', 'C13'}),
    ]


def cmd_selftest():
    base, cases = selftest_cases()
    wrong = 0
    for name, text, sources, expected in cases:
        try:
            failed = {label.split()[0] for label, ok, _ in evaluate(text, base, sources) if not ok}
        except StopCheck as exc:
            failed = {f'STOP: {exc}'}
        good = failed == expected
        wrong += not good
        outcome = 'all checks pass' if not failed else 'fails ' + ' '.join(sorted(failed, key=lambda c: int(c[1:]) if c[1:].isdigit() else 99))
        print(f"  [{'OK' if good else 'WRONG'}] {name}: {outcome}" + ('' if good else f' (expected {sorted(expected) or "all pass"})'))
    print(f'SELFTEST: PASS ({len(cases)} cases)' if not wrong else f'SELFTEST: FAILED ({wrong} of {len(cases)} cases)')
    return 0 if not wrong else 1


if __name__ == '__main__':
    commands = {'check': cmd_check, 'next': cmd_next, 'headings': cmd_headings, 'selftest': cmd_selftest}
    if len(sys.argv) < 2 or sys.argv[1] not in commands:
        sys.exit(__doc__)
    sys.exit(commands[sys.argv[1]](*sys.argv[2:]))
