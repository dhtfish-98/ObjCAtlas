// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasType;

@interface ObjCAtlasOCProperty : NSObject

- (id)initAtlasWithName:(NSString *)atlas_name atlas_attributes:(NSString *)atlas_attributes;

@property (readonly) NSString *name;
@property (readonly) NSString *atlas_attributeString;
@property (readonly) ObjCAtlasType *type;
@property (readonly) NSArray *attributes;

@property (strong) NSString *atlas_attributeStringAfterType;

@property (nonatomic, readonly) NSString *atlas_defaultGetter;
@property (nonatomic, readonly) NSString *atlas_defaultSetter;

@property (strong) NSString *atlas_customGetter;
@property (strong) NSString *atlas_customSetter;

@property (nonatomic, readonly) NSString *atlas_getter;
@property (nonatomic, readonly) NSString *atlas_setter;

@property (readonly) BOOL atlas_isReadOnly;
@property (readonly) BOOL atlas_isDynamic;

- (NSComparisonResult)atlas_ascendingCompareByName:(ObjCAtlasOCProperty *)atlas_other;

@end
