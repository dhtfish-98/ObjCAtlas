// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTypeName.h"

@implementation ObjCAtlasTypeName
{
    NSString *atlas__name;
    NSMutableArray *atlas__templateTypes;
    NSString *atlas__suffix;
}

// Preserve the original explicit property storage after renaming.
@synthesize name = atlas__name;
@synthesize atlas_templateTypes = atlas__templateTypes;
@synthesize atlas_suffix = atlas__suffix;

- (id)init;
{
    if ((self = [super init])) {
        atlas__name = nil;
        atlas__templateTypes = [[NSMutableArray alloc] init];
        atlas__suffix = nil;
    }

    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)atlas_zone;
{
    ObjCAtlasTypeName *atlas_copy = [[ObjCAtlasTypeName alloc] init];
    atlas_copy.name = self.name;
    atlas_copy.atlas_suffix = self.atlas_suffix;
    
    for (ObjCAtlasTypeName *atlas_subtype in self.atlas_templateTypes) {
        ObjCAtlasTypeName *atlas_subcopy = [atlas_subtype copy];
        [atlas_copy.atlas_templateTypes addObject:atlas_subcopy];
    }
    
    return atlas_copy;
}

#pragma mark -

- (BOOL)isEqual:(id)atlas_otherObject;
{
    if ([atlas_otherObject isKindOfClass:[self class]] == NO)
        return NO;
    
    return [[self description] isEqual:[atlas_otherObject description]];
}

#pragma mark - Debugging

- (NSString *)description;
{
    if ([self.atlas_templateTypes count] == 0) {
        return self.name ? self.name : @"";
    }
    
    if (self.atlas_suffix != nil)
        return [NSString stringWithFormat:@"%@<%@>%@", self.name, [self.atlas_templateTypes componentsJoinedByString:@", "], self.atlas_suffix];
    
    return [NSString stringWithFormat:@"%@<%@>", self.name, [self.atlas_templateTypes componentsJoinedByString:@", "]];
}

#pragma mark -

- (BOOL)atlas_isTemplateType;
{
    return [self.atlas_templateTypes count] > 0;
}

@end
