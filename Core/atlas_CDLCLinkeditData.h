// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLoadCommand.h"

@interface ObjCAtlasLCLinkeditData : ObjCAtlasLoadCommand

@property (nonatomic, readonly) NSData *atlas_linkeditData;

@end
