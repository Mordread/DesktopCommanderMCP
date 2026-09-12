# MainRig Upstream Baseline

Captured 2026-09-12 before downstream production changes.

- Upstream: `https://github.com/wonderwhy-er/DesktopCommanderMCP.git`
- Upstream commit: `a781f5a4b8cfebac6638bc6fcbd38fca6326be53`
- Package version: `0.2.50`
- Local branch: `mainrig/base`
- Host: Windows MainRig
- Node: `v24.18.0`
- npm: `11.16.0`
- Git: `2.55.0.windows.3`

## Build
`npm ci` completed successfully. Its postinstall attempted to execute `dist/track-installation.js` before `prepare` built `dist`; the package script intentionally swallowed that failure and the subsequent prepare/build succeeded.

## Test suite
`npm test` built successfully and ran 59 test modules: 57 passed, 2 failed.

Known baseline failure 1: `test-config-atomic-write.js` consistently receives Windows `EPERM` renaming its temporary config file into place.
Known baseline failure 2: `test-enhanced-repl.js` reports no usable `python3`/`python` through its own detection path. MainRig itself has Python 3.14.6 at `C:\Users\Mordread\AppData\Local\Programs\Python\Python314\python.exe`.

Downstream acceptance rule: no new upstream-suite failures beyond explicitly documented baseline exceptions, plus all downstream tests must pass.
