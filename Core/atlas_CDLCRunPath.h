// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLoadCommand.h"

@interface ObjCAtlasLCRunPath : ObjCAtlasLoadCommand

@property (readonly) NSString *path;
@property (nonatomic, readonly) NSString *atlas_resolvedRunPath;

@end
