// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasOCCategory, ObjCAtlasOCClass;

@interface ObjCAtlasOCSymtab : NSObject

@property (readonly) NSMutableArray *atlas_classes;
- (void)atlas_addClass:(ObjCAtlasOCClass *)atlas_aClass;

@property (readonly) NSMutableArray *atlas_categories;
- (void)atlas_addCategory:(ObjCAtlasOCCategory *)atlas_category;

@end
