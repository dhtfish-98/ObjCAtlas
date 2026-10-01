// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDClassDump.h"

#import "atlas_CDFatArch.h"
#import "atlas_CDFatFile.h"
#import "atlas_CDLCDylib.h"
#import "atlas_CDMachOFile.h"
#import "atlas_CDObjectiveCProcessor.h"
#import "atlas_CDType.h"
#import "atlas_CDTypeFormatter.h"
#import "atlas_CDTypeParser.h"
#import "atlas_CDVisitor.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDTypeController.h"
#import "atlas_CDSearchPathState.h"

NSString *atlas_CDErrorDomain_ClassDump = @"CDErrorDomain_ClassDump";

NSString *atlas_CDErrorKey_Exception    = @"CDErrorKey_Exception";

@interface ObjCAtlasClassDump ()
@end

#pragma mark -

@implementation ObjCAtlasClassDump
{
    ObjCAtlasSearchPathState *atlas__searchPathState;
    
    BOOL atlas__shouldProcessRecursively;
    BOOL atlas__shouldSortClasses; // And categories, protocols
    BOOL atlas__shouldSortClassesByInheritance; // And categories, protocols
    BOOL atlas__shouldSortMethods;
    
    BOOL atlas__shouldShowIvarOffsets;
    BOOL atlas__shouldShowMethodAddresses;
    BOOL atlas__shouldShowHeader;
    
    NSRegularExpression *atlas__regularExpression;
    
    NSString *atlas__sdkRoot;
    NSMutableArray *atlas__machOFiles;
    NSMutableDictionary *atlas__machOFilesByName;
    NSMutableArray *atlas__objcProcessors;
    
    ObjCAtlasTypeController *atlas__typeController;
    
    atlas_CDArch atlas__targetArch;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_searchPathState = atlas__searchPathState;
@synthesize atlas_shouldProcessRecursively = atlas__shouldProcessRecursively;
@synthesize atlas_shouldSortClasses = atlas__shouldSortClasses;
@synthesize atlas_shouldSortClassesByInheritance = atlas__shouldSortClassesByInheritance;
@synthesize atlas_shouldSortMethods = atlas__shouldSortMethods;
@synthesize atlas_shouldShowIvarOffsets = atlas__shouldShowIvarOffsets;
@synthesize atlas_shouldShowMethodAddresses = atlas__shouldShowMethodAddresses;
@synthesize atlas_shouldShowHeader = atlas__shouldShowHeader;
@synthesize regularExpression = atlas__regularExpression;
@synthesize atlas_sdkRoot = atlas__sdkRoot;
@synthesize atlas_machOFiles = atlas__machOFiles;
@synthesize atlas_objcProcessors = atlas__objcProcessors;
@synthesize atlas_targetArch = atlas__targetArch;
@synthesize atlas_typeController = atlas__typeController;

- (id)init;
{
    if ((self = [super init])) {
        atlas__searchPathState = [[ObjCAtlasSearchPathState alloc] init];
        atlas__sdkRoot = nil;
        
        atlas__machOFiles = [[NSMutableArray alloc] init];
        atlas__machOFilesByName = [[NSMutableDictionary alloc] init];
        atlas__objcProcessors = [[NSMutableArray alloc] init];
        
        atlas__typeController = [[ObjCAtlasTypeController alloc] initAtlasWithClassDump:self];
        
        // These can be ppc, ppc7400, ppc64, i386, x86_64
        atlas__targetArch.atlas_cputype = CPU_TYPE_ANY;
        atlas__targetArch.atlas_cpusubtype = 0;
        
        atlas__shouldShowHeader = YES;
    }

    return self;
}

#pragma mark - Regular expression handling

- (BOOL)atlas_shouldShowName:(NSString *)atlas_name;
{
    if (self.regularExpression != nil) {
        NSTextCheckingResult *atlas_firstMatch = [self.regularExpression firstMatchInString:atlas_name options:(NSMatchingOptions)0 range:NSMakeRange(0, [atlas_name length])];
        return atlas_firstMatch != nil;
    }

    return YES;
}

#pragma mark -

- (BOOL)atlas_containsObjectiveCData;
{
    for (ObjCAtlasObjectiveCProcessor *atlas_processor in self.atlas_objcProcessors) {
        if ([atlas_processor atlas_hasObjectiveCData])
            return YES;
    }

    return NO;
}

- (BOOL)atlas_hasEncryptedFiles;
{
    for (ObjCAtlasMachOFile *atlas_machOFile in self.atlas_machOFiles) {
        if ([atlas_machOFile atlas_isEncrypted]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)atlas_hasObjectiveCRuntimeInfo;
{
    return self.atlas_containsObjectiveCData || self.atlas_hasEncryptedFiles;
}

- (BOOL)atlas_loadFile:(ObjCAtlasFile *)atlas_file atlas_error:(NSError *__autoreleasing *)atlas_error;
{
    //NSLog(@"targetArch: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
    ObjCAtlasMachOFile *atlas_machOFile = [atlas_file atlas_machOFileWithArch:atlas__targetArch];
    //NSLog(@"machOFile: %@", machOFile);
    if (atlas_machOFile == nil) {
        if (atlas_error != NULL) {
            NSString *atlas_failureReason;
            NSString *atlas_targetArchName = atlas_CDNameForCPUType(atlas__targetArch.atlas_cputype, atlas__targetArch.atlas_cpusubtype);
            if ([atlas_file isKindOfClass:[ObjCAtlasFatFile class]] && [(ObjCAtlasFatFile *)atlas_file atlas_containsArchitecture:atlas__targetArch]) {
                atlas_failureReason = [NSString stringWithFormat:@"Fat file doesn't contain a valid Mach-O file for the specified architecture (%@).  "
                                                            "It probably means that class-dump was run on a static library, which is not supported.", atlas_targetArchName];
            } else {
                atlas_failureReason = [NSString stringWithFormat:@"File doesn't contain the specified architecture (%@).  Available architectures are %@.", atlas_targetArchName, atlas_file.atlas_architectureNameDescription];
            }
            NSDictionary *atlas_userInfo = @{ NSLocalizedFailureReasonErrorKey : atlas_failureReason };
            *atlas_error = [NSError errorWithDomain:atlas_CDErrorDomain_ClassDump code:0 userInfo:atlas_userInfo];
        }
        return NO;
    }

    // Set before processing recursively.  This was getting caught on CoreUI on 10.6
    assert([atlas_machOFile filename] != nil);
    [atlas__machOFiles addObject:atlas_machOFile];
    atlas__machOFilesByName[atlas_machOFile.filename] = atlas_machOFile;

    if ([self atlas_shouldProcessRecursively]) {
        @try {
            for (ObjCAtlasLoadCommand *atlas_loadCommand in [atlas_machOFile atlas_loadCommands]) {
                if ([atlas_loadCommand isKindOfClass:[ObjCAtlasLCDylib class]]) {
                    ObjCAtlasLCDylib *atlas_dylibCommand = (ObjCAtlasLCDylib *)atlas_loadCommand;
                    if ([atlas_dylibCommand atlas_cmd] == LC_LOAD_DYLIB) {
                        [self.atlas_searchPathState atlas_pushSearchPaths:[atlas_machOFile atlas_runPaths]];
                        {
                            NSString *atlas_loaderPathPrefix = @"@loader_path";
                            
                            NSString *atlas_path = [atlas_dylibCommand path];
                            if ([atlas_path hasPrefix:atlas_loaderPathPrefix]) {
                                NSString *atlas_loaderPath = [atlas_machOFile.filename stringByDeletingLastPathComponent];
                                atlas_path = [[atlas_path stringByReplacingOccurrencesOfString:atlas_loaderPathPrefix withString:atlas_loaderPath] stringByStandardizingPath];
                            }
                            [self atlas_machOFileWithName:atlas_path]; // Loads as a side effect
                        }
                        [self.atlas_searchPathState atlas_popSearchPaths];
                    }
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Caught exception: %@", exception);
            if (atlas_error != NULL) {
                NSDictionary *atlas_userInfo = @{
                NSLocalizedFailureReasonErrorKey : @"Caught exception",
                atlas_CDErrorKey_Exception             : exception,
                };
                *atlas_error = [NSError errorWithDomain:atlas_CDErrorDomain_ClassDump code:0 userInfo:atlas_userInfo];
            }
            return NO;
        }
    }

    return YES;
}

#pragma mark -

- (void)atlas_processObjectiveCData;
{
    for (ObjCAtlasMachOFile *atlas_machOFile in self.atlas_machOFiles) {
        ObjCAtlasObjectiveCProcessor *atlas_processor = [[[atlas_machOFile atlas_processorClass] alloc] initAtlasWithMachOFile:atlas_machOFile];
        [atlas_processor atlas_process];
        [atlas__objcProcessors addObject:atlas_processor];
    }
}

// This visits everything segment processors, classes, categories.  It skips over modules.  Need something to visit modules so we can generate separate headers.
- (void)atlas_recursivelyVisit:(ObjCAtlasVisitor *)atlas_visitor;
{
    [atlas_visitor atlas_willBeginVisiting];

    for (ObjCAtlasObjectiveCProcessor *atlas_processor in self.atlas_objcProcessors) {
        [atlas_processor atlas_recursivelyVisit:atlas_visitor];
    }

    [atlas_visitor atlas_didEndVisiting];
}

- (ObjCAtlasMachOFile *)atlas_machOFileWithName:(NSString *)atlas_name;
{
    NSString *atlas_adjustedName = nil;
    NSString *atlas_executablePathPrefix = @"@executable_path";
    NSString *atlas_rpathPrefix = @"@rpath";

    if ([atlas_name hasPrefix:atlas_executablePathPrefix]) {
        atlas_adjustedName = [atlas_name stringByReplacingOccurrencesOfString:atlas_executablePathPrefix withString:self.atlas_searchPathState.executablePath];
    } else if ([atlas_name hasPrefix:atlas_rpathPrefix]) {
        //NSLog(@"Searching for %@ through run paths: %@", name, [searchPathState searchPaths]);
        for (NSString *atlas_searchPath in [self.atlas_searchPathState atlas_searchPaths]) {
            NSString *atlas_str = [atlas_name stringByReplacingOccurrencesOfString:atlas_rpathPrefix withString:atlas_searchPath];
            //NSLog(@"trying %@", str);
            if ([[NSFileManager defaultManager] fileExistsAtPath:atlas_str]) {
                atlas_adjustedName = atlas_str;
                //NSLog(@"Found it!");
                break;
            }
        }
        if (atlas_adjustedName == nil) {
            atlas_adjustedName = atlas_name;
            //NSLog(@"Did not find it.");
        }
    } else if (self.atlas_sdkRoot != nil) {
        atlas_adjustedName = [self.atlas_sdkRoot stringByAppendingPathComponent:atlas_name];
    } else {
        atlas_adjustedName = atlas_name;
    }

    ObjCAtlasMachOFile *atlas_machOFile = atlas__machOFilesByName[atlas_adjustedName];
    if (atlas_machOFile == nil) {
        ObjCAtlasFile *atlas_file = [ObjCAtlasFile atlas_fileWithContentsOfFile:atlas_adjustedName atlas_searchPathState:self.atlas_searchPathState];

        if (atlas_file == nil || [self atlas_loadFile:atlas_file atlas_error:NULL] == NO)
            NSLog(@"Warning: Failed to load: %@", atlas_adjustedName);

        atlas_machOFile = atlas__machOFilesByName[atlas_adjustedName];
        if (atlas_machOFile == nil) {
            NSLog(@"Warning: Couldn't load MachOFile with ID: %@, adjustedID: %@", atlas_name, atlas_adjustedName);
        }
    }

    return atlas_machOFile;
}

- (void)atlas_appendHeaderToString:(NSMutableString *)atlas_resultString;
{
    // Since this changes each version, for regression testing it'll be better to be able to not show it.
    if (self.atlas_shouldShowHeader == NO)
        return;

    [atlas_resultString appendString:@"//\n"];
    [atlas_resultString appendFormat:@"//     Generated by class-dump %s.\n", atlas_CLASS_DUMP_VERSION];
    [atlas_resultString appendString:@"//\n"];
    [atlas_resultString appendString:@"//  Copyright (C) 1997-2019 Steve Nygard.\n"];
    [atlas_resultString appendString:@"//\n\n"];

    if (self.atlas_sdkRoot != nil) {
        [atlas_resultString appendString:@"//\n"];
        [atlas_resultString appendFormat:@"// SDK Root: %@\n", self.atlas_sdkRoot];
        [atlas_resultString appendString:@"//\n\n"];
    }
}

- (void)atlas_registerTypes;
{
    for (ObjCAtlasObjectiveCProcessor *atlas_processor in self.atlas_objcProcessors) {
        [atlas_processor atlas_registerTypesWithObject:self.atlas_typeController atlas_phase:0];
    }
    [self.atlas_typeController atlas_endPhase:0];

    [self.atlas_typeController atlas_workSomeMagic];
}

- (void)atlas_showHeader;
{
    if ([self.atlas_machOFiles count] > 0) {
        [[[self.atlas_machOFiles lastObject] atlas_headerString:YES] atlas_print];
    }
}

- (void)atlas_showLoadCommands;
{
    if ([self.atlas_machOFiles count] > 0) {
        [[[self.atlas_machOFiles lastObject] atlas_loadCommandString:YES] atlas_print];
    }
}

@end
