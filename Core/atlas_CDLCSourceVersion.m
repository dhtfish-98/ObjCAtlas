// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCSourceVersion.h"

#import "atlas_CDMachOFile.h"

@implementation ObjCAtlasLCSourceVersion
{
    struct source_version_command atlas__sourceVersionCommand;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__sourceVersionCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__sourceVersionCommand.cmdsize = [atlas_cursor atlas_readInt32];
        atlas__sourceVersionCommand.version = [atlas_cursor atlas_readInt64];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__sourceVersionCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__sourceVersionCommand.cmdsize;
}

- (NSString *)atlas_sourceVersionString;
{
    // A.B.C.D.E packed as a24.b10.c10.d10.e10
    uint32_t atlas_a =  atlas__sourceVersionCommand.version >> 40;
    uint32_t atlas_b = (atlas__sourceVersionCommand.version >> 30) & 0x3ff;
    uint32_t atlas_c = (atlas__sourceVersionCommand.version >> 20) & 0x3ff;
    uint32_t atlas_d = (atlas__sourceVersionCommand.version >> 10) & 0x3ff;
    uint32_t atlas_e =  atlas__sourceVersionCommand.version        & 0x3ff;

    return [NSString stringWithFormat:@"%u.%u.%u.%u.%u", atlas_a, atlas_b, atlas_c, atlas_d, atlas_e];
}

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_verbose:(BOOL)atlas_isVerbose;
{
    [super atlas_appendToString:atlas_resultString atlas_verbose:atlas_isVerbose];

    [atlas_resultString appendFormat:@"    Source version: %@\n", self.atlas_sourceVersionString];
}

@end
