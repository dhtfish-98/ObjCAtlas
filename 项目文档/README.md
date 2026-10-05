> 文档在「项目文档」，构建、缓存与暂存输入在「Build」。从仓库根目录运行 `python3 构建.py --stage --ci`，再进入 `Build/源码` 按下方命令编译。暂存会恢复原输入路径；ObjCAtlas 的构建适配类型为 `manual`。现有版本和历史验证记录按各自提交理解。

# ObjCAtlas

维护源码版本：**v1.0.5**。维护者为 **dhtfish98**；本项目仍是保留原作者及 GPL 许可的上游衍生作品。

v1.0.5 更正 GitHub 提交与标签的归属元数据，并同步项目版本号；运行时代码和上游权利不变。v1.0.4 在此前边界修复基础上，为符号表、fat 架构切片和常用 dyld bind 信息添加文件范围与字符串终止检查。命令行的 3.5 版本号属于原上游解析内核；本仓库维护版本以 GitHub Release 和此页为准。

防御用途、实际能力及本轮验证范围见 [DEFENSIVE_SCOPE.md](<DEFENSIVE_SCOPE.md>)。

ObjCAtlas is a Objective-C derivative of [nygard/class-dump](https://github.com/nygard/class-dump) with renamed owned source files and symbols. It preserves the upstream feature set within the tested contracts. See [source/license record](<ORIGIN.md>), [verification record](<VALIDATION.md>) and [complete mapping](<../RENAME_MAP.json>).

`Core` owns binary loading, data cursors, Objective-C metadata, type parsing and formatting. The renamed top-level entry point owns command parsing. `Checks`/`LegacyChecks` preserve the historical test corpus. External/vendor source is kept separately with its notices.

The command-line options, type-encoding grammar and Mach-O layouts remain compatible. Explicit property synthesis preserves the original backing ivar after renaming. Helper binaries can be compiled from their renamed source files by the contract script.

## Build

On macOS with Xcode command-line tools, stage the source and restore the project inputs first:

```sh
python3 构建.py --stage --ci
cd Build/源码
xcodebuild -project ObjCAtlas.xcodeproj -target ObjCAtlas -configuration Release SYMROOT="$PWD/../输出/ObjCAtlas/Products" OBJROOT="$PWD/../输出/ObjCAtlas/Intermediates" MACOSX_DEPLOYMENT_TARGET=13.0 CODE_SIGNING_ALLOWED=NO
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

The v1.0.3 local validation passed 22 contract checks, 39 original and 39 derivative XCTest cases, a guard-page cursor test, and synthetic malformed Mach-O checks. The v1.0.4 extension adds symbol table, fat slice and dyld bind boundary cases; see [validation scope](VALIDATION.md) for the current exact-commit result and open paths.

Runtime/integration boundaries are listed in VALIDATION.md. Built packages are distributed with the complete corresponding source package and original notices.
