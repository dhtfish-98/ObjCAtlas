// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCDylinker.h"

@implementation ObjCAtlasLCDylinker
{
    struct dylinker_command atlas__dylinkerCommand;
    NSString *atlas__name;
}

// Preserve the original explicit property storage after renaming.
@synthesize name = atlas__name;

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__dylinkerCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__dylinkerCommand.cmdsize = [atlas_cursor atlas_readInt32];

        atlas__dylinkerCommand.name.offset = [atlas_cursor atlas_readInt32];
        
        NSUInteger atlas_length = atlas__dylinkerCommand.cmdsize - sizeof(atlas__dylinkerCommand);
        //NSLog(@"expected length: %u", length);
        
        atlas__name = [atlas_cursor atlas_readStringOfLength:atlas_length atlas_encoding:NSASCIIStringEncoding];
        //NSLog(@"name: %@", name);
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__dylinkerCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__dylinkerCommand.cmdsize;
}

@end
