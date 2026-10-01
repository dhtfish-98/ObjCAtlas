// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDRelocationInfo.h"

@implementation ObjCAtlasRelocationInfo
{
    struct relocation_info atlas__rinfo;
}

- (id)initAtlasWithInfo:(struct relocation_info)atlas_info;
{
    if ((self = [super init])) {
        atlas__rinfo = atlas_info;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> addr/off: %08x, sym #: %5u, pcrel? %u, len: %u, extern? %u, type: %x",
            NSStringFromClass([self class]), self,
            atlas__rinfo.r_address, atlas__rinfo.r_symbolnum, atlas__rinfo.r_pcrel, atlas__rinfo.r_length, atlas__rinfo.r_extern, atlas__rinfo.r_type];
}

#pragma mark -

- (NSUInteger)atlas_offset;
{
    return atlas__rinfo.r_address;
}

- (atlas_CDRelocationSize)atlas_size;
{
    return atlas__rinfo.r_length;
}

- (uint32_t)atlas_symbolnum;
{
    return atlas__rinfo.r_symbolnum;
}

- (BOOL)atlas_isExtern;
{
    return atlas__rinfo.r_extern == 1;
}

@end
