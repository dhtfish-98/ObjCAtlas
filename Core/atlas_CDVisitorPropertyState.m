// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDVisitorPropertyState.h"

#import "atlas_CDOCProperty.h"

@interface ObjCAtlasVisitorPropertyState ()
@end

#pragma mark -

@implementation ObjCAtlasVisitorPropertyState
{
    NSMutableDictionary *atlas__propertiesByAccessor; // NSString (accessor)       -> CDOCProperty
    NSMutableDictionary *atlas__propertiesByName;     // NSString (property name)  -> CDOCProperty
}

- (id)initWithProperties:(NSArray *)atlas_properties;
{
    if ((self = [super init])) {
        atlas__propertiesByAccessor = [[NSMutableDictionary alloc] init];
        atlas__propertiesByName = [[NSMutableDictionary alloc] init];
        
        for (ObjCAtlasOCProperty *atlas_property in atlas_properties) {
            //NSLog(@"property: %@, getter: %@, setter: %@", [property name], [property getter], [property setter]);
            atlas__propertiesByName[atlas_property.name] = atlas_property;
            atlas__propertiesByAccessor[atlas_property.atlas_getter] = atlas_property;
            if (atlas_property.atlas_isReadOnly == NO)
                atlas__propertiesByAccessor[atlas_property.atlas_setter] = atlas_property;
        }
    }

    return self;
}

#pragma mark - Debugging

- (void)atlas_log;
{
    NSLog(@"propertiesByAccessor: %@", atlas__propertiesByAccessor);
    NSLog(@"propertiesByName: %@", atlas__propertiesByName);
}

#pragma mark -

- (ObjCAtlasOCProperty *)atlas_propertyForAccessor:(NSString *)atlas_str;
{
    return atlas__propertiesByAccessor[atlas_str];
}

- (BOOL)atlas_hasUsedProperty:(ObjCAtlasOCProperty *)atlas_property;
{
    return atlas__propertiesByName[atlas_property.name] == nil;
}

- (void)atlas_useProperty:(ObjCAtlasOCProperty *)atlas_property;
{
    [atlas__propertiesByName removeObjectForKey:atlas_property.name];
}

- (NSArray *)atlas_remainingProperties;
{
    return [[atlas__propertiesByName allValues] sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
}

@end
