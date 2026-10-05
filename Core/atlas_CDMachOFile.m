// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDMachOFile.h"

#include <mach-o/arch.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>

#import "atlas_CDMachOFileDataCursor.h"
#import "atlas_CDFatFile.h"
#import "atlas_CDLoadCommand.h"
#import "atlas_CDLCDyldInfo.h"
#import "atlas_CDLCDylib.h"
#import "atlas_CDLCDynamicSymbolTable.h"
#import "atlas_CDLCEncryptionInfo.h"
#import "atlas_CDLCRunPath.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDLCSymbolTable.h"
#import "atlas_CDLCUUID.h"
#import "atlas_CDLCVersionMinimum.h"
#import "atlas_CDObjectiveC1Processor.h"
#import "atlas_CDObjectiveC2Processor.h"
#import "atlas_CDSection.h"
#import "atlas_CDSymbol.h"
#import "atlas_CDRelocationInfo.h"
#import "atlas_CDSearchPathState.h"
#import "atlas_CDLCSourceVersion.h"
#import "atlas_CDLCBuildVersion.h"

static NSString *atlas_CDMachOFileMagicNumberDescription(uint32_t atlas_magic)
{
    switch (atlas_magic) {
        case MH_MAGIC:    return @"MH_MAGIC";
        case MH_CIGAM:    return @"MH_CIGAM";
        case MH_MAGIC_64: return @"MH_MAGIC_64";
        case MH_CIGAM_64: return @"MH_CIGAM_64";
    }

    return [NSString stringWithFormat:@"0x%08x", atlas_magic];
}

@implementation ObjCAtlasMachOFile
{
    atlas_CDByteOrder atlas__byteOrder;
    
    NSArray *atlas__loadCommands;
    NSArray *atlas__dylibLoadCommands;
    NSArray *atlas__segments;
    ObjCAtlasLCSymbolTable *atlas__symbolTable;
    ObjCAtlasLCDynamicSymbolTable *atlas__dynamicSymbolTable;
    ObjCAtlasLCDyldInfo *atlas__dyldInfo;
    ObjCAtlasLCDylib *atlas__dylibIdentifier;
    ObjCAtlasLCVersionMinimum *atlas__minVersionMacOSX;
    ObjCAtlasLCVersionMinimum *atlas__minVersionIOS;
    ObjCAtlasLCSourceVersion *atlas__sourceVersion;
    ObjCAtlasLCBuildVersion *atlas__buildVersion;
    NSArray *atlas__runPaths;
    NSArray *atlas__runPathCommands;
    NSArray *atlas__dyldEnvironment;
    NSArray *atlas__reExportedDylibs;

    // The parts of struct mach_header_64 pulled out so that our property accessors can be synthesized.
	uint32_t atlas__magic;
	cpu_type_t atlas__cputype;
	cpu_subtype_t atlas__cpusubtype;
	uint32_t atlas__filetype;
	uint32_t atlas__ncmds;
	uint32_t atlas__sizeofcmds;
	uint32_t atlas__flags;
	uint32_t atlas__reserved;
    
    BOOL atlas__uses64BitABI;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_byteOrder = atlas__byteOrder;
@synthesize atlas_magic = atlas__magic;
@synthesize atlas_cputype = atlas__cputype;
@synthesize atlas_cpusubtype = atlas__cpusubtype;
@synthesize atlas_filetype = atlas__filetype;
@synthesize atlas_flags = atlas__flags;
@synthesize atlas_loadCommands = atlas__loadCommands;
@synthesize atlas_dylibLoadCommands = atlas__dylibLoadCommands;
@synthesize atlas_segments = atlas__segments;
@synthesize atlas_runPaths = atlas__runPaths;
@synthesize atlas_runPathCommands = atlas__runPathCommands;
@synthesize atlas_dyldEnvironment = atlas__dyldEnvironment;
@synthesize atlas_reExportedDylibs = atlas__reExportedDylibs;
@synthesize atlas_symbolTable = atlas__symbolTable;
@synthesize atlas_dynamicSymbolTable = atlas__dynamicSymbolTable;
@synthesize atlas_dyldInfo = atlas__dyldInfo;
@synthesize atlas_dylibIdentifier = atlas__dylibIdentifier;
@synthesize atlas_minVersionMacOSX = atlas__minVersionMacOSX;
@synthesize atlas_minVersionIOS = atlas__minVersionIOS;
@synthesize atlas_sourceVersion = atlas__sourceVersion;
@synthesize atlas_buildVersion = atlas__buildVersion;
@synthesize atlas_uses64BitABI = atlas__uses64BitABI;

- (id)init;
{
    if ((self = [super init])) {
        atlas__byteOrder = atlas_CDByteOrder_LittleEndian;
    }
    
    return self;
}

- (id)initAtlasWithData:(NSData *)atlas_data atlas_filename:(NSString *)atlas_filename atlas_searchPathState:(ObjCAtlasSearchPathState *)atlas_searchPathState;
{
    if ((self = [super initAtlasWithData:atlas_data atlas_filename:atlas_filename atlas_searchPathState:atlas_searchPathState])) {
        atlas__byteOrder = atlas_CDByteOrder_LittleEndian;
        
        ObjCAtlasDataCursor *atlas_cursor = [[ObjCAtlasDataCursor alloc] initWithData:atlas_data];
        atlas__magic = [atlas_cursor atlas_readBigInt32];
        if (atlas__magic == MH_MAGIC || atlas__magic == MH_MAGIC_64) {
            atlas__byteOrder = atlas_CDByteOrder_BigEndian;
        } else if (atlas__magic == MH_CIGAM || atlas__magic == MH_CIGAM_64) {
            atlas__byteOrder = atlas_CDByteOrder_LittleEndian;
        } else {
            return nil;
        }
        
        atlas__uses64BitABI = (atlas__magic == MH_MAGIC_64) || (atlas__magic == MH_CIGAM_64);
        
        if (atlas__byteOrder == atlas_CDByteOrder_LittleEndian) {
            atlas__cputype    = [atlas_cursor atlas_readLittleInt32];
            atlas__cpusubtype = [atlas_cursor atlas_readLittleInt32];
            atlas__filetype   = [atlas_cursor atlas_readLittleInt32];
            atlas__ncmds      = [atlas_cursor atlas_readLittleInt32];
            atlas__sizeofcmds = [atlas_cursor atlas_readLittleInt32];
            atlas__flags      = [atlas_cursor atlas_readLittleInt32];
            if (atlas__uses64BitABI) {
                atlas__reserved = [atlas_cursor atlas_readLittleInt32];
            }
        } else {
            atlas__cputype    = [atlas_cursor atlas_readBigInt32];
            atlas__cpusubtype = [atlas_cursor atlas_readBigInt32];
            atlas__filetype   = [atlas_cursor atlas_readBigInt32];
            atlas__ncmds      = [atlas_cursor atlas_readBigInt32];
            atlas__sizeofcmds = [atlas_cursor atlas_readBigInt32];
            atlas__flags      = [atlas_cursor atlas_readBigInt32];
            if (atlas__uses64BitABI) {
                atlas__reserved = [atlas_cursor atlas_readBigInt32];
            }
        }
        
        NSAssert(atlas__uses64BitABI == atlas_CDArchUses64BitABI((atlas_CDArch){ .atlas_cputype = atlas__cputype, .atlas_cpusubtype = atlas__cpusubtype }), @"Header magic should match cpu arch", nil);
        
        NSUInteger atlas_headerOffset = atlas__uses64BitABI ? sizeof(struct mach_header_64) : sizeof(struct mach_header);
        ObjCAtlasMachOFileDataCursor *atlas_fileCursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self atlas_offset:atlas_headerOffset];
        [self atlas__readLoadCommands:atlas_fileCursor atlas_count:atlas__ncmds];
    }

    return self;
}

- (void)atlas__readLoadCommands:(ObjCAtlasMachOFileDataCursor *)atlas_cursor atlas_count:(uint32_t)atlas_count;
{
    NSMutableArray *atlas_loadCommands      = [[NSMutableArray alloc] init];
    NSMutableArray *atlas_dylibLoadCommands = [[NSMutableArray alloc] init];
    NSMutableArray *atlas_segments          = [[NSMutableArray alloc] init];
    NSMutableArray *atlas_runPaths          = [[NSMutableArray alloc] init];
    NSMutableArray *atlas_runPathCommands   = [[NSMutableArray alloc] init];
    NSMutableArray *atlas_dyldEnvironment   = [[NSMutableArray alloc] init];
    NSMutableArray *atlas_reExportedDylibs  = [[NSMutableArray alloc] init];
    
    for (uint32_t atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
        ObjCAtlasLoadCommand *atlas_loadCommand = [ObjCAtlasLoadCommand atlas_loadCommandWithDataCursor:atlas_cursor];
        if (atlas_loadCommand != nil) {
            [atlas_loadCommands addObject:atlas_loadCommand];

            if (atlas_loadCommand.atlas_cmd == LC_VERSION_MIN_MACOSX)                        self.atlas_minVersionMacOSX = (ObjCAtlasLCVersionMinimum *)atlas_loadCommand;
            if (atlas_loadCommand.atlas_cmd == LC_VERSION_MIN_IPHONEOS)                      self.atlas_minVersionIOS = (ObjCAtlasLCVersionMinimum *)atlas_loadCommand;
            if (atlas_loadCommand.atlas_cmd == LC_DYLD_ENVIRONMENT)                          [atlas_dyldEnvironment addObject:atlas_loadCommand];
            if (atlas_loadCommand.atlas_cmd == LC_REEXPORT_DYLIB)                            [atlas_reExportedDylibs addObject:atlas_loadCommand];
            if (atlas_loadCommand.atlas_cmd == LC_ID_DYLIB)                                  self.atlas_dylibIdentifier = (ObjCAtlasLCDylib *)atlas_loadCommand;

            if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCSourceVersion class]])           self.atlas_sourceVersion = (ObjCAtlasLCSourceVersion *)atlas_loadCommand;
            else if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCBuildVersion class]])       self.atlas_buildVersion = (ObjCAtlasLCBuildVersion *)atlas_loadCommand;
            else if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCDylib class]])              [atlas_dylibLoadCommands addObject:atlas_loadCommand];
            else if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCSegment class]])            [atlas_segments addObject:atlas_loadCommand];
            else if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCSymbolTable class]])        self.atlas_symbolTable = (ObjCAtlasLCSymbolTable *)atlas_loadCommand;
            else if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCDynamicSymbolTable class]]) self.atlas_dynamicSymbolTable = (ObjCAtlasLCDynamicSymbolTable *)atlas_loadCommand;
            else if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCDyldInfo class]])           self.atlas_dyldInfo = (ObjCAtlasLCDyldInfo *)atlas_loadCommand;
            else if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCRunPath class]]) {
                [atlas_runPaths addObject:[(ObjCAtlasLCRunPath *)atlas_loadCommand atlas_resolvedRunPath]];
                [atlas_runPathCommands addObject:atlas_loadCommand];
            }
        }
        //NSLog(@"loadCommand: %@", loadCommand);
    }
    atlas__loadCommands      = [atlas_loadCommands copy];
    atlas__dylibLoadCommands = [atlas_dylibLoadCommands copy];
    atlas__segments          = [atlas_segments copy];
    atlas__runPaths          = [atlas_runPaths copy];
    atlas__runPathCommands   = [atlas_runPathCommands copy];
    atlas__dyldEnvironment   = [atlas_dyldEnvironment copy];
    atlas__reExportedDylibs  = [atlas_reExportedDylibs copy];

    for (ObjCAtlasLoadCommand *atlas_loadCommand in atlas__loadCommands) {
        [atlas_loadCommand atlas_machOFileDidReadLoadCommands:self];
    }
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> magic: 0x%08x, cputype: %x, cpusubtype: %x, filetype: %d, ncmds: %ld, sizeofcmds: %d, flags: 0x%x, uses64BitABI? %d, filename: %@, data: %p",
            NSStringFromClass([self class]), self,
            [self atlas_magic], [self atlas_cputype], [self atlas_cpusubtype], [self atlas_filetype], [atlas__loadCommands count], 0, [self atlas_flags], self.atlas_uses64BitABI,
            self.filename, self.data];
}

#pragma mark -

- (ObjCAtlasMachOFile *)atlas_machOFileWithArch:(atlas_CDArch)atlas_arch;
{
    if (self.atlas_cputype == atlas_arch.atlas_cputype && self.atlas_maskedCPUSubtype == (atlas_arch.atlas_cpusubtype & ~CPU_SUBTYPE_MASK))
        return self;

    return nil;
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

- (NSUInteger)atlas_ptrSize;
{
    return self.atlas_uses64BitABI ? sizeof(uint64_t) : sizeof(uint32_t);
}
             
// We only have one architecture, so it is by default the best match.  
- (BOOL)atlas_bestMatchForArch:(atlas_CDArch *)atlas_ioArchPtr;
{
    if (atlas_ioArchPtr != NULL) {
        atlas_ioArchPtr->atlas_cputype    = self.atlas_cputype;
        atlas_ioArchPtr->atlas_cpusubtype = self.atlas_cpusubtype;
    }

    return YES;
}

- (NSString *)atlas_filetypeDescription;
{
    switch ([self atlas_filetype]) {
        case MH_OBJECT:      return @"OBJECT";
        case MH_EXECUTE:     return @"EXECUTE";
        case MH_FVMLIB:      return @"FVMLIB";
        case MH_CORE:        return @"CORE";
        case MH_PRELOAD:     return @"PRELOAD";
        case MH_DYLIB:       return @"DYLIB";
        case MH_DYLINKER:    return @"DYLINKER";
        case MH_BUNDLE:      return @"BUNDLE";
        case MH_DYLIB_STUB:  return @"DYLIB_STUB";
        case MH_DSYM:        return @"DSYM";
        case MH_KEXT_BUNDLE: return @"KEXT_BUNDLE";
        default:
            break;
    }

    return nil;
}

- (NSString *)atlas_flagDescription;
{
    NSMutableArray *atlas_setFlags = [NSMutableArray array];
    uint32_t atlas_flags = [self atlas_flags];
    if (atlas_flags & MH_NOUNDEFS)                [atlas_setFlags addObject:@"NOUNDEFS"];
    if (atlas_flags & MH_INCRLINK)                [atlas_setFlags addObject:@"INCRLINK"];
    if (atlas_flags & MH_DYLDLINK)                [atlas_setFlags addObject:@"DYLDLINK"];
    if (atlas_flags & MH_BINDATLOAD)              [atlas_setFlags addObject:@"BINDATLOAD"];
    if (atlas_flags & MH_PREBOUND)                [atlas_setFlags addObject:@"PREBOUND"];
    if (atlas_flags & MH_SPLIT_SEGS)              [atlas_setFlags addObject:@"SPLIT_SEGS"];
    if (atlas_flags & MH_LAZY_INIT)               [atlas_setFlags addObject:@"LAZY_INIT"];
    if (atlas_flags & MH_TWOLEVEL)                [atlas_setFlags addObject:@"TWOLEVEL"];
    if (atlas_flags & MH_FORCE_FLAT)              [atlas_setFlags addObject:@"FORCE_FLAT"];
    if (atlas_flags & MH_NOMULTIDEFS)             [atlas_setFlags addObject:@"NOMULTIDEFS"];
    if (atlas_flags & MH_NOFIXPREBINDING)         [atlas_setFlags addObject:@"NOFIXPREBINDING"];
    if (atlas_flags & MH_PREBINDABLE)             [atlas_setFlags addObject:@"PREBINDABLE"];
    if (atlas_flags & MH_ALLMODSBOUND)            [atlas_setFlags addObject:@"ALLMODSBOUND"];
    if (atlas_flags & MH_SUBSECTIONS_VIA_SYMBOLS) [atlas_setFlags addObject:@"SUBSECTIONS_VIA_SYMBOLS"];
    if (atlas_flags & MH_CANONICAL)               [atlas_setFlags addObject:@"CANONICAL"];
    if (atlas_flags & MH_WEAK_DEFINES)            [atlas_setFlags addObject:@"WEAK_DEFINES"];
    if (atlas_flags & MH_BINDS_TO_WEAK)           [atlas_setFlags addObject:@"BINDS_TO_WEAK"];
    if (atlas_flags & MH_ALLOW_STACK_EXECUTION)   [atlas_setFlags addObject:@"ALLOW_STACK_EXECUTION"];
    if (atlas_flags & MH_ROOT_SAFE)               [atlas_setFlags addObject:@"ROOT_SAFE"];
    if (atlas_flags & MH_SETUID_SAFE)             [atlas_setFlags addObject:@"SETUID_SAFE"];
    if (atlas_flags & MH_NO_REEXPORTED_DYLIBS)    [atlas_setFlags addObject:@"NO_REEXPORTED_DYLIBS"];
    if (atlas_flags & MH_PIE)                     [atlas_setFlags addObject:@"PIE"];

    return [atlas_setFlags componentsJoinedByString:@" "];
}

#pragma mark -

- (ObjCAtlasLCSegment *)atlas_dataConstSegment
{
    // macho objects from iOS 9 appear to store various sections
    // in __DATA_CONST that were previously found in __DATA
    ObjCAtlasLCSegment *atlas_seg = [self atlas_segmentWithName:@"__DATA_CONST"];

    // Fall back on __DATA if it is not found for earlier behavior
    if (!atlas_seg) {
        atlas_seg = [self atlas_segmentWithName:@"__DATA"];
    }
    return atlas_seg;
}

- (ObjCAtlasLCSegment *)atlas_segmentWithName:(NSString *)atlas_segmentName;
{
    for (id atlas_loadCommand in atlas__loadCommands) {
        if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCSegment class]] && [[atlas_loadCommand name] isEqual:atlas_segmentName]) {
            return atlas_loadCommand;
        }
    }

    return nil;
}

- (ObjCAtlasLCSegment *)atlas_segmentContainingAddress:(NSUInteger)atlas_address;
{
    for (id atlas_loadCommand in atlas__loadCommands) {
        if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCSegment class]] && [atlas_loadCommand atlas_containsAddress:atlas_address]) {
            return atlas_loadCommand;
        }
    }

    return nil;
}

- (void)atlas_showWarning:(NSString *)atlas_warning;
{
    NSLog(@"Warning: %@", atlas_warning);
}

- (NSString *)atlas_stringAtAddress:(NSUInteger)atlas_address;
{
    const void *atlas_ptr;

    if (atlas_address == 0)
        return nil;

    ObjCAtlasLCSegment *atlas_segment = [self atlas_segmentContainingAddress:atlas_address];
    if (atlas_segment == nil) {
        NSLog(@"Error: Cannot find offset for address 0x%08lx in stringAtAddress:", atlas_address);
        exit(5);
        return nil;
    }

    if ([atlas_segment atlas_isProtected]) {
        NSData *atlas_d2 = [atlas_segment atlas_decryptedData];
        NSUInteger atlas_d2Offset = [atlas_segment atlas_segmentOffsetForAddress:atlas_address];
        if (atlas_d2Offset == 0)
            return nil;

        if (atlas_d2Offset >= atlas_d2.length) {
            [NSException raise:NSRangeException format:@"String address exceeds decrypted segment."];
        }
        atlas_ptr = (uint8_t *)[atlas_d2 bytes] + atlas_d2Offset;
        const void *atlas_end = memchr(atlas_ptr, 0, atlas_d2.length - atlas_d2Offset);
        if (atlas_end == NULL) {
            [NSException raise:NSRangeException format:@"Unterminated string in decrypted segment."];
        }
        return [[NSString alloc] initWithBytes:atlas_ptr length:(const uint8_t *)atlas_end - (const uint8_t *)atlas_ptr encoding:NSASCIIStringEncoding];
    }

    NSUInteger atlas_offset = [self atlas_dataOffsetForAddress:atlas_address];
    if (atlas_offset == 0)
        return nil;

    if (atlas_offset >= self.data.length) {
        [NSException raise:NSRangeException format:@"String address exceeds file data."];
    }
    atlas_ptr = (uint8_t *)[self.data bytes] + atlas_offset;
    const void *atlas_end = memchr(atlas_ptr, 0, self.data.length - atlas_offset);
    if (atlas_end == NULL) {
        [NSException raise:NSRangeException format:@"Unterminated string in file data."];
    }
    return [[NSString alloc] initWithBytes:atlas_ptr length:(const uint8_t *)atlas_end - (const uint8_t *)atlas_ptr encoding:NSASCIIStringEncoding];
}

- (NSUInteger)atlas_dataOffsetForAddress:(NSUInteger)atlas_address;
{
    if (atlas_address == 0)
        return 0;

    ObjCAtlasLCSegment *atlas_segment = [self atlas_segmentContainingAddress:atlas_address];
    if (atlas_segment == nil) {
        NSLog(@"Error: Cannot find offset for address 0x%08lx in dataOffsetForAddress:", atlas_address);
        exit(5);
    }

//    if ([segment isProtected]) {
//        NSLog(@"Error: Segment is protected.");
//        exit(5);
//    }

#if 0
    NSLog(@"---------->");
    NSLog(@"segment is: %@", segment);
    NSLog(@"address: 0x%08x", address);
    NSLog(@"CDFile offset:    0x%08x", offset);
    NSLog(@"file off for address: 0x%08x", [segment fileOffsetForAddress:address]);
    NSLog(@"data offset:      0x%08x", offset + [segment fileOffsetForAddress:address]);
    NSLog(@"<----------");
#endif
    return [atlas_segment atlas_fileOffsetForAddress:atlas_address];
}

- (const void *)bytes;
{
    return [self.data bytes];
}

- (const void *)atlas_bytesAtOffset:(NSUInteger)atlas_offset;
{
    if (atlas_offset > self.data.length) {
        [NSException raise:NSRangeException format:@"Offset exceeds file data."];
    }
    return (uint8_t *)[self.data bytes] + atlas_offset;
}

- (NSData *)atlas_dataAtOffset:(NSUInteger)atlas_offset length:(NSUInteger)atlas_length;
{
    if (atlas_offset > self.data.length || atlas_length > self.data.length - atlas_offset) {
        [NSException raise:NSRangeException format:@"Range exceeds file data."];
    }
    return [self.data subdataWithRange:NSMakeRange(atlas_offset, atlas_length)];
}

- (NSString *)atlas_importBaseName;
{
    if ([self atlas_filetype] == MH_DYLIB) {
        return atlas_CDImportNameForPath(self.filename);
    }

    return nil;
}

#pragma mark -

- (BOOL)atlas_isEncrypted;
{
    for (ObjCAtlasLoadCommand *atlas_loadCommand in atlas__loadCommands) {
        if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCEncryptionInfo class]] && [(ObjCAtlasLCEncryptionInfo *)atlas_loadCommand atlas_isEncrypted]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)atlas_hasProtectedSegments;
{
    for (ObjCAtlasLoadCommand *atlas_loadCommand in atlas__loadCommands) {
        if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCSegment class]] && [(ObjCAtlasLCSegment *)atlas_loadCommand atlas_isProtected])
            return YES;
    }

    return NO;
}

- (BOOL)atlas_canDecryptAllSegments;
{
    for (ObjCAtlasLoadCommand *atlas_loadCommand in atlas__loadCommands) {
        if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCSegment class]] && [(ObjCAtlasLCSegment *)atlas_loadCommand atlas_canDecrypt] == NO)
            return NO;
    }

    return YES;
}

- (NSString *)atlas_loadCommandString:(BOOL)atlas_isVerbose;
{
    NSMutableString *atlas_resultString = [NSMutableString string];
    NSUInteger atlas_count = [atlas__loadCommands count];
    for (NSUInteger atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
        [atlas_resultString appendFormat:@"Load command %lu\n", atlas_index];
        ObjCAtlasLoadCommand *atlas_loadCommand = atlas__loadCommands[atlas_index];
        [atlas_loadCommand atlas_appendToString:atlas_resultString atlas_verbose:atlas_isVerbose];
        [atlas_resultString appendString:@"\n"];
    }

    return atlas_resultString;
}

- (NSString *)atlas_headerString:(BOOL)atlas_isVerbose;
{
    NSMutableString *atlas_resultString = [NSMutableString string];
    [atlas_resultString appendString:@"Mach header\n"];
    [atlas_resultString appendString:@"      magic cputype cpusubtype   filetype ncmds sizeofcmds      flags\n"];
    // Grr, %11@ doesn't work.
    if (atlas_isVerbose)
        [atlas_resultString appendFormat:@"%11@ %7@ %10u   %8@ %5lu %10u %@\n",
                      atlas_CDMachOFileMagicNumberDescription([self atlas_magic]), [self atlas_archName], [self atlas_cpusubtype],
                      [self atlas_filetypeDescription], [atlas__loadCommands count], 0, [self atlas_flagDescription]];
    else
        [atlas_resultString appendFormat:@" 0x%08x %7u %10u   %8u %5lu %10u 0x%08x\n",
                      [self atlas_magic], [self atlas_cputype], [self atlas_cpusubtype], [self atlas_filetype], [atlas__loadCommands count], 0, [self atlas_flags]];
    [atlas_resultString appendString:@"\n"];

    return atlas_resultString;
}

- (NSUUID *)UUID;
{
    for (ObjCAtlasLoadCommand *atlas_loadCommand in atlas__loadCommands)
        if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCUUID class]])
            return [(ObjCAtlasLCUUID *)atlas_loadCommand UUID];

    return nil;
}

// Must not return nil.
- (NSString *)atlas_archName;
{
    return atlas_CDNameForCPUType([self atlas_cputype], [self atlas_cpusubtype]);
}

- (void)atlas_logInfoForAddress:(NSUInteger)atlas_address;
{
    if (atlas_address != 0) {
        ObjCAtlasLCSegment *atlas_segment = [self atlas_segmentContainingAddress:atlas_address];
        if (atlas_segment == nil) {
            NSLog(@"No segment contains address: %016lx", atlas_address);
        } else {
            //NSLog(@"Found address %016lx in segment, sections= %@", address, [segment sections]);
            ObjCAtlasSection *atlas_section = [atlas_segment atlas_sectionContainingAddress:atlas_address];
            if (atlas_section == nil) {
                NSLog(@"Found address %016lx in segment %@, but not in a section", atlas_address, [atlas_segment name]);
            } else {
                NSLog(@"Found address %016lx in segment %@, section %@", atlas_address, [atlas_segment name], [atlas_section atlas_sectionName]);
            }
        }

        NSString *atlas_str = [self atlas_stringAtAddress:atlas_address];
        NSLog(@"      address %016lx as a string: '%@' (length %lu)", atlas_address, atlas_str, [atlas_str length]);
        NSLog(@"      address %016lx data offset: %lu", atlas_address, [self atlas_dataOffsetForAddress:atlas_address]);
    }
}

- (NSString *)atlas_externalClassNameForAddress:(NSUInteger)atlas_address;
{
    // Not for NSCFArray (NSMutableArray), NSSimpleAttributeDictionaryEnumerator (NSEnumerator), NSSimpleAttributeDictionary (NSDictionary), etc.
    // It turns out NSMutableArray is in /System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation, so...
    // ... it's an undefined symbol, need to look it up.
    ObjCAtlasRelocationInfo *atlas_rinfo = [self.atlas_dynamicSymbolTable atlas_relocationEntryWithOffset:atlas_address - [self.atlas_symbolTable atlas_baseAddress]];
    //NSLog(@"rinfo: %@", rinfo);
    if (atlas_rinfo != nil) {
        ObjCAtlasSymbol *atlas_symbol = [[self.atlas_symbolTable atlas_symbols] objectAtIndex:atlas_rinfo.atlas_symbolnum];
        //NSLog(@"symbol: %@", symbol);

        // Now we could use GET_LIBRARY_ORDINAL(), look up the the appropriate mach-o file (being sure to have loaded them even without -r),
        // look up the symbol in that mach-o file, get the address, look up the class based on that address, and finally get the class name
        // from that.

        // Or, we could be lazy and take advantage of the fact that the class name we're after is in the symbol name:
        NSString *atlas_str = [atlas_symbol name];
        if ([atlas_str hasPrefix:atlas_ObjCClassSymbolPrefix]) {
            return [atlas_str substringFromIndex:[atlas_ObjCClassSymbolPrefix length]];
        } else {
            NSLog(@"Warning: Unknown prefix on symbol name... %@ (addr %lx)", atlas_str, atlas_address);
            return atlas_str;
        }
    }

    // This is fine, they might really be root objects.  NSObject, NSProxy.
    return nil;
}

- (BOOL)atlas_hasRelocationEntryForAddress:(NSUInteger)atlas_address;
{
    ObjCAtlasRelocationInfo *atlas_rinfo = [self.atlas_dynamicSymbolTable atlas_relocationEntryWithOffset:atlas_address - [self.atlas_symbolTable atlas_baseAddress]];
    //NSLog(@"%s, rinfo= %@", __cmd, rinfo);
    return atlas_rinfo != nil;
}

- (BOOL)atlas_hasRelocationEntryForAddress2:(NSUInteger)atlas_address;
{
    return [self.atlas_dyldInfo atlas_symbolNameForAddress:atlas_address] != nil;
}

- (NSString *)atlas_externalClassNameForAddress2:(NSUInteger)atlas_address;
{
    NSString *atlas_str = [self.atlas_dyldInfo atlas_symbolNameForAddress:atlas_address];

    if (atlas_str != nil) {
        if ([atlas_str hasPrefix:atlas_ObjCClassSymbolPrefix]) {
            return [atlas_str substringFromIndex:[atlas_ObjCClassSymbolPrefix length]];
        } else {
            NSLog(@"Warning: Unknown prefix on symbol name... %@ (addr %lx)", atlas_str, atlas_address);
            return atlas_str;
        }
    }

    return nil;
}

- (BOOL)atlas_hasObjectiveC1Data;
{
    return [self atlas_segmentWithName:@"__OBJC"] != nil;
}

- (BOOL)atlas_hasObjectiveC2Data;
{
    // http://twitter.com/gparker/status/17962955683
    // Oxced: What's the best way to determine the ObjC ABI version of a file?  otool tests if cputype is ARM, but that's not accurate with iOS 4 simulator
    // gparker: @0xced Old ABI has an __OBJC segment. New ABI has a __DATA,__objc_info section.
    // 0xced: @gparker I was hoping for a flag, but that will do it, thanks.
    // 0xced: @gparker Did you mean __DATA,__objc_imageinfo instead of __DATA,__objc_info ?
    // gparker: @0xced Yes, it's __DATA,__objc_imageinfo.
    return [[self atlas_dataConstSegment] atlas_sectionWithName:@"__objc_imageinfo"] != nil;
}

- (Class)atlas_processorClass;
{
    if ([self atlas_hasObjectiveC2Data])
        return [ObjCAtlasObjectiveC2Processor class];
    
    return [ObjCAtlasObjectiveC1Processor class];
}

- (ObjCAtlasLCDylib *)atlas_dylibLoadCommandForLibraryOrdinal:(NSUInteger)atlas_libraryOrdinal;
{
    if (atlas_libraryOrdinal == SELF_LIBRARY_ORDINAL || atlas_libraryOrdinal >= MAX_LIBRARY_ORDINAL)
        return nil;
    
    NSArray *atlas_loadCommands = atlas__dylibLoadCommands;
    if (atlas__dylibIdentifier != nil) {
        // Remove our own ID (LC_ID_DYLIB) so that we calculate the correct offset
        NSMutableArray *atlas_remainingLoadCommands = [atlas_loadCommands mutableCopy];
        [atlas_remainingLoadCommands removeObject:atlas__dylibIdentifier];
        atlas_loadCommands = atlas_remainingLoadCommands;
    }
    
    if (atlas_libraryOrdinal - 1 < [atlas_loadCommands count]) // Ordinals start from 1
        return atlas_loadCommands[atlas_libraryOrdinal - 1];
    else
        return nil;
}

- (NSString *)atlas_architectureNameDescription;
{
    return self.atlas_archName;
}

@end
