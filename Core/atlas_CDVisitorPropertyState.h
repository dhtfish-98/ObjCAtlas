// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasOCProperty;

@interface ObjCAtlasVisitorPropertyState : NSObject

- (id)initWithProperties:(NSArray *)atlas_properties;

- (ObjCAtlasOCProperty *)atlas_propertyForAccessor:(NSString *)atlas_str;

- (BOOL)atlas_hasUsedProperty:(ObjCAtlasOCProperty *)atlas_property;
- (void)atlas_useProperty:(ObjCAtlasOCProperty *)atlas_property;

@property (nonatomic, readonly) NSArray *atlas_remainingProperties;

@end
