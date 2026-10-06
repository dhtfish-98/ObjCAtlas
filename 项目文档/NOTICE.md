# Original rights and license texts

ObjCAtlas is a maintained derivative of [nygard/class-dump](https://github.com/nygard/class-dump) at commit `2c82b4ff12b2ea5d1ac23e49281d496997370841`. Original class-dump copyrights, including Steve Nygard's, remain in the source. The class-dump derivative retains its GPL-2.0-or-later terms; [LICENSE](LICENSE) contains the GPL v2 text. See [ORIGIN.md](ORIGIN.md) for the rename and modification record.

`ThirdParty/blowfish.c` and `ThirdParty/blowfish.h` retain **Copyright (C) 1997 by Paul Kocher** and their **LGPL-2.1-or-later** notices. The [complete LGPL v2.1 text](第三方许可/LGPL-2.1.txt) accompanies these files. Relative to the pinned upstream, `blowfish.h` is unchanged and `blowfish.c` renames the internal `N` macro to `atlas_N` and its references. The modified `.c` file now carries a dated modification notice identifying its first public modified copy on 2026-10-02; the original copyright and LGPL wording remain intact.

The LGPL text was copied byte-for-byte from [SPDX license-list-data at commit `31ba1a50e5397e00a304dbadc76531740e89ee48`](https://github.com/spdx/license-list-data/blob/31ba1a50e5397e00a304dbadc76531740e89ee48/text/LGPL-2.1-or-later.txt), SHA-256 `5749785c8bdefafcb5d798270ed0a967036fe2ca63dcedade1627565dfef81d2`. The source-file notices, rather than the SPDX repository, identify the licensing of these Blowfish files.

dhtfish98 maintains the renamed project and the documented modifications. That maintenance does not claim original authorship of class-dump or the vendored Blowfish implementation and does not remove or replace their licenses.
