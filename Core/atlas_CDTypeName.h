// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface ObjCAtlasTypeName : NSObject <NSCopying>

@property (strong) NSString *name;
@property (readonly) NSMutableArray *atlas_templateTypes;
@property (strong) NSString *atlas_suffix;
@property (nonatomic, readonly) BOOL atlas_isTemplateType;

@end
