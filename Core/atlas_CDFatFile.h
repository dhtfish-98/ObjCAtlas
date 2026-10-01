// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDFile.h"

@class ObjCAtlasFatArch;

@interface ObjCAtlasFatFile : ObjCAtlasFile

@property (readonly) NSMutableArray *atlas_arches;
@property (nonatomic, readonly) NSArray *atlas_archNames;

- (void)atlas_addArchitecture:(ObjCAtlasFatArch *)atlas_fatArch;
- (BOOL)atlas_containsArchitecture:(atlas_CDArch)atlas_arch;

@end
