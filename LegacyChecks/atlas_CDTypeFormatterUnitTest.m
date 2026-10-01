//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTypeFormatterUnitTest.h"

#import <Foundation/Foundation.h>
#import "atlas_NSError_CDExtensions.h"

#import "atlas_CDType.h"
#import "atlas_CDTypeFormatter.h"
#import "atlas_CDTypeLexer.h"
#import "atlas_CDTypeParser.h"

@implementation ObjCAtlasCDTypeFormatterUnitTest

- (void)dealloc;
{
    [atlas_typeFormatter release];
    [super dealloc];
}

- (void)setUp;
{
    atlas_typeFormatter = [[ObjCAtlasTypeFormatter alloc] init];
}

- (void)tearDown;
{
    [atlas_typeFormatter release];
    atlas_typeFormatter = nil;
}

- (void)testAtlasVariableName:(NSString *)atlas_aVariableName type:(NSString *)atlas_aType expectedResult:(NSString *)atlas_expectedResult;
{
    NSString *atlas_result;

    result = [typeFormatter formatVariable:aVariableName type:aType symbolReferences:nil];
    STAssertEqualObjects(atlas_expectedResult, atlas_result, @"");
}

- (void)atlas_parseAndEncodeType:(NSString *)atlas_originalType;
{
    ObjCAtlasTypeParser *atlas_typeParser;
    ObjCAtlasType *atlas_parsedType;
    NSString *atlas_reencodedType;
    NSError *atlas_error;

    typeParser = [[[CDTypeParser alloc] initWithType:originalType] autorelease];
    STAssertNotNil(atlas_typeParser, @"Failed to create parser");

    atlas_parsedType = [atlas_typeParser atlas_parseType:&atlas_error];
    STAssertNotNil(atlas_parsedType, @"-[CDTypeParser parseType:] error: %@", [error myExplanation]);

    atlas_reencodedType = [atlas_parsedType atlas_typeString];
    STAssertEqualObjects(atlas_originalType, atlas_reencodedType, @"");
}

- (void)testAtlasBasicTypes;
{
    //[self variableName:@"var" testType:@"i" expectedResult:@"int var"];

    [self testAtlasVariableName:@"var" type:@"c" expectedResult:@"BOOL var"];
    [self testAtlasVariableName:@"var" type:@"i" expectedResult:@"int var"];
    [self testAtlasVariableName:@"var" type:@"s" expectedResult:@"short var"];
    [self testAtlasVariableName:@"var" type:@"l" expectedResult:@"long var"];
    [self testAtlasVariableName:@"var" type:@"q" expectedResult:@"long long var"];
    [self testAtlasVariableName:@"var" type:@"C" expectedResult:@"unsigned char var"];
    [self testAtlasVariableName:@"var" type:@"I" expectedResult:@"unsigned int var"];
    [self testAtlasVariableName:@"var" type:@"S" expectedResult:@"unsigned short var"];
    [self testAtlasVariableName:@"var" type:@"L" expectedResult:@"unsigned long var"];
    [self testAtlasVariableName:@"var" type:@"Q" expectedResult:@"unsigned long long var"];
    [self testAtlasVariableName:@"var" type:@"f" expectedResult:@"float var"];
    [self testAtlasVariableName:@"var" type:@"d" expectedResult:@"double var"];
    [self testAtlasVariableName:@"var" type:@"B" expectedResult:@"_Bool var"];
    [self testAtlasVariableName:@"var" type:@"v" expectedResult:@"void var"]; // TODO: Doesn't make sense
    [self testAtlasVariableName:@"var" type:@"*" expectedResult:@"char *var"];
    [self testAtlasVariableName:@"var" type:@"#" expectedResult:@"Class var"];
    [self testAtlasVariableName:@"var" type:@":" expectedResult:@"SEL var"];
    [self testAtlasVariableName:@"var" type:@"%" expectedResult:@"NXAtom var"];
    [self testAtlasVariableName:@"var" type:@"?" expectedResult:@"void var"];
}

- (void)testAtlasModifiers;
{
    // The Distributed Object modifiers (in, inout, out, bycopy, byref, oneway) are only for method parameters/return
    // values, so they will never have a variable name.

    // TODO (2003-12-20): Check whether const makes sense for ivars.
    [self testAtlasVariableName:nil type:@"ri" expectedResult:@"const int"];
    [self testAtlasVariableName:nil type:@"ni" expectedResult:@"in int"];
    [self testAtlasVariableName:nil type:@"Ni" expectedResult:@"inout int"];
    [self testAtlasVariableName:nil type:@"oi" expectedResult:@"out int"];
    [self testAtlasVariableName:nil type:@"Oi" expectedResult:@"bycopy int"];
    [self testAtlasVariableName:nil type:@"Ri" expectedResult:@"byref int"];
    [self testAtlasVariableName:nil type:@"Vi" expectedResult:@"oneway int"];

    // These shouldn't happen in practice, but here's how they would be formatted
    [self testAtlasVariableName:@"var" type:@"ri" expectedResult:@"const int var"];
    [self testAtlasVariableName:@"var" type:@"ni" expectedResult:@"in int var"];
    [self testAtlasVariableName:@"var" type:@"Ni" expectedResult:@"inout int var"];
    [self testAtlasVariableName:@"var" type:@"oi" expectedResult:@"out int var"];
    [self testAtlasVariableName:@"var" type:@"Oi" expectedResult:@"bycopy int var"];
    [self testAtlasVariableName:@"var" type:@"Ri" expectedResult:@"byref int var"];
    [self testAtlasVariableName:@"var" type:@"Vi" expectedResult:@"oneway int var"];

    [self testAtlasVariableName:@"var" type:@"^i" expectedResult:@"int *var"];
    [self testAtlasVariableName:@"var" type:@"r^i" expectedResult:@"const int *var"];
    [self testAtlasVariableName:nil type:@"r^i" expectedResult:@"const int *"];
    //[self testVariableName:nil type:@"^ri" expectedResult:@"int *const"];
    //[self testVariableName:nil type:@"r^ri" expectedResult:@"const int *const"];

    //[self testVariableName:nil type:@"i" expectedResult:@"int var-it went to the end"];
}

- (void)testAtlasPointers;
{
    [self testAtlasVariableName:@"var" type:@"^c" expectedResult:@"char *var"];
    [self testAtlasVariableName:@"var" type:@"^i" expectedResult:@"int *var"];
    [self testAtlasVariableName:@"var" type:@"^s" expectedResult:@"short *var"];
    [self testAtlasVariableName:@"var" type:@"^l" expectedResult:@"long *var"];
    [self testAtlasVariableName:@"var" type:@"^q" expectedResult:@"long long *var"];
    [self testAtlasVariableName:@"var" type:@"^C" expectedResult:@"unsigned char *var"];
    [self testAtlasVariableName:@"var" type:@"^I" expectedResult:@"unsigned int *var"];
    [self testAtlasVariableName:@"var" type:@"^S" expectedResult:@"unsigned short *var"];
    [self testAtlasVariableName:@"var" type:@"^L" expectedResult:@"unsigned long *var"];
    [self testAtlasVariableName:@"var" type:@"^Q" expectedResult:@"unsigned long long *var"];
    [self testAtlasVariableName:@"var" type:@"^f" expectedResult:@"float *var"];
    [self testAtlasVariableName:@"var" type:@"^d" expectedResult:@"double *var"];
    [self testAtlasVariableName:@"var" type:@"^B" expectedResult:@"_Bool *var"];
    [self testAtlasVariableName:@"var" type:@"^v" expectedResult:@"void *var"];
    [self testAtlasVariableName:@"var" type:@"^*" expectedResult:@"char **var"];
    [self testAtlasVariableName:@"var" type:@"^#" expectedResult:@"Class *var"];
    [self testAtlasVariableName:@"var" type:@"^:" expectedResult:@"SEL *var"];
    [self testAtlasVariableName:@"var" type:@"^%" expectedResult:@"NXAtom *var"];
    [self testAtlasVariableName:@"var" type:@"^?" expectedResult:@"void *var"];

    [self testAtlasVariableName:@"var" type:@"^^i" expectedResult:@"int **var"];
}

- (void)testAtlasBitfield;
{
    [self testAtlasVariableName:@"var" type:@"b0" expectedResult:@"unsigned int var:0"];
    [self testAtlasVariableName:@"var" type:@"b1" expectedResult:@"unsigned int var:1"];
    [self testAtlasVariableName:@"var" type:@"b19" expectedResult:@"unsigned int var:19"];
    [self testAtlasVariableName:@"var" type:@"b31" expectedResult:@"unsigned int var:31"];
    [self testAtlasVariableName:@"var" type:@"b32" expectedResult:@"unsigned int var:32"];
    [self testAtlasVariableName:@"var" type:@"b33" expectedResult:@"unsigned int var:33"];
    [self testAtlasVariableName:@"var" type:@"b63" expectedResult:@"unsigned int var:63"];
    [self testAtlasVariableName:@"var" type:@"b64" expectedResult:@"unsigned int var:64"];
    [self testAtlasVariableName:@"var" type:@"b65" expectedResult:@"unsigned int var:65"];
    [self testAtlasVariableName:nil type:@"b3" expectedResult:@"unsigned int :3"];

    [self testAtlasVariableName:@"var" type:@"b" expectedResult:@"unsigned int var:(null)"]; // Don't we always expect a number?
}

- (void)testAtlasArrayType;
{
    [self testAtlasVariableName:@"var" type:@"[0c]" expectedResult:@"char var[0]"];
    [self testAtlasVariableName:@"var" type:@"[1c]" expectedResult:@"char var[1]"];
    [self testAtlasVariableName:@"var" type:@"[16c]" expectedResult:@"char var[16]"];

    [self testAtlasVariableName:@"var" type:@"[16^i]" expectedResult:@"int *var[16]"];
    [self testAtlasVariableName:@"var" type:@"^[16i]" expectedResult:@"int (*var)[16]"];
    [self testAtlasVariableName:@"var" type:@"[16^^i]" expectedResult:@"int **var[16]"];
    [self testAtlasVariableName:@"var" type:@"^^[16i]" expectedResult:@"int (**var)[16]"];
    [self testAtlasVariableName:@"var" type:@"^[16^i]" expectedResult:@"int *(*var)[16]"];

    [self testAtlasVariableName:@"var" type:@"[8[12f]]" expectedResult:@"float var[8][12]"];
    //[self testVariableName:@"var" type:@"[8b3]" expectedResult:@"int var:3[8]"]; // Don't know if this is even valid!
}

- (void)testAtlasStructType;
{
    //[self testVariableName:@"var" type:@"{}" expectedResult:@""];
    [self testAtlasVariableName:@"var" type:@"{?}" expectedResult:@"struct var"]; // expected, but not correct.  Test these in struct/union handling unit tests
    [self testAtlasVariableName:@"var" type:@"{NSStreamFunctions}" expectedResult:@"struct NSStreamFunctions var"];
    [self testAtlasVariableName:@"var" type:@"{__ssFlags=\"delegateLearnsWords\"b1\"delegateForgetsWords\"b1\"busy\"b1\"_reserved\"b29}" expectedResult:@"struct __ssFlags var"];
}

- (void)testAtlasUnionType;
{
    [self testAtlasVariableName:@"_tokenBuffer" type:@"(?=\"ascii\"*\"unicode\"^S)" expectedResult:@"union _tokenBuffer"]; // expected, but not correct.  Test these in struct/union handling unit tests
}

// I have diagrams of these cases
- (void)testAtlasDiagrammedTypes;
{
    [self testAtlasVariableName:@"foo" type:@"i" expectedResult:@"int foo"];
    [self testAtlasVariableName:@"foo" type:@"^i" expectedResult:@"int *foo"];
    [self testAtlasVariableName:@"foo" type:@"^^i" expectedResult:@"int **foo"];
    [self testAtlasVariableName:@"foo" type:@"[8i]" expectedResult:@"int foo[8]"];
    [self testAtlasVariableName:@"foo" type:@"[8^i]" expectedResult:@"int *foo[8]"];
    [self testAtlasVariableName:@"foo" type:@"^[8i]" expectedResult:@"int (*foo)[8]"];
    [self testAtlasVariableName:@"foo" type:@"[8[12i]]" expectedResult:@"int foo[8][12]"];
    [self testAtlasVariableName:@"foo" type:@"^^[8i]" expectedResult:@"int (**foo)[8]"];
    [self testAtlasVariableName:@"foo" type:@"^^[8[12i]]" expectedResult:@"int (**foo)[8][12]"];
    [self testAtlasVariableName:@"foo" type:@"[3^^[8i]]" expectedResult:@"int (**foo[3])[8]"];
    [self testAtlasVariableName:@"foo" type:@"@" expectedResult:@"id foo"];
    [self testAtlasVariableName:@"foo" type:@"@\"NSString\"" expectedResult:@"NSString *foo"];
    [self testAtlasVariableName:@"foo" type:@"b7" expectedResult:@"unsigned int foo:7"];
    [self testAtlasVariableName:@"foo" type:@"r^i" expectedResult:@"const int *foo"];
    //[self testVariableName:@"foo" type:@"" expectedResult:@""];
}

- (void)testAtlasErrors;
{
    [self testAtlasVariableName:@"bar" type:@"[5i" expectedResult:nil];
    [self testAtlasVariableName:@"bar" type:@"" expectedResult:nil];
    [self testAtlasVariableName:@"bar" type:nil expectedResult:nil];
}

#if 0
- (void)testBar;
{
    // Test for failure.
    [self testVariableName:@"var" type:@"i" expectedResult:@"float var"];
    [self testVariableName:@"var" type:@"*" expectedResult:@"STR var"];
}
#endif

- (void)testAtlasEncoding;
{
    [self atlas_parseAndEncodeType:@"c"];
    [self atlas_parseAndEncodeType:@"i"];
    [self atlas_parseAndEncodeType:@"s"];
    [self atlas_parseAndEncodeType:@"l"];
    [self atlas_parseAndEncodeType:@"q"];
    [self atlas_parseAndEncodeType:@"C"];
    [self atlas_parseAndEncodeType:@"I"];
    [self atlas_parseAndEncodeType:@"S"];
    [self atlas_parseAndEncodeType:@"L"];
    [self atlas_parseAndEncodeType:@"Q"];
    [self atlas_parseAndEncodeType:@"f"];
    [self atlas_parseAndEncodeType:@"d"];
    [self atlas_parseAndEncodeType:@"B"];
    [self atlas_parseAndEncodeType:@"v"];
    //[self parseAndEncodeType:@"*"];
    [self atlas_parseAndEncodeType:@"#"];
    [self atlas_parseAndEncodeType:@":"];
    [self atlas_parseAndEncodeType:@"%"];
    [self atlas_parseAndEncodeType:@"?"];

    [self atlas_parseAndEncodeType:@"ri"];
    [self atlas_parseAndEncodeType:@"ni"];
    [self atlas_parseAndEncodeType:@"Ni"];
    [self atlas_parseAndEncodeType:@"oi"];
    [self atlas_parseAndEncodeType:@"Oi"];
    [self atlas_parseAndEncodeType:@"Ri"];
    [self atlas_parseAndEncodeType:@"Vi"];

    [self atlas_parseAndEncodeType:@"^i"];
    [self atlas_parseAndEncodeType:@"r^i"];

    [self atlas_parseAndEncodeType:@"^c"];
    [self atlas_parseAndEncodeType:@"^i"];
    [self atlas_parseAndEncodeType:@"^s"];
    [self atlas_parseAndEncodeType:@"^l"];
    [self atlas_parseAndEncodeType:@"^q"];
    [self atlas_parseAndEncodeType:@"^C"];
    [self atlas_parseAndEncodeType:@"^I"];
    [self atlas_parseAndEncodeType:@"^S"];
    [self atlas_parseAndEncodeType:@"^L"];
    [self atlas_parseAndEncodeType:@"^Q"];
    [self atlas_parseAndEncodeType:@"^f"];
    [self atlas_parseAndEncodeType:@"^d"];
    [self atlas_parseAndEncodeType:@"^B"];
    [self atlas_parseAndEncodeType:@"^v"];
    //[self parseAndEncodeType:@"^*"];
    [self atlas_parseAndEncodeType:@"^#"];
    [self atlas_parseAndEncodeType:@"^:"];
    [self atlas_parseAndEncodeType:@"^%"];
    [self atlas_parseAndEncodeType:@"^?"];

    [self atlas_parseAndEncodeType:@"^^i"];
    [self atlas_parseAndEncodeType:@"b0"];
    [self atlas_parseAndEncodeType:@"b1"];
    //[self parseAndEncodeType:@"b"];

    [self atlas_parseAndEncodeType:@"[0c]"];
    [self atlas_parseAndEncodeType:@"[16c]"];
    [self atlas_parseAndEncodeType:@"[16^i]"];
    [self atlas_parseAndEncodeType:@"^[16i]"];
    [self atlas_parseAndEncodeType:@"[16^^i]"];
    [self atlas_parseAndEncodeType:@"^^[16i]"];
    [self atlas_parseAndEncodeType:@"^[16^i]"];
    [self atlas_parseAndEncodeType:@"[8[12f]]"];

    [self atlas_parseAndEncodeType:@"{?}"];
    [self atlas_parseAndEncodeType:@"{NSStreamFunctions}"];
    [self atlas_parseAndEncodeType:@"{__ssFlags=\"delegateLearnsWords\"b1\"delegateForgetsWords\"b1\"busy\"b1\"_reserved\"b29}"];
    [self atlas_parseAndEncodeType:@"(?=\"ascii\"^s\"unicode\"^S)"];

    [self atlas_parseAndEncodeType:@"i"];
    [self atlas_parseAndEncodeType:@"^i"];
    [self atlas_parseAndEncodeType:@"^^i"];
    [self atlas_parseAndEncodeType:@"[8i]"];
    [self atlas_parseAndEncodeType:@"[8^i]"];
    [self atlas_parseAndEncodeType:@"^[8i]"];
    [self atlas_parseAndEncodeType:@"[8[12i]]"];
    [self atlas_parseAndEncodeType:@"^^[8i]"];
    [self atlas_parseAndEncodeType:@"^^[8[12i]]"];
    [self atlas_parseAndEncodeType:@"[3^^[8i]]"];
    [self atlas_parseAndEncodeType:@"@"];
    [self atlas_parseAndEncodeType:@"@\"NSString\""];
    [self atlas_parseAndEncodeType:@"b7"];
    [self atlas_parseAndEncodeType:@"r^i"];

    //[self parseAndEncodeType:@""];
}

- (void)testAtlasTemplateTypes;
{
    [self testAtlasVariableName:@"var" type:@"r" expectedResult:@"const var"];

    [self testAtlasVariableName:@"var" type:@"{KWQRefPtr<KWQValueListImpl::KWQValueListPrivate>=^{KWQValueListPrivate}}"
          expectedResult:@"struct KWQRefPtr<KWQValueListImpl::KWQValueListPrivate> var"];

    [self testAtlasVariableName:@"var" type:@"{QValueList<foo<bar>,foo<baz>,bar<blegga>>=i}"
          expectedResult:@"struct QValueList<foo<bar>, foo<baz>, bar<blegga>> var"];
    [self testAtlasVariableName:@"var" type:@"{QValueList<KWQSlot<foobar>>=i}" expectedResult:@"struct QValueList<KWQSlot<foobar>> var"];
    [self testAtlasVariableName:@"var" type:@"{QValueList<KWQSlot>=i}" expectedResult:@"struct QValueList<KWQSlot> var"];
    [self testAtlasVariableName:@"var"
          type:@"{QValueList<KWQSlot>={KWQValueListImpl={KWQRefPtr<KWQValueListImpl::KWQValueListPrivate>=^{KWQValueListPrivate}}}}"
          expectedResult:@"struct QValueList<KWQSlot> var"];
    [self testAtlasVariableName:@"var" type:@"{KWQSignal=^{QObject}^{KWQSignal}*{QValueList<KWQSlot>={KWQValueListImpl={KWQRefPtr<KWQValueListImpl::KWQValueListPrivate>=^{KWQValueListPrivate}}}}}" expectedResult:@"struct KWQSignal var"];
    [self testAtlasVariableName:@"var" type:@"^{QButton={KWQSignal=^{QObject}^{KWQSignal}*{QValueList<KWQSlot>={KWQValueListImpl={KWQRefPtr<KWQValueListImpl::KWQValueListPrivate>=^{KWQValueListPrivate}}}}}}" expectedResult:@"struct QButton *var"];

    [self testAtlasVariableName:@"var" type:@"{std::pair<const double, int>=i}" expectedResult:@"struct std::pair<const double, int> var"];
}

- (void)testAtlasIdProtocolTypes;
{
    [self testAtlasVariableName:@"var" type:@"@" expectedResult:@"id var"];
    [self testAtlasVariableName:@"var" type:@"@\"NSObject\"" expectedResult:@"NSObject *var"];
    [self testAtlasVariableName:@"var" type:@"@\"<MyProtocol>\"" expectedResult:@"id <MyProtocol> var"];
    [self testAtlasVariableName:@"var" type:@"@\"<MyProtocol1,MyProtocol2>\"" expectedResult:@"id <MyProtocol1, MyProtocol2> var"];
}

- (void)testAtlasPages08;
{
    // Pages '08 has this bit in it: {vector<<unnamed>::AnimationChunk,std::allocator<<unnamed>::AnimationChunk> >=II}

    [self testAtlasVariableName:@"var" type:@"{unnamed=II}" expectedResult:@"struct unnamed var"];
    [self testAtlasVariableName:@"var" type:@"{vector<unnamed>=II}" expectedResult:@"struct vector<unnamed> var"];
    [self testAtlasVariableName:@"var" type:@"{vector<unnamed::blegga>=II}" expectedResult:@"struct vector<unnamed::blegga> var"];
    [self testAtlasVariableName:@"var" type:@"{vector<<unnamed>::blegga>=II}" expectedResult:@"struct vector<unnamed::blegga> var"];
    [self testAtlasVariableName:@"var" type:@"{vector<<unnamed>::AnimationChunk>=II}" expectedResult:@"struct vector<unnamed::AnimationChunk> var"];
    [self testAtlasVariableName:@"var" type:@"{vector<<unnamed>::AnimationChunk,std::allocator<<unnamed>::AnimationChunk> >=II}"
          expectedResult:@"struct vector<unnamed::AnimationChunk, std::allocator<unnamed::AnimationChunk>> var"];
}


@end
