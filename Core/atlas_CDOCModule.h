// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasOCSymtab;

@interface ObjCAtlasOCModule : NSObject

@property (assign) uint32_t version;
@property (strong) NSString *name;
@property (strong) ObjCAtlasOCSymtab *atlas_symtab;

- (NSString *)atlas_formattedString;

@end
