//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTypeParserUnitTest.h"

#import <Foundation/Foundation.h>
#import "atlas_NSError_CDExtensions.h"

#import "atlas_CDType.h"
#import "atlas_CDTypeLexer.h"
#import "atlas_CDTypeParser.h"

@implementation ObjCAtlasCDTypeParserUnitTest

- (void)setUp;
{
}

- (void)tearDown;
{
}

- (void)testAtlasType:(NSString *)atlas_aType showLexing:(BOOL)atlas_shouldShowLexing;
{
    ObjCAtlasTypeParser *atlas_aTypeParser;
    ObjCAtlasType *atlas_result;
    NSError *atlas_error;

    if (atlas_shouldShowLexing) {
        NSLog(@"----------------------------------------");
        NSLog(@"str: %@", atlas_aType);
    }

    aTypeParser = [[CDTypeParser alloc] initWithType:aType];
    [[atlas_aTypeParser atlas_lexer] setAtlas_shouldShowLexing:atlas_shouldShowLexing];
    atlas_result = [atlas_aTypeParser atlas_parseType:&atlas_error];
    STAssertNotNil(atlas_result, @"-[CDTypeParser parseType:] error: %@", [error myExplanation]);
    [atlas_aTypeParser release];
}

- (void)testAtlasMethodType:(NSString *)atlas_aMethodType showLexing:(BOOL)atlas_shouldShowLexing;
{
    ObjCAtlasTypeParser *atlas_aTypeParser;
    NSArray *atlas_result;
    NSError *atlas_error;

    aTypeParser = [[CDTypeParser alloc] initWithType:aMethodType];
    [[atlas_aTypeParser atlas_lexer] setAtlas_shouldShowLexing:atlas_shouldShowLexing];
    atlas_result = [atlas_aTypeParser atlas_parseMethodType:&atlas_error];
    STAssertNotNil(atlas_result, @"-[CDTypeParser parseMethodType:] error: %@", [error myExplanation]);
    [atlas_aTypeParser release];
}

- (void)testAtlasLoneConstType;
{
    // On Panther, from WebCore, -[KWQPageState
    // initWithDocument:URL:windowProperties:locationProperties:interpreterBuiltins:]
    // has part of a method type as "r12".  "r" is const, but it doesn't modify anything.

    [self testAtlasMethodType:@"ri12i16" showLexing:NO]; // This works
    [self testAtlasMethodType:@"r12i16" showLexing:NO]; // This didn't work.
}

// Field names:
// {?="field1"^@"NSObject"} -- end of struct, use quoted string
// {?="field1"^@"NSObject""field2"@} -- followed by field, use quoted string
// {?="field1"^@"field2"^@} -- quoted string is followed by type, don't use quoted string for object

// No field names -- always use the quoted string
// {?=^@"NSObject"}
// {?=^@"NSObject"^@"NSObject"}

- (void)testAtlasObjectQuotedStringTypes;
{
    NSString *atlas_str;

    atlas_str = @"{?=\"field1\"^@\"NSObject\"}";
    [self testAtlasType:atlas_str showLexing:NO];

    atlas_str = @"{?=\"field1\"^@\"NSObject\"\"field2\"@}";
    [self testAtlasType:atlas_str showLexing:NO];

    atlas_str = @"{?=\"field1\"^@\"field2\"^@}";
    [self testAtlasType:atlas_str showLexing:NO];

    atlas_str = @"{?=^@\"NSObject\"}";
    [self testAtlasType:atlas_str showLexing:NO];

    atlas_str = @"{?=^@\"NSObject\"^@\"NSObject\"}";
    [self testAtlasType:atlas_str showLexing:NO];
}

- (void)testAtlasMissingFieldNames;
{
    NSString *atlas_str;

    atlas_str = @"{?=b8b4b1b1b18\"_field1\"[8S]}";
    [self testAtlasType:atlas_str showLexing:NO];
}

- (void)testAtlasLowercaseClassName;
{
    NSString *atlas_str;

    atlas_str = @"@\"iToolsAccount\"";
    [self testAtlasType:atlas_str showLexing:NO];
}

- (void)testAtlasLowercaseClassName2;
{
    NSString *atlas_str;

    atlas_str = @"{?=@\"iToolsAccount\"}";
    [self testAtlasType:atlas_str showLexing:NO];
}

- (void)testAtlasPages08;
{
    // Pages '08 has this bit in it: {vector<<unnamed>::AnimationChunk,std::allocator<<unnamed>::AnimationChunk> >=II}

    [self testAtlasType:@"{unnamed=II}" showLexing:NO];
    [self testAtlasType:@"{vector<unnamed>=II}" showLexing:NO];
    [self testAtlasType:@"{vector<unnamed::blegga>=II}" showLexing:NO];
    [self testAtlasType:@"{vector<<unnamed>::blegga>=II}" showLexing:NO];
    [self testAtlasType:@"{vector<<unnamed>::AnimationChunk>=II}" showLexing:NO];
    [self testAtlasType:@"{vector<<unnamed>::AnimationChunk>=II}" showLexing:NO];
    [self testAtlasType:@"{vector<<unnamed>::AnimationChunk,std::allocator<<unnamed>::AnimationChunk> >=II}" showLexing:NO];
}

@end
