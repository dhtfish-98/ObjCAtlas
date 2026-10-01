//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTypeLexerUnitTest.h"

#import <Foundation/Foundation.h>
#import "atlas_CDTypeLexer.h"

struct atlas_tokenValuePair {
    int atlas_token;
    NSString *atlas_value;
    int atlas_nextState;
};

@implementation ObjCAtlasCDTypeLexerUnitTest

- (void)setUp;
{
}

- (void)tearDown;
{
}

- (void)atlas__setupLexerForString:(NSString *)atlas_str;
{
    atlas_lexer = [[ObjCAtlasTypeLexer alloc] initWithString:atlas_str];
}

- (void)atlas__cleanupLexer;
{
    [atlas_lexer release];
    atlas_lexer = nil;
}

- (void)atlas__showScannedTokens;
{
    int atlas_token;

    NSLog(@"----------------------------------------");
    STAssertNotNil(atlas_lexer, @"");

    NSLog(@"str: %@", [atlas_lexer string]);

    [atlas_lexer setAtlas_shouldShowLexing:YES];

    atlas_token = [atlas_lexer atlas_scanNextToken];
    while (atlas_token != atlas_TK_EOS)
        atlas_token = [atlas_lexer atlas_scanNextToken];
    NSLog(@"----------------------------------------");
}

- (void)atlas_showScannedTokensForString:(NSString *)atlas_str;
{
    [self atlas__setupLexerForString:atlas_str];
    [self atlas__showScannedTokens];
    [self atlas__cleanupLexer];
}

// The last token in expectedResults must be atlas_TK_EOS.
- (void)testAtlasLexingString:(NSString *)atlas_str expectedResults:(struct atlas_tokenValuePair *)atlas_expectedResults;
{
    int atlas_token;

    [self atlas__setupLexerForString:atlas_str];
    //NSLog(@"str: %@", [lexer string]);
    //[lexer setShouldShowLexing:YES];

    while (atlas_expectedResults->atlas_token != atlas_TK_EOS) {
        atlas_token = [atlas_lexer atlas_scanNextToken];
        STAssertEquals(atlas_expectedResults->atlas_token, atlas_token, @"");
        if (atlas_expectedResults->atlas_value != nil)
            STAssertEqualObjects(atlas_expectedResults->atlas_value, [atlas_lexer atlas_lexText], @"");
        if (atlas_expectedResults->atlas_nextState != -1)
            [atlas_lexer atlas_setState:atlas_expectedResults->atlas_nextState];
        atlas_expectedResults++;
    }

    atlas_token = [atlas_lexer atlas_scanNextToken];
    STAssertEquals(atlas_TK_EOS, atlas_token, @"");

    [self atlas__cleanupLexer];
}

- (void)testAtlasSimpleTokens;
{
    NSString *atlas_str = @"i^@";
    struct atlas_tokenValuePair atlas_tokens[] = {
        { 'i',              nil,               -1 },
        { '^',              nil,               -1 },
        { '@',              nil,               -1 },
        { atlas_TK_EOS,           nil,               -1 },
    };

    [self testAtlasLexingString:atlas_str expectedResults:atlas_tokens];
}

- (void)testAtlasQuotedStringToken;
{
    NSString *atlas_str = @"@\"NSObject\"";
    struct atlas_tokenValuePair atlas_tokens[] = {
        { '@',              nil,               -1 },
        { atlas_TK_QUOTED_STRING, @"NSObject",       -1 },
        { atlas_TK_EOS,           nil,               -1 },
    };

    [self testAtlasLexingString:atlas_str expectedResults:atlas_tokens];
}

- (void)testAtlasEmptyQuotedStringToken;
{
    NSString *atlas_str = @"@\"\"";
    struct atlas_tokenValuePair atlas_tokens[] = {
        { '@',              nil,               -1 },
        { atlas_TK_QUOTED_STRING, @"",               -1 },
        { atlas_TK_EOS,           nil,               -1 },
    };

    [self testAtlasLexingString:atlas_str expectedResults:atlas_tokens];
}

- (void)testAtlasUnterminatedQuotedString;
{
    NSString *atlas_str = @"@\"NSObject";
    struct atlas_tokenValuePair atlas_tokens[] = {
        { '@',              nil,               -1 },
        { atlas_TK_QUOTED_STRING, @"NSObject",       -1 },
        { atlas_TK_EOS,           nil,               -1 },
    };

    [self testAtlasLexingString:atlas_str expectedResults:atlas_tokens];
}

// The lexer should automatically switch back to normal mode after scanning one identifier.
- (void)testAtlasIdentifierToken;
{
    NSString *atlas_str = @"iii)ii";
    struct atlas_tokenValuePair atlas_tokens[] = {
        { 'i',              nil,               atlas_CDTypeLexerState_Identifier },
        { atlas_TK_IDENTIFIER,    @"ii",             -1 },
        { ')',              nil,               -1 },
        { 'i',              nil,               -1 },
        { 'i',              nil,               -1 },
        { atlas_TK_EOS,           nil,               -1 },
    };

    [self testAtlasLexingString:atlas_str expectedResults:atlas_tokens];
}


// This tests a more complicated C++ template type, and makes sure the space between the '>'s is ignored.
- (void)testAtlasTemplateTokens;
{
    NSString *atlas_str = @"{vector<IPPhotoInfo*,std::allocator<IPPhotoInfo*> >=iic}";
    struct atlas_tokenValuePair atlas_tokens[] = {
        { '{',              nil,               atlas_CDTypeLexerState_Identifier },
        { atlas_TK_IDENTIFIER,    @"vector",         -1 },
        { '<',              nil,               atlas_CDTypeLexerState_TemplateTypes },
        { atlas_TK_TEMPLATE_TYPE, @"IPPhotoInfo*",   -1 },
        { ',',              nil,               -1 },
        { atlas_TK_TEMPLATE_TYPE, @"std::allocator", -1 },
        { '<',              nil,               atlas_CDTypeLexerState_TemplateTypes },
        { atlas_TK_TEMPLATE_TYPE, @"IPPhotoInfo*",   -1 },
        { '>',              nil,               -1 },
        { '>',              nil,               atlas_CDTypeLexerState_Normal },
        { '=',              nil,               -1 },
        { 'i',              nil,               -1 },
        { 'i',              nil,               -1 },
        { 'c',              nil,               -1 },
        { '}',              nil,               -1 },
        { atlas_TK_EOS,           nil,               -1 },
    };

    [self testAtlasLexingString:atlas_str expectedResults:atlas_tokens];
}

@end
