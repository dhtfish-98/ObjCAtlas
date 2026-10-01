// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDFatFile.h"

#include <mach-o/arch.h>
#include <mach-o/fat.h>

#import "atlas_CDDataCursor.h"
#import "atlas_CDFatArch.h"
#import "atlas_CDMachOFile.h"

@implementation ObjCAtlasFatFile
{
    NSMutableArray *atlas__arches;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_arches = atlas__arches;

- (id)init;
{
    if ((self = [super init])) {
        atlas__arches = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initAtlasWithData:(NSData *)atlas_data atlas_filename:(NSString *)atlas_filename atlas_searchPathState:(ObjCAtlasSearchPathState *)atlas_searchPathState;
{
    if ((self = [super initAtlasWithData:atlas_data atlas_filename:atlas_filename atlas_searchPathState:atlas_searchPathState])) {
        ObjCAtlasDataCursor *atlas_cursor = [[ObjCAtlasDataCursor alloc] initWithData:atlas_data];

        struct fat_header atlas_header;
        atlas_header.magic = [atlas_cursor atlas_readBigInt32];
        
        //NSLog(@"(testing fat) magic: 0x%x", header.magic);
        if (atlas_header.magic != FAT_MAGIC) {
            return nil;
        }
        
        atlas__arches = [[NSMutableArray alloc] init];
        
        atlas_header.nfat_arch = [atlas_cursor atlas_readBigInt32];
        //NSLog(@"nfat_arch: %u", header.nfat_arch);
        for (NSUInteger atlas_index = 0; atlas_index < atlas_header.nfat_arch; atlas_index++) {
            ObjCAtlasFatArch *atlas_arch = [[ObjCAtlasFatArch alloc] initAtlasWithDataCursor:atlas_cursor];
            atlas_arch.atlas_fatFile = self;
            [atlas__arches addObject:atlas_arch];
        }
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> %lu arches", NSStringFromClass([self class]), self, [self.atlas_arches count]];
}

#pragma mark -


// Case 1: no arch specified
//  - check main file for these, then lock down on that arch:
//    - local arch, 64 bit
//    - local arch, 32 bit
//    - any arch, 64 bit
//    - any arch, 32 bit
//
// Case 2: you specified a specific arch (i386, x86_64, ppc, ppc7400, ppc64, etc.)
//  - only that arch
//
// In either case, we can ignore the cpu subtype

// Returns YES on success, NO on failure.
- (BOOL)atlas_bestMatchForArch:(atlas_CDArch *)atlas_ioArchPtr;
{
    cpu_type_t atlas_targetType = atlas_ioArchPtr->atlas_cputype & ~CPU_ARCH_MASK;

    // Target architecture, 64 bit
    for (ObjCAtlasFatArch *atlas_fatArch in self.atlas_arches) {
        if (atlas_fatArch.atlas_maskedCPUType == atlas_targetType && atlas_fatArch.atlas_uses64BitABI) {
            if (atlas_ioArchPtr != NULL) *atlas_ioArchPtr = atlas_fatArch.atlas_arch;
            return YES;
        }
    }

    // Target architecture, 32 bit
    for (ObjCAtlasFatArch *atlas_fatArch in self.atlas_arches) {
        if (atlas_fatArch.atlas_maskedCPUType == atlas_targetType && atlas_fatArch.atlas_uses64BitABI == NO) {
            if (atlas_ioArchPtr != NULL) *atlas_ioArchPtr = atlas_fatArch.atlas_arch;
            return YES;
        }
    }

    // Any architecture, 64 bit
    for (ObjCAtlasFatArch *atlas_fatArch in self.atlas_arches) {
        if (atlas_fatArch.atlas_uses64BitABI) {
            if (atlas_ioArchPtr != NULL) *atlas_ioArchPtr = atlas_fatArch.atlas_arch;
            return YES;
        }
    }

    // Any architecture, 32 bit
    for (ObjCAtlasFatArch *atlas_fatArch in self.atlas_arches) {
        if (atlas_fatArch.atlas_uses64BitABI == NO) {
            if (atlas_ioArchPtr != NULL) *atlas_ioArchPtr = atlas_fatArch.atlas_arch;
            return YES;
        }
    }

    // Any architecture
    if ([self.atlas_arches count] > 0) {
        if (atlas_ioArchPtr != NULL) *atlas_ioArchPtr = [self.atlas_arches[0] atlas_arch];
        return YES;
    }

    return NO;
}

- (ObjCAtlasFatArch *)atlas_fatArchWithArch:(atlas_CDArch)atlas_cdarch;
{
    for (ObjCAtlasFatArch *atlas_arch in self.atlas_arches) {
        if (atlas_arch.atlas_cputype == atlas_cdarch.atlas_cputype && atlas_arch.atlas_maskedCPUSubtype == (atlas_cdarch.atlas_cpusubtype & ~CPU_SUBTYPE_MASK))
            return atlas_arch;
    }

    return nil;
}

- (ObjCAtlasMachOFile *)atlas_machOFileWithArch:(atlas_CDArch)atlas_cdarch;
{
    return [[self atlas_fatArchWithArch:atlas_cdarch] atlas_machOFile];
}

- (NSArray *)atlas_archNames;
{
    NSMutableArray *atlas_archNames = [NSMutableArray array];
    for (ObjCAtlasFatArch *atlas_arch in self.atlas_arches)
        [atlas_archNames addObject:atlas_arch.atlas_archName];

    return atlas_archNames;
}

- (NSString *)atlas_architectureNameDescription;
{
    return [self.atlas_archNames componentsJoinedByString:@", "];
}

#pragma mark -

- (void)atlas_addArchitecture:(ObjCAtlasFatArch *)atlas_fatArch;
{
    atlas_fatArch.atlas_fatFile = self;
    [self.atlas_arches addObject:atlas_fatArch];
}

- (BOOL)atlas_containsArchitecture:(atlas_CDArch)atlas_arch;
{
    return [self atlas_fatArchWithArch:atlas_arch] != nil;
}

@end
