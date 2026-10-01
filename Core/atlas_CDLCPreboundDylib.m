// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCPreboundDylib.h"

#import "atlas_CDFatFile.h"
#import "atlas_CDMachOFile.h"

@implementation ObjCAtlasLCPreboundDylib
{
    struct prebound_dylib_command atlas__preboundDylibCommand;
}

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        //NSLog(@"current offset: %u", [cursor offset]);
        atlas__preboundDylibCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__preboundDylibCommand.cmdsize = [atlas_cursor atlas_readInt32];
        //NSLog(@"cmdsize: %u", preboundDylibCommand.cmdsize);
        
        atlas__preboundDylibCommand.name.offset           = [atlas_cursor atlas_readInt32];
        atlas__preboundDylibCommand.nmodules              = [atlas_cursor atlas_readInt32];
        atlas__preboundDylibCommand.linked_modules.offset = [atlas_cursor atlas_readInt32];
        
        if (atlas__preboundDylibCommand.cmdsize > 20) {
            // Don't need this info right now.
            [atlas_cursor atlas_advanceByLength:atlas__preboundDylibCommand.cmdsize - 20];
        }
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__preboundDylibCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__preboundDylibCommand.cmdsize;
}

@end
