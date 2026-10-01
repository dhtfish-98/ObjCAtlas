// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLoadCommand.h"

@class ObjCAtlasRelocationInfo;

@interface ObjCAtlasLCDynamicSymbolTable : ObjCAtlasLoadCommand

- (void)atlas_loadSymbols;

- (ObjCAtlasRelocationInfo *)atlas_relocationEntryWithOffset:(NSUInteger)atlas_offset;

@end
