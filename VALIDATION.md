# Validation evidence

## PASS

Both original and modified XCTest suites executed 39 tests with zero failures. Both original and modified Release builds produced universal arm64/x86_64 executables and static libraries. 21 contract checks passed, including real compiled Objective-C Mach-O metadata, CLI/version/error cases, independent static-library consumers over 20 type encodings, both independently built helper programs, and 20 existing formatter input fixtures.

The local report contains **21 passed contract checks**. Executed local build/test logs and original-baseline evidence are retained outside this public repository. Source and build bundles are created only after final file contents are frozen. Independent consumers link/import the renamed API from a separate project.

## Compatibility/normalization

The minimum deployment target was raised to macOS13 for the installed toolchain; both baseline/new builds used that target. SDK27 no longer provides PLATFORM_IOSMAC, so both baseline and new builds define it as6, the PLATFORM_MACCATALYST value. Legacy SenTestingKit sources use a declaration-only parsing shim during name transformation; this is not a runtime substitute or a test pass. The original `var-004.txt` formatter fixture itself aborts with NSInvalidArgumentException on a deliberately invalid template. Both variants match stdout, signal and exception class/reason; ASLR stacks and NSLog time/PID are excluded only for that known upstream abort.

Only executable/project branding, compile dates and NSLog timestamps/process IDs are normalized in regular CLI comparisons. Rust export READMEs normalize the generator brand. The observed known formatter abort compares exception type/reason rather than ASLR stack addresses. Parsed fields and production algorithms are not normalized.

## OPEN

- The archived SenTestingKit runner is not executed; both current XCTest suites ran 39 tests with zero failures. Full real application Xcode/Pods/CoreData/dSYM integration and device runtime remain unverified.
- The hosted CI workflow has been authored but has not yet run on GitHub at this local handoff.
- Passing these finite checks is not a proof of every input or complete feature equivalence.
