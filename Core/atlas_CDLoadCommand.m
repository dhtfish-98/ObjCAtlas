// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLoadCommand.h"

#import "atlas_CDLCBuildVersion.h"
#import "atlas_CDLCDyldInfo.h"
#import "atlas_CDLCDylib.h"
#import "atlas_CDLCDylinker.h"
#import "atlas_CDLCDynamicSymbolTable.h"
#import "atlas_CDLCEncryptionInfo.h"
#import "atlas_CDLCFunctionStarts.h"
#import "atlas_CDLCLinkeditData.h"
#import "atlas_CDLCPrebindChecksum.h"
#import "atlas_CDLCPreboundDylib.h"
#import "atlas_CDLCRoutines32.h"
#import "atlas_CDLCRoutines64.h"
#import "atlas_CDLCRunPath.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDLCSubClient.h"
#import "atlas_CDLCSubFramework.h"
#import "atlas_CDLCSubLibrary.h"
#import "atlas_CDLCSubUmbrella.h"
#import "atlas_CDLCSymbolTable.h"
#import "atlas_CDLCTwoLevelHints.h"
#import "atlas_CDLCUnixThread.h"
#import "atlas_CDLCUUID.h"
#import "atlas_CDLCUnknown.h"
#import "atlas_CDLCVersionMinimum.h"
#import "atlas_CDMachOFile.h"

#import "atlas_CDLCMain.h"
#import "atlas_CDLCDataInCode.h"
#import "atlas_CDLCSourceVersion.h"

@implementation ObjCAtlasLoadCommand
{
    __weak ObjCAtlasMachOFile *atlas__machOFile;
    NSUInteger atlas__commandOffset;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_machOFile = atlas__machOFile;
@synthesize atlas_commandOffset = atlas__commandOffset;

+ (id)atlas_loadCommandWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    Class atlas_targetClass = [ObjCAtlasLCUnknown class];

    uint32_t atlas_val = [atlas_cursor atlas_peekInt32];

    switch (atlas_val) {
        case LC_SEGMENT:               atlas_targetClass = [ObjCAtlasLCSegment class]; break;
        case LC_SEGMENT_64:            atlas_targetClass = [ObjCAtlasLCSegment class]; break;
        case LC_SYMTAB:                atlas_targetClass = [ObjCAtlasLCSymbolTable class]; break;
            //case LC_SYMSEG: // obsolete
            //case LC_THREAD: // not used?
        case LC_UNIXTHREAD:            atlas_targetClass = [ObjCAtlasLCUnixThread class]; break;
            //case LC_LOADFVMLIB: // not used?
            //case LC_IDFVMLIB: // not used?
            //case LC_IDENT: // not used?
            //case LC_FVMFILE: // not used?
            //case LC_PREPAGE: // not used
        case LC_DYSYMTAB:              atlas_targetClass = [ObjCAtlasLCDynamicSymbolTable class]; break;
        case LC_LOAD_DYLIB:            atlas_targetClass = [ObjCAtlasLCDylib class]; break;
        case LC_ID_DYLIB:              atlas_targetClass = [ObjCAtlasLCDylib class]; break;
        case LC_LOAD_DYLINKER:         atlas_targetClass = [ObjCAtlasLCDylinker class]; break;
        case LC_ID_DYLINKER:           atlas_targetClass = [ObjCAtlasLCDylinker class]; break;
        case LC_PREBOUND_DYLIB:        atlas_targetClass = [ObjCAtlasLCPreboundDylib class]; break;
        case LC_ROUTINES:              atlas_targetClass = [ObjCAtlasLCRoutines32 class]; break;
        case LC_SUB_FRAMEWORK:         atlas_targetClass = [ObjCAtlasLCSubFramework class]; break;
            //case LC_SUB_UMBRELLA:    targetClass = [CDLCSubUmbrella class]; break;
        case LC_SUB_CLIENT:            atlas_targetClass = [ObjCAtlasLCSubClient class]; break;
            //case LC_SUB_LIBRARY:     targetClass = [CDLCSubLibrary class]; break;
        case LC_TWOLEVEL_HINTS:        atlas_targetClass = [ObjCAtlasLCTwoLevelHints class]; break;
        case LC_PREBIND_CKSUM:         atlas_targetClass = [ObjCAtlasLCPrebindChecksum class]; break;
        case LC_LOAD_WEAK_DYLIB:       atlas_targetClass = [ObjCAtlasLCDylib class]; break;
        case LC_ROUTINES_64:           atlas_targetClass = [ObjCAtlasLCRoutines64 class]; break;
        case LC_UUID:                  atlas_targetClass = [ObjCAtlasLCUUID class]; break;
        case LC_RPATH:                 atlas_targetClass = [ObjCAtlasLCRunPath class]; break;
        case LC_CODE_SIGNATURE:        atlas_targetClass = [ObjCAtlasLCLinkeditData class]; break;
        case LC_SEGMENT_SPLIT_INFO:    atlas_targetClass = [ObjCAtlasLCLinkeditData class]; break;
        case LC_REEXPORT_DYLIB:        atlas_targetClass = [ObjCAtlasLCDylib class]; break;
        case LC_LAZY_LOAD_DYLIB:       atlas_targetClass = [ObjCAtlasLCDylib class]; break;
        case LC_ENCRYPTION_INFO:
        case LC_ENCRYPTION_INFO_64:    atlas_targetClass = [ObjCAtlasLCEncryptionInfo class]; break;
        case LC_DYLD_INFO:             atlas_targetClass = [ObjCAtlasLCDyldInfo class]; break;
        case LC_DYLD_INFO_ONLY:        atlas_targetClass = [ObjCAtlasLCDyldInfo class]; break;

        case LC_LOAD_UPWARD_DYLIB:     atlas_targetClass = [ObjCAtlasLCDylib class]; break;
        case LC_VERSION_MIN_MACOSX:    atlas_targetClass = [ObjCAtlasLCVersionMinimum class]; break;
        case LC_VERSION_MIN_IPHONEOS:  atlas_targetClass = [ObjCAtlasLCVersionMinimum class]; break;
        case LC_FUNCTION_STARTS:       atlas_targetClass = [ObjCAtlasLCFunctionStarts class]; break;
        case LC_DYLD_ENVIRONMENT:      atlas_targetClass = [ObjCAtlasLCDylinker class]; break;
        case LC_MAIN:                  atlas_targetClass = [ObjCAtlasLCMain class]; break;
        case LC_DATA_IN_CODE:          atlas_targetClass = [ObjCAtlasLCDataInCode class]; break;
        case LC_SOURCE_VERSION:        atlas_targetClass = [ObjCAtlasLCSourceVersion class]; break;
        case LC_DYLIB_CODE_SIGN_DRS:   atlas_targetClass = [ObjCAtlasLCLinkeditData class]; break; // Designated Requirements

        case LC_BUILD_VERSION:         atlas_targetClass = [ObjCAtlasLCBuildVersion class]; break;

        case LC_LINKER_OPTION:
        case LC_LINKER_OPTIMIZATION_HINT:
        case LC_VERSION_MIN_TVOS:
        case LC_VERSION_MIN_WATCHOS:
        case LC_NOTE:

        default:
            NSLog(@"Unknown load command: 0x%08x", atlas_val);
    };

    //NSLog(@"targetClass: %@", NSStringFromClass(targetClass));

    return [[atlas_targetClass alloc] initAtlasWithDataCursor:atlas_cursor];
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super init])) {
        atlas__machOFile = [atlas_cursor atlas_machOFile];
        atlas__commandOffset = [atlas_cursor atlas_offset];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> cmd: 0x%08x (%@), cmdsize: %d // %@",
            NSStringFromClass([self class]), self,
            self.atlas_cmd, self.commandName, self.atlas_cmdsize, [self atlas_extraDescription]];
}

- (NSString *)atlas_extraDescription;
{
    return @"";
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    // Implement in subclasses
    [NSException raise:NSGenericException format:@"Must implement method in subclasses."];
    return 0;
}

- (uint32_t)atlas_cmdsize;
{
    // Implement in subclasses
    [NSException raise:NSGenericException format:@"Must implement method in subclasses."];
    return 0;
}

- (BOOL)atlas_mustUnderstandToExecute;
{
    return (self.atlas_cmd & LC_REQ_DYLD) != 0;
}

- (NSString *)commandName;
{
    switch (self.atlas_cmd) {
        case LC_SEGMENT:               return @"LC_SEGMENT";
        case LC_SYMTAB:                return @"LC_SYMTAB";
        case LC_SYMSEG:                return @"LC_SYMSEG";
        case LC_THREAD:                return @"LC_THREAD";
        case LC_UNIXTHREAD:            return @"LC_UNIXTHREAD";
        case LC_LOADFVMLIB:            return @"LC_LOADFVMLIB";
        case LC_IDFVMLIB:              return @"LC_IDFVMLIB";
        case LC_IDENT:                 return @"LC_IDENT";
        case LC_FVMFILE:               return @"LC_FVMFILE";
        case LC_PREPAGE:               return @"LC_PREPAGE";
        case LC_DYSYMTAB:              return @"LC_DYSYMTAB";
        case LC_LOAD_DYLIB:            return @"LC_LOAD_DYLIB";
        case LC_ID_DYLIB:              return @"LC_ID_DYLIB";
        case LC_LOAD_DYLINKER:         return @"LC_LOAD_DYLINKER";
        case LC_ID_DYLINKER:           return @"LC_ID_DYLINKER";
        case LC_PREBOUND_DYLIB:        return @"LC_PREBOUND_DYLIB";
        case LC_ROUTINES:              return @"LC_ROUTINES";
        case LC_SUB_FRAMEWORK:         return @"LC_SUB_FRAMEWORK";
        case LC_SUB_UMBRELLA:          return @"LC_SUB_UMBRELLA";
        case LC_SUB_CLIENT:            return @"LC_SUB_CLIENT";
        case LC_SUB_LIBRARY:           return @"LC_SUB_LIBRARY";
        case LC_TWOLEVEL_HINTS:        return @"LC_TWOLEVEL_HINTS";
        case LC_PREBIND_CKSUM:         return @"LC_PREBIND_CKSUM";
            
        case LC_LOAD_WEAK_DYLIB:       return @"LC_LOAD_WEAK_DYLIB";
        case LC_SEGMENT_64:            return @"LC_SEGMENT_64";
        case LC_ROUTINES_64:           return @"LC_ROUTINES_64";
        case LC_UUID:                  return @"LC_UUID";
        case LC_RPATH:                 return @"LC_RPATH";
        case LC_CODE_SIGNATURE:        return @"LC_CODE_SIGNATURE";
        case LC_SEGMENT_SPLIT_INFO:    return @"LC_SEGMENT_SPLIT_INFO";
        case LC_REEXPORT_DYLIB:        return @"LC_REEXPORT_DYLIB";
        case LC_LAZY_LOAD_DYLIB:       return @"LC_LAZY_LOAD_DYLIB";
        case LC_ENCRYPTION_INFO:       return @"LC_ENCRYPTION_INFO";
        case LC_DYLD_INFO:             return @"LC_DYLD_INFO";
        case LC_DYLD_INFO_ONLY:        return @"LC_DYLD_INFO_ONLY";
        case LC_LOAD_UPWARD_DYLIB:     return @"LC_LOAD_UPWARD_DYLIB";
        case LC_VERSION_MIN_MACOSX:    return @"LC_VERSION_MIN_MACOSX";
        case LC_VERSION_MIN_IPHONEOS:  return @"LC_VERSION_MIN_IPHONEOS";
        case LC_FUNCTION_STARTS:       return @"LC_FUNCTION_STARTS";
        case LC_DYLD_ENVIRONMENT:      return @"LC_DYLD_ENVIRONMENT";

        case LC_LINKER_OPTION:            return @"LC_LINKER_OPTION";
        case LC_LINKER_OPTIMIZATION_HINT: return @"LC_LINKER_OPTIMIZATION_HINT";
        case LC_VERSION_MIN_TVOS:         return @"LC_VERSION_MIN_TVOS";
        case LC_VERSION_MIN_WATCHOS:      return @"LC_VERSION_MIN_WATCHOS";
        case LC_NOTE:                     return @"LC_NOTE";
        case LC_BUILD_VERSION:            return @"LC_BUILD_VERSION";

        default:
            break;
    }

    return [NSString stringWithFormat:@"0x%08x", [self atlas_cmd]];
}

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_verbose:(BOOL)atlas_isVerbose;
{
    [atlas_resultString appendFormat:@"     cmd %@", [self commandName]];
    if (self.atlas_mustUnderstandToExecute)
        [atlas_resultString appendFormat:@" (must understand to execute)"];
    [atlas_resultString appendFormat:@"\n"];
    [atlas_resultString appendFormat:@" cmdsize %u\n", [self atlas_cmdsize]];
}

- (void)atlas_machOFileDidReadLoadCommands:(ObjCAtlasMachOFile *)atlas_machOFile;
{
}

@end
