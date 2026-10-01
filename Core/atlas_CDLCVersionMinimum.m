// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCVersionMinimum.h"

#import "atlas_CDMachOFile.h"

@implementation ObjCAtlasLCVersionMinimum
{
    struct version_min_command atlas__versionMinCommand;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__versionMinCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__versionMinCommand.cmdsize = [atlas_cursor atlas_readInt32];
        atlas__versionMinCommand.version = [atlas_cursor atlas_readInt32];
        atlas__versionMinCommand.sdk     = [atlas_cursor atlas_readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__versionMinCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__versionMinCommand.cmdsize;
}

- (NSString *)atlas_minimumVersionString;
{
    uint32_t atlas_x = (atlas__versionMinCommand.version >> 16);
    uint32_t atlas_y = (atlas__versionMinCommand.version >> 8) & 0xff;
    uint32_t atlas_z = atlas__versionMinCommand.version & 0xff;

    return [NSString stringWithFormat:@"%u.%u.%u", atlas_x, atlas_y, atlas_z];
}

- (NSString *)atlas_SDKVersionString;
{
    uint32_t atlas_x = (atlas__versionMinCommand.sdk >> 16);
    uint32_t atlas_y = (atlas__versionMinCommand.sdk >> 8) & 0xff;
    uint32_t atlas_z = atlas__versionMinCommand.sdk & 0xff;
    
    return [NSString stringWithFormat:@"%u.%u.%u", atlas_x, atlas_y, atlas_z];
}

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_verbose:(BOOL)atlas_isVerbose;
{
    [super atlas_appendToString:atlas_resultString atlas_verbose:atlas_isVerbose];

    [atlas_resultString appendFormat:@"    Minimum version: %@\n", self.atlas_minimumVersionString];
    [atlas_resultString appendFormat:@"    SDK version: %@\n", self.atlas_SDKVersionString];
}

@end
