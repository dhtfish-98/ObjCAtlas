// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDMethodType.h"

#import "atlas_CDType.h"

@implementation ObjCAtlasMethodType
{
    ObjCAtlasType *atlas__type;
    NSString *atlas__offset;
}

// Preserve the original explicit property storage after renaming.
@synthesize type = atlas__type;
@synthesize atlas_offset = atlas__offset;

- (id)initAtlasWithType:(ObjCAtlasType *)atlas_type atlas_offset:(NSString *)atlas_offset;
{
    if ((self = [super init])) {
        atlas__type = atlas_type;
        atlas__offset = atlas_offset;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] type: %@, offset: %@", NSStringFromClass([self class]), self.type, self.atlas_offset];
}

@end
