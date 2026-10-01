// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <SenTestingKit/SenTestingKit.h>

@class ObjCAtlasTypeFormatter;

@interface ObjCAtlasCDTypeFormatterUnitTest : SenTestCase
{
    ObjCAtlasTypeFormatter *atlas_typeFormatter;
}

- (void)dealloc;

- (void)setUp;
- (void)tearDown;

- (void)testAtlasVariableName:(NSString *)atlas_aVariableName type:(NSString *)atlas_aType expectedResult:(NSString *)atlas_expectedResult;
- (void)atlas_parseAndEncodeType:(NSString *)atlas_originalType;

@end
