// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface NSData (CDExtensions)

- (NSString *)atlas_hexString;
- (NSData *)atlas_SHA1Digest;

@end
