# Validation evidence

## PASS

Both original and modified XCTest suites executed 39 tests with zero failures. Both original and modified Release builds produced universal arm64/x86_64 executables and static libraries. 21 contract checks passed, including real compiled Objective-C Mach-O metadata, CLI/version/error cases, independent static-library consumers over 20 type encodings, both independently built helper programs, and 20 existing formatter input fixtures.

The local report contains **21 passed contract checks**. Executed local build/test logs and original-baseline evidence are retained outside this public repository. Source and build bundles are created only after final file contents are frozen. Independent consumers link/import the renamed API from a separate project.

The public main commit `329fc1ab2c3518bd506b0040616943ba278c9950` completed [GitHub Actions run 37192416648](https://github.com/dhtfish-98/ObjCAtlas/actions/runs/37192416648) successfully. Its uploaded `contract.json` records 21 passing checks, including 39 original and 39 derivative XCTest cases. This is evidence for that exact commit; subsequent commits and releases require their own CI and package checks.

## Compatibility/normalization

The minimum deployment target was raised to macOS13 for the installed toolchain; both baseline/new builds used that target. SDK27 no longer provides PLATFORM_IOSMAC, so both baseline and new builds define it as6, the PLATFORM_MACCATALYST value. Legacy SenTestingKit sources use a declaration-only parsing shim during name transformation; this is not a runtime substitute or a test pass. The original `var-004.txt` formatter fixture itself aborts with NSInvalidArgumentException on a deliberately invalid template. Both variants match stdout, signal and exception class/reason; ASLR stacks and NSLog time/PID are excluded only for that known upstream abort.

Only executable/project branding, compile dates and NSLog timestamps/process IDs are normalized in regular CLI comparisons. Rust export READMEs normalize the generator brand. The observed known formatter abort compares exception type/reason rather than ASLR stack addresses. Parsed fields and production algorithms are not normalized.

## OPEN

- The archived SenTestingKit runner is not executed; both current XCTest suites ran 39 tests with zero failures. Full real application Xcode/Pods/CoreData/dSYM integration and device runtime remain unverified.
- The earlier local handoff predated hosted CI. Run 37192416648 now verifies the exact public commit named above; it does not by itself validate later source packages, device behavior, or application integration.
- The previously interrupted deep source/security audit remains OPEN. The finite contracts do not replace its malformed-input and full-source review.
- Passing these finite checks is not a proof of every input or complete feature equivalence.

## 2026-10-02 capability review

The current runtime entry points, file/process/network capabilities and attribution were reviewed. See DEFENSIVE_SCOPE.md for the exact paths and remaining limitations. This documentation update does not claim another execution of the historical full test suite, a rewrite of every upstream algorithm, or CVP eligibility. GitHub CI for the new commit is separate evidence.

## 2026-10-05 local malformed-input review for v1.0.3

The same pinned upstream commit and this maintenance tree passed 22 local contract checks. The original and maintained XCTest suites each passed 39 cases. The new checks exercise a byte at the edge of a protected memory page, length-overflow rejection, unterminated strings, synthetic Mach-O sections extending beyond EOF, and truncated protected segments. The local report is retained under Build; [a source-safe copy](BOUNDS_VALIDATION_20261005.json) records the check names and remaining contract limitations. The project version and bundle identifiers were updated to v1.0.3 / dhtfish98 without changing the upstream copyright or GPL terms.

This is a targeted parser boundary repair. It does not complete the interrupted full-source security audit, prove arbitrary malformed-file safety, or establish an exploitable vulnerability in the upstream project. Current hosted CI and release assets must be checked against the eventual exact commit before marking publication complete.

## 2026-10-05 local symbol, fat-slice and dyld-bind review for v1.0.4

The fixed original `class-dump@2c82b4ff12b2ea5d1ac23e49281d496997370841` and this maintenance tree passed 22 contract checks. Original and maintained XCTest suites each passed 39 cases. The synthetic Mach-O check now covers 20 cases, including valid and malformed symbol/string tables, fat architecture slices, dyld bind ranges and unterminated bind names. The protected-page cursor check also passed. The machine-readable scope is in [v1.0.4 bounds validation](BOUNDS_VALIDATION_V1_0_4_20261005.json).

These cases exercise selected parser boundaries only. Debug-only rebase/export paths, recursive export tries, other load commands, adversarial resource use, all device integration and the full-source security audit remain OPEN. Current hosted CI and any v1.0.4 Release assets require their own exact-commit and downloaded-byte verification before publication can be marked complete. Original class-dump GPL notices and other actual third-party rights remain intact.
