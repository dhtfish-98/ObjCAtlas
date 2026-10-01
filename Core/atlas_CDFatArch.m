// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDFatArch.h"

#include <mach-o/fat.h>
#import "atlas_CDDataCursor.h"
#import "atlas_CDFatFile.h"
#import "atlas_CDMachOFile.h"

@implementation ObjCAtlasFatArch
{
    __weak ObjCAtlasFatFile *atlas__fatFile;
    
    // This is essentially struct fat_arch, but this way our property accessors can be synthesized.
    cpu_type_t atlas__cputype;
    cpu_subtype_t atlas__cpusubtype;
    uint32_t atlas__offset;
    uint32_t atlas__size;
    uint32_t atlas__align;
    
    ObjCAtlasMachOFile *atlas__machOFile; // Lazily create this.
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_cputype = atlas__cputype;
@synthesize atlas_cpusubtype = atlas__cpusubtype;
@synthesize atlas_offset = atlas__offset;
@synthesize atlas_size = atlas__size;
@synthesize atlas_align = atlas__align;
@synthesize atlas_fatFile = atlas__fatFile;
@synthesize atlas_machOFile = atlas__machOFile;

- (id)initAtlasWithMachOFile:(ObjCAtlasMachOFile *)atlas_machOFile;
{
    if ((self = [super init])) {
        atlas__machOFile = atlas_machOFile;
        NSParameterAssert([atlas_machOFile.data length] < 0x100000000);
        
        atlas__cputype    = atlas__machOFile.atlas_cputype;
        atlas__cpusubtype = atlas__machOFile.atlas_cpusubtype;
        atlas__offset     = 0; // Would be filled in when this is written to disk
        atlas__size       = (uint32_t)[atlas__machOFile.data length];
        atlas__align      = 12; // 2**12 = 4096 (0x1000)
    }
    
    return self;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasDataCursor *)atlas_cursor;
{
    if ((self = [super init])) {
        atlas__cputype    = [atlas_cursor atlas_readBigInt32];
        atlas__cpusubtype = [atlas_cursor atlas_readBigInt32];
        atlas__offset     = [atlas_cursor atlas_readBigInt32];
        atlas__size       = [atlas_cursor atlas_readBigInt32];
        atlas__align      = [atlas_cursor atlas_readBigInt32];
        
        //NSLog(@"self: %@", self);
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"64 bit ABI? %d, cputype: 0x%08x, cpusubtype: 0x%08x, offset: 0x%08x (%8u), size: 0x%08x (%8u), align: 2^%u (%x), arch name: %@",
            self.atlas_uses64BitABI, self.atlas_cputype, self.atlas_cpusubtype, self.atlas_offset, self.atlas_offset, self.atlas_size, self.atlas_size,
            self.atlas_align, 1 << self.atlas_align, self.atlas_archName];
}

#pragma mark -

- (cpu_type_t)atlas_maskedCPUType;
{
    return self.atlas_cputype & ~CPU_ARCH_MASK;
}

- (cpu_subtype_t)atlas_maskedCPUSubtype;
{
    return self.atlas_cpusubtype & ~CPU_SUBTYPE_MASK;
}

- (BOOL)atlas_uses64BitABI;
{
    return atlas_CDArchUses64BitABI(self.atlas_arch);
}

- (BOOL)atlas_uses64BitLibraries;
{
    return atlas_CDArchUses64BitLibraries(self.atlas_arch);
}

- (atlas_CDArch)atlas_arch;
{
    atlas_CDArch atlas_arch = { self.atlas_cputype, self.atlas_cpusubtype };

    return atlas_arch;
}

// Must not return nil.
- (NSString *)atlas_archName;
{
    return atlas_CDNameForCPUType(self.atlas_cputype, self.atlas_cpusubtype);
}

- (ObjCAtlasMachOFile *)atlas_machOFile;
{
    if (atlas__machOFile == nil) {
        NSData *atlas_data = [NSData dataWithBytesNoCopy:((uint8_t *)[self.atlas_fatFile.data bytes] + self.atlas_offset) length:self.atlas_size freeWhenDone:NO];
        atlas__machOFile = [[ObjCAtlasMachOFile alloc] initAtlasWithData:atlas_data atlas_filename:self.atlas_fatFile.filename atlas_searchPathState:self.atlas_fatFile.atlas_searchPathState];
    }

    return atlas__machOFile;
}

@end
