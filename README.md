# ObjCAtlas

防御用途、实际能力及本轮验证范围见 [DEFENSIVE_SCOPE.md](DEFENSIVE_SCOPE.md)。

ObjCAtlas is a Objective-C derivative of [nygard/class-dump](https://github.com/nygard/class-dump) with renamed owned source files and symbols. It preserves the upstream feature set within the tested contracts. See [source/license record](ORIGIN.md), [verification record](VALIDATION.md) and [complete mapping](RENAME_MAP.json).

`Core` owns binary loading, data cursors, Objective-C metadata, type parsing and formatting. The renamed top-level entry point owns command parsing. `Checks`/`LegacyChecks` preserve the historical test corpus. External/vendor source is kept separately with its notices.

The command-line options, type-encoding grammar and Mach-O layouts remain compatible. Explicit property synthesis preserves the original backing ivar after renaming. Helper binaries can be compiled from their renamed source files by the contract script.

## Build

On macOS with the command-line tools (Rust stable is also needed for ArchiveLens):

```sh
xcodebuild -project ObjCAtlas.xcodeproj -target ObjCAtlas -configuration Release SYMROOT="$PWD/build" MACOSX_DEPLOYMENT_TARGET=13.0 CODE_SIGNING_ALLOWED=NO
```

## Test and independently consume

```sh
python3 verification/atlas_contract.py --upstream ../upstream
```

To compare against the pinned original, clone the upstream repository into `../upstream`, check out the commit in ORIGIN.md, then run:

```sh
python3 verification/atlas_contract.py --upstream ../upstream
```

The contract script builds and runs the original and derivative, generates neutral fixtures, checks outputs/files and compiles a separate consumer against the public renamed API. `.github/workflows/contracts.yml` repeats this with an upstream checkout pinned to the recorded commit.

Both original and modified Release builds produced universal arm64/x86_64 executables and static libraries. 21 contract checks passed, including real compiled Objective-C Mach-O metadata, CLI/version/error cases, independent static-library consumers over 20 type encodings, both independently built helper programs, and 20 existing formatter input fixtures.

Runtime/integration boundaries are listed in VALIDATION.md. Built packages are distributed with the complete corresponding source package and original notices.
