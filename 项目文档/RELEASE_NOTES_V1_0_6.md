# ObjCAtlas v1.0.6 maintenance scope

Compared with v1.0.5, this revision adds the full GNU LGPL v2.1 text for the Paul Kocher Blowfish files, a dated modification notice in `ThirdParty/blowfish.c`, and an explicit source-to-license map in [NOTICE.md](NOTICE.md). It also corrects [ORIGIN.md](ORIGIN.md), updates the maintenance version in three Info.plist files and README, refreshes the build input and source manifests, and limits build staging to the manifest-listed files with matching hashes.

The original Blowfish copyright and LGPL wording, the class-dump copyright and GPL text, and runtime parser code remain unchanged. Only a new comment was added to the Blowfish source; its algorithm is unchanged. The maintenance version is separate from the upstream command-line kernel version 3.5. This rights correction does not establish a new runtime security result, an upstream vulnerability, or CVP approval.

The public release, CI and downloadable source assets must be checked against their own exact commit before being described as published or verified. The candidate's local stage/build results, if any, are separate evidence.
