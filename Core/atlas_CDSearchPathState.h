// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface ObjCAtlasSearchPathState : NSObject

@property (nonatomic, strong) NSString *executablePath;

- (void)atlas_pushSearchPaths:(NSArray *)atlas_searchPaths;
- (void)atlas_popSearchPaths;

- (NSArray *)atlas_searchPaths;

@end
