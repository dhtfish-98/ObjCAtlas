// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCTwoLevelHints.h"

#import "atlas_CDMachOFile.h"

@implementation ObjCAtlasLCTwoLevelHints
{
    struct twolevel_hints_command atlas__hintsCommand;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__hintsCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__hintsCommand.cmdsize = [atlas_cursor atlas_readInt32];
        atlas__hintsCommand.offset  = [atlas_cursor atlas_readInt32];
        atlas__hintsCommand.nhints  = [atlas_cursor atlas_readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__hintsCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__hintsCommand.cmdsize;
}

@end
