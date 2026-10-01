// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCMain.h"

@implementation ObjCAtlasLCMain
{
    struct entry_point_command atlas__entryPointCommand;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__entryPointCommand.cmd       = [atlas_cursor atlas_readInt32];
        atlas__entryPointCommand.cmdsize   = [atlas_cursor atlas_readInt32];
        atlas__entryPointCommand.entryoff  = [atlas_cursor atlas_readInt64];
        atlas__entryPointCommand.stacksize = [atlas_cursor atlas_readInt64];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__entryPointCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__entryPointCommand.cmdsize;
}

@end
