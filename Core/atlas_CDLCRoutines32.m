// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCRoutines32.h"

@implementation ObjCAtlasLCRoutines32
{
    struct routines_command atlas__routinesCommand;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__routinesCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__routinesCommand.cmdsize = [atlas_cursor atlas_readInt32];
        
        atlas__routinesCommand.init_address = [atlas_cursor atlas_readInt32];
        atlas__routinesCommand.init_module  = [atlas_cursor atlas_readInt32];
        atlas__routinesCommand.reserved1    = [atlas_cursor atlas_readInt32];
        atlas__routinesCommand.reserved2    = [atlas_cursor atlas_readInt32];
        atlas__routinesCommand.reserved3    = [atlas_cursor atlas_readInt32];
        atlas__routinesCommand.reserved4    = [atlas_cursor atlas_readInt32];
        atlas__routinesCommand.reserved5    = [atlas_cursor atlas_readInt32];
        atlas__routinesCommand.reserved6    = [atlas_cursor atlas_readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__routinesCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__routinesCommand.cmdsize;
}

@end
