// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDFile.h"

#include <mach-o/arch.h>
#import "atlas_CDFatFile.h"
#import "atlas_CDMachOFile.h"
#import "atlas_CDSearchPathState.h"

NSString *atlas_CDImportNameForPath(NSString *atlas_path)
{
    NSString *atlas_name = [atlas_path lastPathComponent];
    
    // Remove all extensions (make sure extensions like .a.dylib are covered)
    NSString *atlas_nameWithExtensions = atlas_name;
    for (NSInteger atlas_i = ([atlas_nameWithExtensions length] - 1); atlas_i >= 0; atlas_i--) {
        if ([atlas_nameWithExtensions characterAtIndex:atlas_i] == '.')
            atlas_name = [atlas_name substringToIndex:atlas_i];
    }
    
    NSString *atlas_libPrefix = @"lib";
    if ([atlas_name hasPrefix:atlas_libPrefix])
        atlas_name = [atlas_name substringFromIndex:[atlas_libPrefix length]];
    return atlas_name;
}

NSString *atlas_CDNameForCPUType(cpu_type_t atlas_cputype, cpu_subtype_t atlas_cpusubtype)
{
    const NXArchInfo *atlas_archInfo = NXGetArchInfoFromCpuType(atlas_cputype, atlas_cpusubtype);
    if (atlas_archInfo != NULL)
        return [NSString stringWithUTF8String:atlas_archInfo->name];

    // Special cases until the built-in function recognizes these.
    switch (atlas_cputype) {
        case CPU_TYPE_ARM: {
            switch (atlas_cpusubtype) {
                case 11: return @"armv7s"; // Not recognized in 10.8.4
            }
            break;
        }
        case CPU_TYPE_ARM | CPU_ARCH_ABI64: {
            switch (atlas_cpusubtype) {
                case CPU_SUBTYPE_ARM_ALL: return @"arm64"; // Not recognized in 10.8.4
            }
            break;
        }

        default: break;
    }

    return [NSString stringWithFormat:@"0x%x:0x%x", atlas_cputype, atlas_cpusubtype];
}

atlas_CDArch atlas_CDArchFromName(NSString *atlas_name)
{
    atlas_CDArch atlas_arch;

    atlas_arch.atlas_cputype    = CPU_TYPE_ANY;
    atlas_arch.atlas_cpusubtype = 0;

    if (atlas_name == nil)
        return atlas_arch;

    const NXArchInfo *atlas_archInfo = NXGetArchInfoFromName([atlas_name UTF8String]);
    if (atlas_archInfo == NULL) {
        if ([atlas_name isEqualToString:@"armv7s"]) { // Not recognized in 10.8.4
            atlas_arch.atlas_cputype    = CPU_TYPE_ARM;
            atlas_arch.atlas_cpusubtype = 11;
        } else if ([atlas_name isEqualToString:@"arm64"]) { // Not recognized in 10.8.4
            atlas_arch.atlas_cputype    = CPU_TYPE_ARM | CPU_ARCH_ABI64;
            atlas_arch.atlas_cpusubtype = CPU_SUBTYPE_ARM_ALL;
        } else {
            NSString *atlas_ignore;
            
            NSScanner *atlas_scanner = [[NSScanner alloc] initWithString:atlas_name];
            if ([atlas_scanner scanHexInt:(uint32_t *)&atlas_arch.atlas_cputype]
                && [atlas_scanner scanString:@":" intoString:&atlas_ignore]
                && [atlas_scanner scanHexInt:(uint32_t *)&atlas_arch.atlas_cpusubtype]) {
                // Great!
                //NSLog(@"scanned 0x%08x : 0x%08x from '%@'", arch.cputype, arch.cpusubtype, name);
            } else {
                atlas_arch.atlas_cputype    = CPU_TYPE_ANY;
                atlas_arch.atlas_cpusubtype = 0;
            }
        }
    } else {
        atlas_arch.atlas_cputype    = atlas_archInfo->cputype;
        atlas_arch.atlas_cpusubtype = atlas_archInfo->cpusubtype;
    }

    return atlas_arch;
}

BOOL atlas_CDArchUses64BitABI(atlas_CDArch atlas_arch)
{
    return (atlas_arch.atlas_cputype & CPU_ARCH_ABI64) == CPU_ARCH_ABI64;
}

BOOL atlas_CDArchUses64BitLibraries(atlas_CDArch atlas_arch)
{
    return (atlas_arch.atlas_cpusubtype & CPU_SUBTYPE_LIB64) == CPU_SUBTYPE_LIB64;
}

#pragma mark -

@interface ObjCAtlasFile ()
@end

#pragma mark -

@implementation ObjCAtlasFile
{
    NSString *atlas__filename;
    NSData *atlas__data;
    ObjCAtlasSearchPathState *atlas__searchPathState;
}

// Returns CDFatFile or CDMachOFile

// Preserve the original explicit property storage after renaming.
@synthesize filename = atlas__filename;
@synthesize data = atlas__data;
@synthesize atlas_searchPathState = atlas__searchPathState;
+ (id)atlas_fileWithContentsOfFile:(NSString *)atlas_filename atlas_searchPathState:(ObjCAtlasSearchPathState *)atlas_searchPathState;
{
    NSData *atlas_data = [NSData dataWithContentsOfMappedFile:atlas_filename];
    ObjCAtlasFatFile *atlas_fatFile = [[ObjCAtlasFatFile alloc] initAtlasWithData:atlas_data atlas_filename:atlas_filename atlas_searchPathState:atlas_searchPathState];
    if (atlas_fatFile != nil)
        return atlas_fatFile;
    
    ObjCAtlasMachOFile *atlas_machOFile = [[ObjCAtlasMachOFile alloc] initAtlasWithData:atlas_data atlas_filename:atlas_filename atlas_searchPathState:atlas_searchPathState];
    return atlas_machOFile;
}

- (id)initAtlasWithData:(NSData *)atlas_data atlas_filename:(NSString *)atlas_filename atlas_searchPathState:(ObjCAtlasSearchPathState *)atlas_searchPathState;
{
    if ((self = [super init])) {
        // Otherwise reading the magic number fails.
        if ([atlas_data length] < 4) {
            return nil;
        }
        
        atlas__filename        = atlas_filename;
        atlas__data            = atlas_data;
        atlas__searchPathState = atlas_searchPathState;
    }

    return self;
}

#pragma mark -

// Return YES on success.  If oArchPtr is not NULL, return the best match.
// Return NO on failure, oArchPtr is untouched.

- (BOOL)atlas_bestMatchForLocalArch:(atlas_CDArch *)atlas_oArchPtr;
{
    const NXArchInfo *atlas_archInfo = NXGetLocalArchInfo();
    if (atlas_archInfo == NULL)
        return NO;
    
    atlas_CDArch atlas_arch = { atlas_archInfo->cputype, atlas_archInfo->cpusubtype };
    
    if ([self atlas_bestMatchForArch:&atlas_arch]) {
        if (atlas_oArchPtr != NULL)
            *atlas_oArchPtr = atlas_arch;
        return YES;
    }
    
    return NO;
}

- (BOOL)atlas_bestMatchForArch:(atlas_CDArch *)atlas_ioArchPtr;
{
    return NO;
}

- (ObjCAtlasMachOFile *)atlas_machOFileWithArch:(atlas_CDArch)atlas_arch;
{
    return nil;
}

- (NSString *)atlas_architectureNameDescription;
{
    return nil;
}

@end
