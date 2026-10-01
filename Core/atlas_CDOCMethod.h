// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasTypeController;

@interface ObjCAtlasOCMethod : NSObject <NSCopying>

- (id)initAtlasWithName:(NSString *)atlas_name atlas_typeString:(NSString *)atlas_typeString;
- (id)initAtlasWithName:(NSString *)atlas_name atlas_typeString:(NSString *)atlas_typeString atlas_address:(NSUInteger)atlas_address;

@property (readonly) NSString *name;
@property (readonly) NSString *atlas_typeString;
@property (assign) NSUInteger address;

- (NSArray *)atlas_parsedMethodTypes;

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_typeController:(ObjCAtlasTypeController *)atlas_typeController;

- (NSComparisonResult)atlas_ascendingCompareByName:(ObjCAtlasOCMethod *)atlas_other;

@end
