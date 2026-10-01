// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCPrebindChecksum.h"

@implementation ObjCAtlasLCPrebindChecksum
{
    struct prebind_cksum_command atlas__prebindChecksumCommand;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__prebindChecksumCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__prebindChecksumCommand.cmdsize = [atlas_cursor atlas_readInt32];
        atlas__prebindChecksumCommand.cksum   = [atlas_cursor atlas_readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__prebindChecksumCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__prebindChecksumCommand.cmdsize;
}

- (uint32_t)atlas_cksum;
{
    return atlas__prebindChecksumCommand.cksum;
}

@end
