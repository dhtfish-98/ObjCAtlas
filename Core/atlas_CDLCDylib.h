// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLoadCommand.h"

@interface ObjCAtlasLCDylib : ObjCAtlasLoadCommand

@property (readonly) NSString *path;
@property (nonatomic, readonly) uint32_t atlas_timestamp;
@property (nonatomic, readonly) uint32_t atlas_currentVersion;
@property (nonatomic, readonly) uint32_t atlas_compatibilityVersion;

@property (nonatomic, readonly) NSString *atlas_formattedCurrentVersion;
@property (nonatomic, readonly) NSString *atlas_formattedCompatibilityVersion;

@end
