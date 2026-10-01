// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#include <stdio.h>
#include <libc.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include <mach-o/arch.h>

#import "atlas_CDClassDump.h"
#import "atlas_CDFindMethodVisitor.h"
#import "atlas_CDClassDumpVisitor.h"
#import "atlas_CDMultiFileVisitor.h"
#import "atlas_CDFile.h"
#import "atlas_CDMachOFile.h"
#import "atlas_CDFatFile.h"
#import "atlas_CDFatArch.h"
#import "atlas_CDSearchPathState.h"

void atlas_print_usage(void)
{
    fprintf(stderr,
            "ObjCAtlas %s\n"
            "Usage: class-dump [options] <mach-o-file>\n"
            "\n"
            "  where options are:\n"
            "        -a             show instance variable offsets\n"
            "        -A             show implementation addresses\n"
            "        --arch <arch>  choose a specific architecture from a universal binary (ppc, ppc64, i386, x86_64, armv6, armv7, armv7s, arm64)\n"
            "        -C <regex>     only display classes matching regular expression\n"
            "        -f <str>       find string in method name\n"
            "        -H             generate header files in current directory, or directory specified with -o\n"
            "        -I             sort classes, categories, and protocols by inheritance (overrides -s)\n"
            "        -o <dir>       output directory used for -H\n"
            "        -r             recursively expand frameworks and fixed VM shared libraries\n"
            "        -s             sort classes and categories by name\n"
            "        -S             sort methods by name\n"
            "        -t             suppress header in output, for testing\n"
            "        --list-arches  list the arches in the file, then exit\n"
            "        --sdk-ios      specify iOS SDK version (will look for /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS<version>.sdk\n"
            "                       or /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS<version>.sdk)\n"
            "        --sdk-mac      specify Mac OS X version (will look for /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX<version>.sdk\n"
            "                       or /Developer/SDKs/MacOSX<version>.sdk)\n"
            "        --sdk-root     specify the full SDK root path (or use --sdk-ios/--sdk-mac for a shortcut)\n"
            ,
            atlas_CLASS_DUMP_VERSION
       );
}

#define atlas_CD_OPT_ARCH        1
#define atlas_CD_OPT_LIST_ARCHES 2
#define atlas_CD_OPT_VERSION     3
#define atlas_CD_OPT_SDK_IOS     4
#define atlas_CD_OPT_SDK_MAC     5
#define atlas_CD_OPT_SDK_ROOT    6
#define atlas_CD_OPT_HIDE        7

int main(int atlas_argc, char *atlas_argv[])
{
    @autoreleasepool {
        NSString *atlas_searchString;
        BOOL atlas_shouldGenerateSeparateHeaders = NO;
        BOOL atlas_shouldListArches = NO;
        BOOL atlas_shouldPrintVersion = NO;
        atlas_CDArch atlas_targetArch;
        BOOL atlas_hasSpecifiedArch = NO;
        NSString *atlas_outputPath;
        NSMutableSet *atlas_hiddenSections = [NSMutableSet set];

        int atlas_ch;
        BOOL atlas_errorFlag = NO;

        struct option atlas_longopts[] = {
            { "show-ivar-offsets",       no_argument,       NULL, 'a' },
            { "show-imp-addr",           no_argument,       NULL, 'A' },
            { "match",                   required_argument, NULL, 'C' },
            { "find",                    required_argument, NULL, 'f' },
            { "generate-multiple-files", no_argument,       NULL, 'H' },
            { "sort-by-inheritance",     no_argument,       NULL, 'I' },
            { "output-dir",              required_argument, NULL, 'o' },
            { "recursive",               no_argument,       NULL, 'r' },
            { "sort",                    no_argument,       NULL, 's' },
            { "sort-methods",            no_argument,       NULL, 'S' },
            { "arch",                    required_argument, NULL, atlas_CD_OPT_ARCH },
            { "list-arches",             no_argument,       NULL, atlas_CD_OPT_LIST_ARCHES },
            { "suppress-header",         no_argument,       NULL, 't' },
            { "version",                 no_argument,       NULL, atlas_CD_OPT_VERSION },
            { "sdk-ios",                 required_argument, NULL, atlas_CD_OPT_SDK_IOS },
            { "sdk-mac",                 required_argument, NULL, atlas_CD_OPT_SDK_MAC },
            { "sdk-root",                required_argument, NULL, atlas_CD_OPT_SDK_ROOT },
            { "hide",                    required_argument, NULL, atlas_CD_OPT_HIDE },
            { NULL,                      0,                 NULL, 0 },
        };

        if (atlas_argc == 1) {
            atlas_print_usage();
            exit(0);
        }

        ObjCAtlasClassDump *atlas_classDump = [[ObjCAtlasClassDump alloc] init];

        while ( (atlas_ch = getopt_long(atlas_argc, atlas_argv, "aAC:f:HIo:rRsSt", atlas_longopts, NULL)) != -1) {
            switch (atlas_ch) {
                case atlas_CD_OPT_ARCH: {
                    NSString *atlas_name = [NSString stringWithUTF8String:optarg];
                    atlas_targetArch = atlas_CDArchFromName(atlas_name);
                    if (atlas_targetArch.atlas_cputype != CPU_TYPE_ANY)
                        atlas_hasSpecifiedArch = YES;
                    else {
                        fprintf(stderr, "Error: Unknown arch %s\n\n", optarg);
                        atlas_errorFlag = YES;
                    }
                    break;
                }
                    
                case atlas_CD_OPT_LIST_ARCHES:
                    atlas_shouldListArches = YES;
                    break;
                    
                case atlas_CD_OPT_VERSION:
                    atlas_shouldPrintVersion = YES;
                    break;
                    
                case atlas_CD_OPT_SDK_IOS: {
                    NSString *atlas_root = [NSString stringWithUTF8String:optarg];
                    //NSLog(@"root: %@", root);
                    NSString *atlas_str;
                    if ([[NSFileManager defaultManager] fileExistsAtPath: @"/Applications/Xcode.app"]) {
                        atlas_str = [NSString stringWithFormat:@"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS%@.sdk", atlas_root];
                    } else if ([[NSFileManager defaultManager] fileExistsAtPath: @"/Developer"]) {
                        atlas_str = [NSString stringWithFormat:@"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS%@.sdk", atlas_root];
                    }
                    atlas_classDump.atlas_sdkRoot = atlas_str;
                    
                    break;
                }
                    
                case atlas_CD_OPT_SDK_MAC: {
                    NSString *atlas_root = [NSString stringWithUTF8String:optarg];
                    //NSLog(@"root: %@", root);
                    NSString *atlas_str;
                    if ([[NSFileManager defaultManager] fileExistsAtPath: @"/Applications/Xcode.app"]) {
                        atlas_str = [NSString stringWithFormat:@"/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX%@.sdk", atlas_root];
                    } else if ([[NSFileManager defaultManager] fileExistsAtPath: @"/Developer"]) {
                        atlas_str = [NSString stringWithFormat:@"/Developer/SDKs/MacOSX%@.sdk", atlas_root];
                    }
                    atlas_classDump.atlas_sdkRoot = atlas_str;
                    
                    break;
                }
                    
                case atlas_CD_OPT_SDK_ROOT: {
                    NSString *atlas_root = [NSString stringWithUTF8String:optarg];
                    //NSLog(@"root: %@", root);
                    atlas_classDump.atlas_sdkRoot = atlas_root;
                    
                    break;
                }
                    
                case atlas_CD_OPT_HIDE: {
                    NSString *atlas_str = [NSString stringWithUTF8String:optarg];
                    if ([atlas_str isEqualToString:@"all"]) {
                        [atlas_hiddenSections addObject:@"structures"];
                        [atlas_hiddenSections addObject:@"protocols"];
                    } else {
                        [atlas_hiddenSections addObject:atlas_str];
                    }
                    break;
                }
                    
                case 'a':
                    atlas_classDump.atlas_shouldShowIvarOffsets = YES;
                    break;
                    
                case 'A':
                    atlas_classDump.atlas_shouldShowMethodAddresses = YES;
                    break;
                    
                case 'C': {
                    NSError *atlas_error;
                    NSRegularExpression *atlas_regularExpression = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithUTF8String:optarg]
                                                                                                       options:(NSRegularExpressionOptions)0
                                                                                                         error:&atlas_error];
                    if (atlas_regularExpression != nil) {
                        atlas_classDump.regularExpression = atlas_regularExpression;
                    } else {
                        fprintf(stderr, "ObjCAtlas: Error with regular expression: %s\n\n", [[atlas_error localizedFailureReason] UTF8String]);
                        atlas_errorFlag = YES;
                    }

                    // Last one wins now.
                    break;
                }
                    
                case 'f': {
                    atlas_searchString = [NSString stringWithUTF8String:optarg];
                    break;
                }
                    
                case 'H':
                    atlas_shouldGenerateSeparateHeaders = YES;
                    break;
                    
                case 'I':
                    atlas_classDump.atlas_shouldSortClassesByInheritance = YES;
                    break;
                    
                case 'o':
                    atlas_outputPath = [NSString stringWithUTF8String:optarg];
                    break;
                    
                case 'r':
                    atlas_classDump.atlas_shouldProcessRecursively = YES;
                    break;
                    
                case 's':
                    atlas_classDump.atlas_shouldSortClasses = YES;
                    break;
                    
                case 'S':
                    atlas_classDump.atlas_shouldSortMethods = YES;
                    break;
                    
                case 't':
                    atlas_classDump.atlas_shouldShowHeader = NO;
                    break;
                    
                case '?':
                default:
                    atlas_errorFlag = YES;
                    break;
            }
        }

        if (atlas_errorFlag) {
            atlas_print_usage();
            exit(2);
        }

        if (atlas_shouldPrintVersion) {
            printf("ObjCAtlas %s compiled %s\n", atlas_CLASS_DUMP_VERSION, __DATE__ " " __TIME__);
            exit(0);
        }

        if (optind < atlas_argc) {
            NSString *atlas_arg = [NSString atlas_stringWithFileSystemRepresentation:atlas_argv[optind]];
            NSString *atlas_executablePath = [atlas_arg atlas_executablePathForFilename];
            if (atlas_shouldListArches) {
                if (atlas_executablePath == nil) {
                    printf("none\n");
                } else {
                    ObjCAtlasSearchPathState *atlas_searchPathState = [[ObjCAtlasSearchPathState alloc] init];
                    atlas_searchPathState.executablePath = atlas_executablePath;
                    id atlas_macho = [ObjCAtlasFile atlas_fileWithContentsOfFile:atlas_executablePath atlas_searchPathState:atlas_searchPathState];
                    if (atlas_macho == nil) {
                        printf("none\n");
                    } else {
                        if ([atlas_macho isKindOfClass:[ObjCAtlasMachOFile class]]) {
                            printf("%s\n", [[atlas_macho atlas_archName] UTF8String]);
                        } else if ([atlas_macho isKindOfClass:[ObjCAtlasFatFile class]]) {
                            printf("%s\n", [[[atlas_macho atlas_archNames] componentsJoinedByString:@" "] UTF8String]);
                        }
                    }
                }
            } else {
                if (atlas_executablePath == nil) {
                    fprintf(stderr, "ObjCAtlas: Input file (%s) doesn't contain an executable.\n", [atlas_arg fileSystemRepresentation]);
                    exit(1);
                }

                atlas_classDump.atlas_searchPathState.executablePath = [atlas_executablePath stringByDeletingLastPathComponent];
                ObjCAtlasFile *atlas_file = [ObjCAtlasFile atlas_fileWithContentsOfFile:atlas_executablePath atlas_searchPathState:atlas_classDump.atlas_searchPathState];
                if (atlas_file == nil) {
                    NSFileManager *atlas_defaultManager = [NSFileManager defaultManager];
                    
                    if ([atlas_defaultManager fileExistsAtPath:atlas_executablePath]) {
                        if ([atlas_defaultManager isReadableFileAtPath:atlas_executablePath]) {
                            fprintf(stderr, "ObjCAtlas: Input file (%s) is neither a Mach-O file nor a fat archive.\n", [atlas_executablePath UTF8String]);
                        } else {
                            fprintf(stderr, "ObjCAtlas: Input file (%s) is not readable (check read permissions).\n", [atlas_executablePath UTF8String]);
                        }
                    } else {
                        fprintf(stderr, "ObjCAtlas: Input file (%s) does not exist.\n", [atlas_executablePath UTF8String]);
                    }

                    exit(1);
                }

                if (atlas_hasSpecifiedArch == NO) {
                    if ([atlas_file atlas_bestMatchForLocalArch:&atlas_targetArch] == NO) {
                        fprintf(stderr, "Error: Couldn't get local architecture\n");
                        exit(1);
                    }
                    //NSLog(@"No arch specified, best match for local arch is: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
                } else {
                    //NSLog(@"chosen arch is: (%08x, %08x)", targetArch.cputype, targetArch.cpusubtype);
                }

                atlas_classDump.atlas_targetArch = atlas_targetArch;
                atlas_classDump.atlas_searchPathState.executablePath = [atlas_executablePath stringByDeletingLastPathComponent];

                NSError *atlas_error;
                if (![atlas_classDump atlas_loadFile:atlas_file atlas_error:&atlas_error]) {
                    fprintf(stderr, "Error: %s\n", [[atlas_error localizedFailureReason] UTF8String]);
                    exit(1);
                } else {
                    [atlas_classDump atlas_processObjectiveCData];
                    [atlas_classDump atlas_registerTypes];
                    
                    if (atlas_searchString != nil) {
                        ObjCAtlasFindMethodVisitor *atlas_visitor = [[ObjCAtlasFindMethodVisitor alloc] init];
                        atlas_visitor.atlas_classDump = atlas_classDump;
                        atlas_visitor.atlas_searchString = atlas_searchString;
                        [atlas_classDump atlas_recursivelyVisit:atlas_visitor];
                    } else if (atlas_shouldGenerateSeparateHeaders) {
                        ObjCAtlasMultiFileVisitor *atlas_multiFileVisitor = [[ObjCAtlasMultiFileVisitor alloc] init];
                        atlas_multiFileVisitor.atlas_classDump = atlas_classDump;
                        atlas_classDump.atlas_typeController.delegate = atlas_multiFileVisitor;
                        atlas_multiFileVisitor.atlas_outputPath = atlas_outputPath;
                        [atlas_classDump atlas_recursivelyVisit:atlas_multiFileVisitor];
                    } else {
                        ObjCAtlasClassDumpVisitor *atlas_visitor = [[ObjCAtlasClassDumpVisitor alloc] init];
                        atlas_visitor.atlas_classDump = atlas_classDump;
                        if ([atlas_hiddenSections containsObject:@"structures"]) atlas_visitor.atlas_shouldShowStructureSection = NO;
                        if ([atlas_hiddenSections containsObject:@"protocols"])  atlas_visitor.atlas_shouldShowProtocolSection  = NO;
                        [atlas_classDump atlas_recursivelyVisit:atlas_visitor];
                    }
                }
            }
        }
        exit(0); // avoid costly autorelease pool drain, we’re exiting anyway
    }
}
