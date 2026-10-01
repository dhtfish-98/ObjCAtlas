// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCSymtab.h"

#import "atlas_CDOCCategory.h"
#import "atlas_CDOCClass.h"

@implementation ObjCAtlasOCSymtab
{
    NSMutableArray *atlas__classes;
    NSMutableArray *atlas__categories;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_classes = atlas__classes;
@synthesize atlas_categories = atlas__categories;

- (id)init;
{
    if ((self = [super init])) {
        atlas__classes = [[NSMutableArray alloc] init];
        atlas__categories = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] classes: %@, categories: %@", NSStringFromClass([self class]), self.atlas_classes, self.atlas_categories];
}

#pragma mark -

- (void)atlas_addClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    [self.atlas_classes addObject:atlas_aClass];
}

- (void)atlas_addCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    [self.atlas_categories addObject:atlas_category];
}

@end
