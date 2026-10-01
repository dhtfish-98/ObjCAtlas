// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCModule.h"

#import "atlas_CDObjectiveC1Processor.h"
#import "atlas_CDOCSymtab.h"

@implementation ObjCAtlasOCModule
{
    uint32_t atlas__version;
    NSString *atlas__name;
    ObjCAtlasOCSymtab *atlas__symtab;
}

// Preserve the original explicit property storage after renaming.
@synthesize version = atlas__version;
@synthesize name = atlas__name;
@synthesize atlas_symtab = atlas__symtab;

- (id)init;
{
    if ((self = [super init])) {
        atlas__version = 0;
        atlas__name = nil;
        atlas__symtab = nil;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, version: %u, symtab: %@", NSStringFromClass([self class]), self.name, self.version, self.atlas_symtab];
}

#pragma mark -

- (NSString *)atlas_formattedString;
{
    return [NSString stringWithFormat:@"//\n// %@\n//\n", self.name];
}

@end
