// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLCFunctionStarts.h"

#import "atlas_ULEB128.h"

@implementation ObjCAtlasLCFunctionStarts
{
    NSArray *atlas__functionStarts;
}

#pragma mark -

// Preserve the original explicit property storage after renaming.
@synthesize atlas_functionStarts = atlas__functionStarts;

- (NSArray *)atlas_functionStarts;
{
    if (atlas__functionStarts == nil) {
        NSData *atlas_functionStartsData = [self atlas_linkeditData];
        const uint8_t *atlas_start = (uint8_t *)[atlas_functionStartsData bytes];
        const uint8_t *atlas_end = atlas_start + [atlas_functionStartsData length];
        uint64_t atlas_startAddress;
        uint64_t atlas_previousAddress = 0;
        NSMutableArray *atlas_functionStarts = [[NSMutableArray alloc] init];
        while ((atlas_startAddress = atlas_read_uleb128(&atlas_start, atlas_end))) {
            [atlas_functionStarts addObject:@(atlas_startAddress + atlas_previousAddress)];
            atlas_previousAddress += atlas_startAddress;
        }
        atlas__functionStarts = [atlas_functionStarts copy];
    }
    return atlas__functionStarts;
}

@end
