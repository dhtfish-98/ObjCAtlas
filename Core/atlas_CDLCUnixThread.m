// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCUnixThread.h"

// For now, this is all I need.  There is no data in here sensitive to its position in the file.

@implementation ObjCAtlasLCUnixThread
{
    struct load_command atlas__loadCommand;
    
    NSData *atlas__commandData;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__loadCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__loadCommand.cmdsize = [atlas_cursor atlas_readInt32];
        
        if (atlas__loadCommand.cmdsize > 8) {
            NSMutableData *atlas_commandData = [[NSMutableData alloc] init];
            [atlas_cursor atlas_appendBytesOfLength:atlas__loadCommand.cmdsize - 8 atlas_intoData:atlas_commandData];
            atlas__commandData = [atlas_commandData copy];
        } else {
            atlas__commandData = nil;
        }
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__loadCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__loadCommand.cmdsize;
}

@end
