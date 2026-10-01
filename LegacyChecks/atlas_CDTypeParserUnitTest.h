// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <SenTestingKit/SenTestingKit.h>

@interface ObjCAtlasCDTypeParserUnitTest : SenTestCase
{
}

- (void)setUp;
- (void)tearDown;

- (void)testAtlasType:(NSString *)atlas_aType showLexing:(BOOL)atlas_shouldShowLexing;
- (void)testAtlasMethodType:(NSString *)atlas_aMethodType showLexing:(BOOL)atlas_shouldShowLexing;

- (void)testAtlasLoneConstType;
- (void)testAtlasObjectQuotedStringTypes;

- (void)testAtlasMissingFieldNames;
- (void)testAtlasLowercaseClassName;

@end
