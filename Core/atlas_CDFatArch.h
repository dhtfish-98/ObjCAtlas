// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDFile.h" // For CDArch

@class ObjCAtlasDataCursor;
@class ObjCAtlasFatFile, ObjCAtlasMachOFile;

@interface ObjCAtlasFatArch : NSObject

- (id)initAtlasWithMachOFile:(ObjCAtlasMachOFile *)atlas_machOFile;
- (id)initAtlasWithDataCursor:(ObjCAtlasDataCursor *)atlas_cursor;

@property (assign) cpu_type_t atlas_cputype;
@property (assign) cpu_subtype_t atlas_cpusubtype;
@property (assign) uint32_t atlas_offset;
@property (assign) uint32_t atlas_size;
@property (assign) uint32_t atlas_align;

@property (nonatomic, readonly) cpu_type_t atlas_maskedCPUType;
@property (nonatomic, readonly) cpu_subtype_t atlas_maskedCPUSubtype;
@property (nonatomic, readonly) BOOL atlas_uses64BitABI;
@property (nonatomic, readonly) BOOL atlas_uses64BitLibraries;

@property (weak) ObjCAtlasFatFile *atlas_fatFile;

@property (nonatomic, readonly) atlas_CDArch atlas_arch;
@property (nonatomic, readonly) NSString *atlas_archName;

@property (nonatomic, readonly) ObjCAtlasMachOFile *atlas_machOFile;

@end
