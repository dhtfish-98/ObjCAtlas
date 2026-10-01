// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#include <stdio.h>
#include <libc.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>
#include <sysexits.h>
#include <mach-o/arch.h>

#import "atlas_CDClassDump.h"
#import "atlas_CDMachOFile.h"
#import "atlas_CDFatFile.h"
#import "atlas_CDLoadCommand.h"
#import "atlas_CDLCSegment.h"

void atlas_print_usage(void)
{
    fprintf(stderr,
            "deprotect %s\n"
            "Usage: deprotect [options] <input file> <output file>\n"
            "\n"
            "  where options are:\n"
            "        --arch <arch>  choose a specific architecture from a universal binary (ppc, ppc64, i386, x86_64, armv6, armv7, armv7s, arm64)\n"
            ,
            atlas_CLASS_DUMP_VERSION
       );
}

BOOL atlas_saveDeprotectedFileToPath(ObjCAtlasMachOFile *atlas_file, NSString *atlas_path)
{
    BOOL atlas_hasProtectedSegments = NO;
    NSMutableData *atlas_mdata = [[NSMutableData alloc] initWithData:atlas_file.data];
    for (ObjCAtlasLoadCommand *atlas_command in atlas_file.atlas_loadCommands) {
        if ([atlas_command isKindOfClass:[ObjCAtlasLCSegment class]]) {
            ObjCAtlasLCSegment *atlas_segment = (ObjCAtlasLCSegment *)atlas_command;
            
            if (atlas_segment.atlas_isProtected) {
                atlas_hasProtectedSegments = YES;
                NSRange atlas_segmentRange = NSMakeRange([atlas_segment atlas_fileoff], [atlas_segment atlas_filesize]);
                NSUInteger atlas_flagOffset;
                
                NSData *atlas_decryptedData = [atlas_segment atlas_decryptedData];
                NSCParameterAssert([atlas_decryptedData length] == atlas_segmentRange.length);
                
                [atlas_mdata replaceBytesInRange:atlas_segmentRange withBytes:[atlas_decryptedData bytes]];
                if (atlas_segment.atlas_machOFile.atlas_uses64BitABI) {
                    atlas_flagOffset = [atlas_segment atlas_commandOffset] + offsetof(struct segment_command_64, flags);
                } else {
                    atlas_flagOffset = [atlas_segment atlas_commandOffset] + offsetof(struct segment_command, flags);
                }
                
                ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:atlas_file atlas_offset:atlas_flagOffset];
                uint32_t atlas_flags = [atlas_cursor atlas_readInt32];
                if (atlas_flags != [atlas_segment atlas_flags]) {
                    fprintf(stderr, "Internal Error: flags (0x%x) does not match segment flags (0x%x).\n", atlas_flags, [atlas_segment atlas_flags]);
                    exit(EX_SOFTWARE);
                }
                atlas_flags &= ~SG_PROTECTED_VERSION_1;
                
                if (atlas_file.atlas_byteOrder == atlas_CDByteOrder_BigEndian) {
                    OSWriteBigInt32([atlas_mdata mutableBytes], atlas_flagOffset, atlas_flags);
                } else {
                    OSWriteLittleInt32([atlas_mdata mutableBytes], atlas_flagOffset, atlas_flags);
                }
            }
        }
    }
    
    if (atlas_hasProtectedSegments) {
        [atlas_mdata writeToFile:atlas_path atomically:NO];
    }
    
    return atlas_hasProtectedSegments;
}

int main(int atlas_argc, char *atlas_argv[])
{
    @autoreleasepool {
        if (atlas_argc == 1) {
            atlas_print_usage();
            exit(EX_OK);
        }
        
        int atlas_ch;
        BOOL atlas_errorFlag = NO;
        atlas_CDArch atlas_targetArch = {CPU_TYPE_ANY, CPU_TYPE_ANY};
        
        struct option atlas_longopts[] = {
            { "arch", required_argument, NULL, 'a' },
            { NULL,   0,                 NULL, 0 },
        };
        
        while ( (atlas_ch = getopt_long(atlas_argc, atlas_argv, "a:", atlas_longopts, NULL)) != -1) {
            switch (atlas_ch) {
                case 'a': {
                    NSString *atlas_name = [NSString stringWithUTF8String:optarg];
                    atlas_targetArch = atlas_CDArchFromName(atlas_name);
                    if (atlas_targetArch.atlas_cputype == CPU_TYPE_ANY) {
                        fprintf(stderr, "Error: Unknown arch %s\n\n", optarg);
                        atlas_errorFlag = YES;
                    }
                    break;
                }
                case '?':
                default:
                    atlas_errorFlag = YES;
                    break;
            }
        }
        
        atlas_argc -= optind;
        atlas_argv += optind;

        if (atlas_errorFlag || atlas_argc < 2) {
            atlas_print_usage();
            exit(EX_USAGE);
        }
        
        {
            NSString *atlas_inputFile = [NSString atlas_stringWithFileSystemRepresentation:atlas_argv[0]];
            NSString *atlas_outputFile = [NSString atlas_stringWithFileSystemRepresentation:atlas_argv[1]];
            
            ObjCAtlasFile *atlas_file = [ObjCAtlasFile atlas_fileWithContentsOfFile:atlas_inputFile atlas_searchPathState:nil];
            if (atlas_file == nil) {
                fprintf(stderr, "Error: input file is neither a Mach-O file nor a fat archive.\n");
                exit(EX_DATAERR);
            }
            
            ObjCAtlasMachOFile *atlas_thinFile = nil;
            if ([atlas_file isKindOfClass:[ObjCAtlasMachOFile class]]) {
                atlas_thinFile = (ObjCAtlasMachOFile *)atlas_file;
            } else if ([atlas_file isKindOfClass:[ObjCAtlasFatFile class]]) {
                if (atlas_targetArch.atlas_cputype == CPU_TYPE_ANY) {
                    if ([atlas_file atlas_bestMatchForLocalArch:&atlas_targetArch] == NO) {
                        fprintf(stderr, "Internal Error: Couldn't get local architecture.\n");
                        exit(EX_SOFTWARE);
                    }
                }
                atlas_thinFile = [(ObjCAtlasFatFile *)atlas_file atlas_machOFileWithArch:atlas_targetArch];
                if (!atlas_thinFile) {
                    const NXArchInfo *atlas_arhcInfo = NXGetArchInfoFromCpuType(atlas_targetArch.atlas_cputype, atlas_targetArch.atlas_cpusubtype);
                    fprintf(stderr, "Error: input file does not contain the '%s' arch.\n", atlas_arhcInfo->name);
                    exit(EX_DATAERR);
                }
            } else {
                fprintf(stderr, "Internal Error: file is neither a CDFatFile nor a CDMachOFile instance.\n");
                exit(EX_SOFTWARE);
            }
            
            BOOL atlas_hasProtectedSegments = atlas_saveDeprotectedFileToPath(atlas_thinFile, atlas_outputFile);
            if (!atlas_hasProtectedSegments) {
                const NXArchInfo *atlas_arhcInfo = NXGetArchInfoFromCpuType(atlas_targetArch.atlas_cputype, atlas_targetArch.atlas_cpusubtype);
                fprintf(stderr, "Error: input file (%s arch) is not protected.\n", atlas_arhcInfo->name);
                exit(EX_DATAERR);
            }
        }
    }

    return 0;
}
