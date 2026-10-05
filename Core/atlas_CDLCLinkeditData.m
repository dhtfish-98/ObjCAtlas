// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCLinkeditData.h"

#import "atlas_CDMachOFile.h"

@implementation ObjCAtlasLCLinkeditData
{
    struct linkedit_data_command atlas__linkeditDataCommand;
    NSData *atlas__linkeditData;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_linkeditData = atlas__linkeditData;

- (id)initAtlasWithDataCursor:(ObjCAtlasMachOFileDataCursor *)atlas_cursor;
{
    if ((self = [super initAtlasWithDataCursor:atlas_cursor])) {
        atlas__linkeditDataCommand.cmd     = [atlas_cursor atlas_readInt32];
        atlas__linkeditDataCommand.cmdsize = [atlas_cursor atlas_readInt32];
        
        atlas__linkeditDataCommand.dataoff  = [atlas_cursor atlas_readInt32];
        atlas__linkeditDataCommand.datasize = [atlas_cursor atlas_readInt32];
    }

    return self;
}

#pragma mark -

- (uint32_t)atlas_cmd;
{
    return atlas__linkeditDataCommand.cmd;
}

- (uint32_t)atlas_cmdsize;
{
    return atlas__linkeditDataCommand.cmdsize;
}

- (NSData *)atlas_linkeditData;
{
    if (atlas__linkeditData == NULL) {
        atlas__linkeditData = [self.atlas_machOFile atlas_dataAtOffset:atlas__linkeditDataCommand.dataoff length:atlas__linkeditDataCommand.datasize];
    }
    
    return atlas__linkeditData;
}

@end
