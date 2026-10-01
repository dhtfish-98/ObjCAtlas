// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <SenTestingKit/SenTestingKit.h>

@class ObjCAtlasClassDump;

@interface ObjCAtlasCDPathUnitTest : SenTestCase
{
    ObjCAtlasClassDump *atlas_classDump;
}

- (void)setUp;
- (void)tearDown;

@end
