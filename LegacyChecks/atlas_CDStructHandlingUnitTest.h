// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <SenTestingKit/SenTestingKit.h>

@class ObjCAtlasClassDump;

@interface ObjCAtlasCDStructHandlingUnitTest : SenTestCase
{
    ObjCAtlasClassDump *atlas_classDump;
}

- (void)dealloc;

- (void)setUp;
- (void)tearDown;

- (void)testAtlasVariableName:(NSString *)atlas_aVariableName type:(NSString *)atlas_aType expectedResult:(NSString *)atlas_expectedResult;
- (void)atlas_registerStructsFromType:(NSString *)atlas_aTypeString atlas_phase:(int)atlas_phase;

- (void)testAtlasFilename:(NSString *)atlas_testFilename;

@end
