// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLoadCommand.h"

@interface ObjCAtlasLCEncryptionInfo : ObjCAtlasLoadCommand

@property (nonatomic, readonly) uint32_t atlas_cryptoff;
@property (nonatomic, readonly) uint32_t atlas_cryptsize;
@property (nonatomic, readonly) uint32_t atlas_cryptid;

@property (nonatomic, readonly) BOOL atlas_isEncrypted;

@end
