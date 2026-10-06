# Source and modification record

ObjCAtlas is a renamed and restructured derivative of [nygard/class-dump](https://github.com/nygard/class-dump) at commit `2c82b4ff12b2ea5d1ac23e49281d496997370841`. It is not an independently authored implementation of the upstream algorithms. Original copyright and license notices are retained.

The class-dump derivative retains its **GPL-2.0-or-later** terms; the full GPL text is in `LICENSE`, and `UPSTREAM_GUIDE.md` preserves the upstream description. The separately attributed `ThirdParty/blowfish.c` and `ThirdParty/blowfish.h` retain Paul Kocher's **LGPL-2.1-or-later** notices. Their LGPL 2.1 text is included in `第三方许可/LGPL-2.1.txt`; `NOTICE.md` maps each source group to its original rights. Neither the source rename nor this maintenance version transfers upstream authorship to dhtfish98.

Modified owned source files have new names, modules/types/functions/local bindings have new names, and build references are updated. The complete file/symbol identity mapping is in `RENAME_MAP.json`: 3990 mapped declarations and 188 mapped owned source files. Macro and supplemental Python/check mappings are recorded separately where applicable. Vendor source remains attributed and keeps its original file and symbol names.

Compiler entry points, external frameworks/trait overrides/selectors/KVC keys, serialization and command-line fields, required build metadata filenames, and fixed test fixture bytes remain compatibility boundaries. These exceptions are explicit in the mapping; replacing external names would change functionality. Original Apple Mach-O layout/field values and input class/method names are preserved.

No claim is made that renaming establishes authorship, eligibility for an application, or a formal proof of complete behavioral equivalence.

Mapped source file modes are preserved. Owned build target/archive and bundle identities are renamed; external Pods target names and installer URLs remain vendor compatibility identifiers.
