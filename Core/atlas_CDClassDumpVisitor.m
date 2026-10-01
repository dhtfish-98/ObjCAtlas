// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDClassDumpVisitor.h"

#include <mach-o/arch.h>

#import "atlas_CDClassDump.h"
#import "atlas_CDObjectiveCProcessor.h"
#import "atlas_CDMachOFile.h"
#import "atlas_CDLCBuildVersion.h"
#import "atlas_CDLCDylib.h"
#import "atlas_CDLCDylinker.h"
#import "atlas_CDLCEncryptionInfo.h"
#import "atlas_CDLCRunPath.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDLCSourceVersion.h"
#import "atlas_CDLCVersionMinimum.h"
#import "atlas_CDTypeController.h"

@implementation ObjCAtlasClassDumpVisitor
{
}

- (void)atlas_willBeginVisiting;
{
    [super atlas_willBeginVisiting];

    [self.atlas_classDump atlas_appendHeaderToString:self.atlas_resultString];

    if (self.atlas_classDump.atlas_hasObjectiveCRuntimeInfo && self.atlas_shouldShowStructureSection) {
        [self.atlas_classDump.atlas_typeController atlas_appendStructuresToString:self.atlas_resultString];
    }
}

- (void)atlas_didEndVisiting;
{
    [super atlas_didEndVisiting];

    [self atlas_writeResultToStandardOutput];
}

- (void)atlas_visitObjectiveCProcessor:(ObjCAtlasObjectiveCProcessor *)atlas_processor;
{
    ObjCAtlasMachOFile *atlas_machOFile = atlas_processor.atlas_machOFile;

    [self.atlas_resultString appendString:@"#pragma mark -\n\n"];
    [self.atlas_resultString appendString:@"//\n"];
    [self.atlas_resultString appendFormat:@"// File: %@\n", atlas_machOFile.filename];
    if (atlas_machOFile.UUID != nil) {
        [self.atlas_resultString appendFormat:@"// UUID: %@\n", [atlas_machOFile.UUID UUIDString]];
    }
    [self.atlas_resultString appendString:@"//\n"];
    [self.atlas_resultString appendFormat:@"//                           Arch: %@\n", atlas_CDNameForCPUType(atlas_machOFile.atlas_cputype, atlas_machOFile.atlas_cpusubtype)];

    if (atlas_machOFile.atlas_filetype == MH_DYLIB) {
        ObjCAtlasLCDylib *atlas_identifier = atlas_machOFile.atlas_dylibIdentifier;
        if (atlas_identifier != nil) {
            [self.atlas_resultString appendFormat:@"//                Current version: %@\n", atlas_identifier.atlas_formattedCurrentVersion];
            [self.atlas_resultString appendFormat:@"//          Compatibility version: %@\n", atlas_identifier.atlas_formattedCompatibilityVersion];
        }
    }
    
    if (atlas_machOFile.atlas_sourceVersion != nil)
        [self.atlas_resultString appendFormat:@"//                 Source version: %@\n", atlas_machOFile.atlas_sourceVersion.atlas_sourceVersionString];
    if (atlas_machOFile.atlas_buildVersion != nil) {
        [self.atlas_resultString appendFormat:@"//                  Build version: %@\n", atlas_machOFile.atlas_buildVersion.atlas_buildVersionString];
        [self.atlas_resultString appendFormat:@"//                          Tools: %@\n", [atlas_machOFile.atlas_buildVersion.atlas_toolStrings componentsJoinedByString:@"\n                                   "]];
    }

    if (atlas_machOFile.atlas_minVersionMacOSX != nil) {
        [self.atlas_resultString appendFormat:@"//       Minimum Mac OS X version: %@\n", atlas_machOFile.atlas_minVersionMacOSX.atlas_minimumVersionString];
        [self.atlas_resultString appendFormat:@"//                    SDK version: %@\n", atlas_machOFile.atlas_minVersionMacOSX.atlas_SDKVersionString];
    }
    if (atlas_machOFile.atlas_minVersionIOS != nil) {
        [self.atlas_resultString appendFormat:@"//            Minimum iOS version: %@\n", atlas_machOFile.atlas_minVersionIOS.atlas_minimumVersionString];
        [self.atlas_resultString appendFormat:@"//                    SDK version: %@\n", atlas_machOFile.atlas_minVersionIOS.atlas_SDKVersionString];
    }

    if (atlas_processor.atlas_garbageCollectionStatus != nil) {
        [self.atlas_resultString appendString:@"//\n"];
        [self.atlas_resultString appendFormat:@"// Objective-C Garbage Collection: %@\n", atlas_processor.atlas_garbageCollectionStatus];
    }

    [atlas_machOFile.atlas_dyldEnvironment enumerateObjectsUsingBlock:^(ObjCAtlasLCDylinker *atlas_env, NSUInteger atlas_index, BOOL *atlas_stop){
        if (atlas_index == 0) {
            [self.atlas_resultString appendString:@"//\n"];
            [self.atlas_resultString appendFormat:@"//               dyld environment: %@\n", atlas_env.name];
        } else {
            [self.atlas_resultString appendFormat:@"//                                 %@\n", atlas_env.name];
        }
    }];

    if ([atlas_machOFile.atlas_runPathCommands count] > 0) {
        [self.atlas_resultString appendString:@"//\n"];
        for (ObjCAtlasLCRunPath *atlas_runPath in atlas_machOFile.atlas_runPathCommands) {
                [self.atlas_resultString appendFormat:@"//                       Run path: %@\n", atlas_runPath.path];
                [self.atlas_resultString appendFormat:@"//                               = %@\n", atlas_runPath.atlas_resolvedRunPath];
        }
    }

    if (atlas_machOFile.atlas_isEncrypted) {
        [self.atlas_resultString appendString:@"//         This file is encrypted:\n"];
        for (ObjCAtlasLoadCommand *atlas_loadCommand in atlas_machOFile.atlas_loadCommands) {
            if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCEncryptionInfo class]]) {
                ObjCAtlasLCEncryptionInfo *atlas_encryptionInfo = (ObjCAtlasLCEncryptionInfo *)atlas_loadCommand;

                [self.atlas_resultString appendFormat:@"//                                   cryptid: 0x%08x\n", atlas_encryptionInfo.atlas_cryptid];
                [self.atlas_resultString appendFormat:@"//                                  cryptoff: 0x%08x\n", atlas_encryptionInfo.atlas_cryptoff];
                [self.atlas_resultString appendFormat:@"//                                 cryptsize: 0x%08x\n", atlas_encryptionInfo.atlas_cryptsize];
            }
        }
    } else if (atlas_machOFile.atlas_hasProtectedSegments) {
        if (atlas_machOFile.atlas_canDecryptAllSegments) {
            [self.atlas_resultString appendString:@"//\n"];
            [self.atlas_resultString appendString:@"//     This file has protected segments, decrypting.\n"];
        } else {
            [self.atlas_resultString appendString:@"//\n"];
            [self.atlas_resultString appendString:@"//     This file has protected segments that can't be decrypted:\n"];
            [atlas_machOFile.atlas_loadCommands enumerateObjectsUsingBlock:^(ObjCAtlasLoadCommand *atlas_loadCommand, NSUInteger atlas_index, BOOL *atlas_stop){
                if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCSegment class]]) {
                    ObjCAtlasLCSegment *atlas_segment = (ObjCAtlasLCSegment *)atlas_loadCommand;
                    
                    if (atlas_segment.atlas_canDecrypt == NO) {
                        [self.atlas_resultString appendFormat:@"//         Load command %lu, segment encryption: %@\n",
                         atlas_index, atlas_CDSegmentEncryptionTypeName(atlas_segment.atlas_encryptionType)];
                    }
                }
            }];
        }
    }
    [self.atlas_resultString appendString:@"//\n\n"];
    
    if (!self.atlas_classDump.atlas_hasObjectiveCRuntimeInfo) {
        [self.atlas_resultString appendString:@"//\n"];
        [self.atlas_resultString appendString:@"// This file does not contain any Objective-C runtime information.\n"];
        [self.atlas_resultString appendString:@"//\n"];
    }
}

@end
