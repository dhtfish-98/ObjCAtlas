//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDStructHandlingUnitTest.h"

#import <Foundation/Foundation.h>
#import "atlas_NSError_CDExtensions.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDType.h"
#import "atlas_CDTypeFormatter.h"
#import "atlas_CDTypeParser.h"

@implementation ObjCAtlasCDStructHandlingUnitTest

- (void)dealloc;
{
    [atlas_classDump release];

    [super dealloc];
}

- (void)setUp;
{
    atlas_classDump = [[ObjCAtlasClassDump alloc] init];
}

- (void)tearDown;
{
    [atlas_classDump release];
    atlas_classDump = nil;
}

- (void)testAtlasVariableName:(NSString *)atlas_aVariableName type:(NSString *)atlas_aType expectedResult:(NSString *)atlas_expectedResult;
{
    NSString *atlas_result;

    result = [[classDump ivarTypeFormatter] formatVariable:aVariableName type:aType symbolReferences:nil];
    STAssertEqualObjects(atlas_expectedResult, atlas_result, @"");
}

- (void)atlas_registerStructsFromType:(NSString *)atlas_aTypeString atlas_phase:(int)atlas_phase;
{
    ObjCAtlasTypeParser *atlas_parser;
    ObjCAtlasType *atlas_type;
    NSError *atlas_error;

    parser = [[CDTypeParser alloc] initWithType:aTypeString];
    atlas_type = [atlas_parser atlas_parseType:&atlas_error];
    STAssertNotNil(atlas_type, @"-[CDTypeParser parseType:] error: %@", [error myExplanation]);

    [type phase:phase registerStructuresWithObject:classDump usedInMethod:NO];
    [atlas_parser release];
}

// TODO (2004-01-05): Move this somewhere that we can share it with the main app.
- (void)testAtlasFilename:(NSString *)atlas_testFilename;
{
    NSString *atlas_inputFilename, *atlas_outputFilename;
    NSMutableString *atlas_resultString;
    NSString *atlas_inputContents, *atlas_expectedOutputContents;
    NSArray *atlas_inputLines, *atlas_inputFields;
    int atlas_phase;
    int atlas_count, atlas_index;
    NSBundle *atlas_bundle;

    //NSLog(@"***** %@", testFilename);

    atlas_resultString = [NSMutableString string];

    atlas_bundle = [NSBundle bundleForClass:[self class]];
    atlas_inputFilename = [atlas_bundle pathForResource:[atlas_testFilename stringByAppendingString:@"-in"] ofType:@"txt"];
    atlas_outputFilename = [atlas_bundle pathForResource:[atlas_testFilename stringByAppendingString:@"-out"] ofType:@"txt"];

    atlas_inputContents = [NSString stringWithContentsOfFile:atlas_inputFilename];
    atlas_expectedOutputContents = [NSString stringWithContentsOfFile:atlas_outputFilename];

    atlas_inputLines = [atlas_inputContents componentsSeparatedByString:@"\n"];
    atlas_count = [atlas_inputLines count];

    // First register structs/unions
    for (atlas_phase = 1; atlas_phase <= 2; atlas_phase++) {
        //NSLog(@"Phase %d ========================================", phase);

        for (atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
            NSString *atlas_line;

            atlas_line = [atlas_inputLines objectAtIndex:atlas_index];
            if ([atlas_line length] > 0 && [atlas_line hasPrefix:@"//"] == NO) {
                atlas_inputFields = [atlas_line componentsSeparatedByString:@"\t"];
                [self atlas_registerStructsFromType:[atlas_inputFields objectAtIndex:0] atlas_phase:atlas_phase];
            }
        }

        [classDump endPhase:phase];
    }

    // Then generate output
    [classDump appendStructuresToString:resultString symbolReferences:nil];

    for (atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
        NSString *atlas_line;
        NSString *atlas_type, *atlas_variableName;

        atlas_line = [atlas_inputLines objectAtIndex:atlas_index];
        if ([atlas_line length] > 0 && [atlas_line hasPrefix:@"//"] == NO) {
            int atlas_fieldCount, atlas_level;
            NSString *atlas_formattedString;

            atlas_inputFields = [atlas_line componentsSeparatedByString:@"\t"];
            atlas_fieldCount = [atlas_inputFields count];
            atlas_type = [atlas_inputFields objectAtIndex:0];
            if (atlas_fieldCount > 1)
                atlas_variableName = [atlas_inputFields objectAtIndex:1];
            else
                atlas_variableName = @"var";

            if (atlas_fieldCount > 2)
                atlas_level = [[atlas_inputFields objectAtIndex:2] intValue];
            else
                atlas_level = 0;

            formattedString = [[classDump ivarTypeFormatter] formatVariable:variableName type:type symbolReferences:nil];
            if (atlas_formattedString != nil) {
                [atlas_resultString appendString:atlas_formattedString];
                [atlas_resultString appendString:@";\n"];
            } else {
                [atlas_resultString appendString:@"Parse failed.\n"];
            }
        }
    }

    STAssertEqualObjects(atlas_expectedOutputContents, atlas_resultString, @"test file: %@", testFilename);
}

#if 1
- (void)testAtlas01;
{
    NSString *atlas_first = @"{_NSRange=II}";
    int atlas_phase;

    STAssertNotNil(atlas_classDump, @"classDump");
    STAssertNotNil([classDump ivarTypeFormatter], @"[classDump ivarTypeFormatter]");

    for (atlas_phase = 1; atlas_phase <= 2; atlas_phase++)
        [self atlas_registerStructsFromType:atlas_first atlas_phase:atlas_phase];
    [self testAtlasVariableName:@"foo" type:atlas_first expectedResult:@"    struct _NSRange foo"];

    // Register {_NSRange=II}
    // Test {_NSRange=II}
}

- (void)testAtlas02;
{
    NSString *atlas_first = @"{_NSRange=II}";
    NSString *atlas_second = @"{_NSRange=\"location\"I\"length\"I}";
    int atlas_phase;

    for (atlas_phase = 1; atlas_phase <= 2; atlas_phase++) {
        [self atlas_registerStructsFromType:atlas_first atlas_phase:atlas_phase];
        [self atlas_registerStructsFromType:atlas_second atlas_phase:atlas_phase];
    }

    [self testAtlasVariableName:@"foo" type:atlas_first expectedResult:@"    struct _NSRange foo"];
    [self testAtlasVariableName:@"bar" type:atlas_second expectedResult:@"    struct _NSRange bar"];

    // Register {_NSRange=II}
    // Register {_NSRange="location"I"length"I}
    // Test {_NSRange=II}
    // Test {_NSRange="location"I"length"I}
}

- (void)testAtlas03;
{
    NSString *atlas_first = @"{_NSRange=\"location\"I\"length\"I}";
    NSString *atlas_second = @"{_NSRange=II}";
    int atlas_phase;

    for (atlas_phase = 1; atlas_phase <= 2; atlas_phase++) {
        [self atlas_registerStructsFromType:atlas_first atlas_phase:atlas_phase];
        [self atlas_registerStructsFromType:atlas_second atlas_phase:atlas_phase];
    }

    [self testAtlasVariableName:@"foo" type:atlas_first expectedResult:@"    struct _NSRange foo"];
    [self testAtlasVariableName:@"bar" type:atlas_second expectedResult:@"    struct _NSRange bar"];

    // Register {_NSRange="location"I"length"I}
    // Register {_NSRange=II}
    // Test {_NSRange="location"I"length"I}
    // Test {_NSRange=II}
}

- (void)testAtlas04;
{
    // I'm guessing that "shud" could stand for Struct Handling Unittest Data.
    [self testAtlasFilename:@"shud01"];
}

- (void)testAtlas05;
{
    [self testAtlasFilename:@"shud02"];
}

- (void)testAtlas06;
{
    //[self testFilename:@"shud03"];
}

- (void)testAtlas07;
{
    [self testAtlasFilename:@"shud04"];
}

- (void)testAtlas08;
{
    [self testAtlasFilename:@"shud05"];
}

- (void)testAtlas09;
{
    [self testAtlasFilename:@"shud06"];
}

- (void)testAtlas10;
{
    [self testAtlasFilename:@"shud07"];
}

- (void)testAtlas11;
{
    [self testAtlasFilename:@"shud08"];
}

- (void)testAtlas12;
{
    [self testAtlasFilename:@"shud09"];
}

- (void)testAtlas13;
{
    [self testAtlasFilename:@"shud10"];
}

- (void)testAtlas14;
{
    [self testAtlasFilename:@"shud11"];
}
#endif

- (void)testAtlas15;
{
    [self testAtlasFilename:@"shud13"];
}

- (void)testAtlas16;
{
    //[self testFilename:@"shud14"];
}

// This tests the new code for dealing with named objects and field names in structures.
- (void)testAtlas17;
{
    [self testAtlasFilename:@"shud15"];
}

- (void)testAtlas18;
{
    [self testAtlasFilename:@"shud16"];
}

@end
