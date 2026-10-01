// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import <SenTestingKit/SenTestingKit.h>

@class ObjCAtlasTypeLexer;

@interface ObjCAtlasCDTypeLexerUnitTest : SenTestCase
{
    ObjCAtlasTypeLexer *atlas_lexer;
}

- (void)setUp;
- (void)tearDown;

- (void)atlas__setupLexerForString:(NSString *)atlas_str;
- (void)atlas__cleanupLexer;
- (void)atlas__showScannedTokens;
- (void)atlas_showScannedTokensForString:(NSString *)atlas_str;

- (void)testAtlasLexingString:(NSString *)atlas_str expectedResults:(struct atlas_tokenValuePair *)atlas_expectedResults;

- (void)testAtlasSimpleTokens;
- (void)testAtlasQuotedStringToken;
- (void)testAtlasEmptyQuotedStringToken;
- (void)testAtlasUnterminatedQuotedString;
- (void)testAtlasIdentifierToken;
- (void)testAtlasTemplateTokens;

@end
