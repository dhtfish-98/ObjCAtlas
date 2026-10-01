// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#include <mach/machine.h> // For cpu_type_t, cpu_subtype_t

typedef struct {
    cpu_type_t atlas_cputype;
    cpu_subtype_t atlas_cpusubtype;
} atlas_CDArch;

@class ObjCAtlasMachOFile, ObjCAtlasSearchPathState;

NSString *atlas_CDImportNameForPath(NSString *atlas_path);
NSString *atlas_CDNameForCPUType(cpu_type_t atlas_cputype, cpu_subtype_t atlas_cpusubtype);
atlas_CDArch atlas_CDArchFromName(NSString *atlas_name);
BOOL atlas_CDArchUses64BitABI(atlas_CDArch atlas_arch);
BOOL atlas_CDArchUses64BitLibraries(atlas_CDArch atlas_arch);

@interface ObjCAtlasFile : NSObject

// Returns CDFatFile or CDMachOFile
+ (id)atlas_fileWithContentsOfFile:(NSString *)atlas_filename atlas_searchPathState:(ObjCAtlasSearchPathState *)atlas_searchPathState;

- (id)initAtlasWithData:(NSData *)atlas_data atlas_filename:(NSString *)atlas_filename atlas_searchPathState:(ObjCAtlasSearchPathState *)atlas_searchPathState;

@property (readonly) NSString *filename;
@property (readonly) NSData *data;
@property (readonly) ObjCAtlasSearchPathState *atlas_searchPathState;

- (BOOL)atlas_bestMatchForLocalArch:(atlas_CDArch *)atlas_oArchPtr;
- (BOOL)atlas_bestMatchForArch:(atlas_CDArch *)atlas_ioArchPtr;
- (ObjCAtlasMachOFile *)atlas_machOFileWithArch:(atlas_CDArch)atlas_arch;

@property (nonatomic, readonly) NSString *atlas_architectureNameDescription;

@end
