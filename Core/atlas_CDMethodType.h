// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasType;

@interface ObjCAtlasMethodType : NSObject

- (id)initAtlasWithType:(ObjCAtlasType *)atlas_type atlas_offset:(NSString *)atlas_offset;

@property (readonly) ObjCAtlasType *type;
@property (readonly) NSString *atlas_offset;

@end
