// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTypeParser.h"

#import "atlas_CDMethodType.h"
#import "atlas_CDType.h"
#import "atlas_CDTypeName.h"
#import "atlas_CDTypeLexer.h"

NSString *atlas_CDExceptionName_SyntaxError         = @"CDExceptionName_SyntaxError";

NSString *atlas_CDErrorDomain_TypeParser            = @"CDErrorDomain_TypeParser";

NSString *atlas_CDErrorKey_Type                     = @"CDErrorKey_Type";
NSString *atlas_CDErrorKey_RemainingString          = @"CDErrorKey_RemainingString";
NSString *atlas_CDErrorKey_MethodOrVariable         = @"CDErrorKey_MethodOrVariable";
NSString *atlas_CDErrorKey_LocalizedLongDescription = @"CDErrorKey_LocalizedLongDescription";

static BOOL atlas_debug = NO;

static NSString *atlas_CDTokenDescription(int atlas_token)
{
    if (atlas_token < 128)
        return [NSString stringWithFormat:@"%d(%c)", atlas_token, atlas_token];

    return [NSString stringWithFormat:@"%d", atlas_token];
}

@interface ObjCAtlasTypeParser ()
@end

#pragma mark -

@implementation ObjCAtlasTypeParser
{
    ObjCAtlasTypeLexer *atlas__lexer;
    int atlas__lookahead;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_lexer = atlas__lexer;

- (id)initWithString:(NSString *)atlas_string;
{
    if ((self = [super init])) {
        // Do some preprocessing first: Replace "<unnamed>::" with just "unnamed::".
        NSMutableString *atlas_str = [atlas_string mutableCopy];
        [atlas_str replaceOccurrencesOfString:@"<unnamed>::" withString:@"unnamed::" options:(NSStringCompareOptions)0 range:NSMakeRange(0, [atlas_string length])];
        
        atlas__lexer = [[ObjCAtlasTypeLexer alloc] initWithString:atlas_str];
        atlas__lookahead = 0;
    }

    return self;
}

#pragma mark -

- (NSArray *)atlas_parseMethodType:(NSError *__autoreleasing *)atlas_error;
{
    NSArray *atlas_result;

    @try {
        atlas__lookahead = [self.atlas_lexer atlas_scanNextToken];
        atlas_result = [self atlas__parseMethodType];
    }
    @catch (NSException *exception) {
        if (atlas_error != NULL) {
            NSMutableDictionary *atlas_userInfo = [NSMutableDictionary dictionary];
            NSString *atlas_localDesc = [NSString stringWithFormat:@"%@:\n\t     type: %@\n\tremaining: %@", [exception reason], self.atlas_lexer.string, self.atlas_lexer.atlas_remainingString];            

            atlas_userInfo[atlas_CDErrorKey_Type]                     = self.atlas_lexer.string;
            atlas_userInfo[atlas_CDErrorKey_RemainingString]          = self.atlas_lexer.atlas_remainingString;
            atlas_userInfo[atlas_CDErrorKey_MethodOrVariable]         = @"method";
            atlas_userInfo[atlas_CDErrorKey_LocalizedLongDescription] = atlas_localDesc;
            
            NSInteger atlas_code;
            if ([exception name] == atlas_CDExceptionName_SyntaxError) {
                atlas_code = atlas_CDTypeParserCode_SyntaxError;
                atlas_userInfo[NSLocalizedDescriptionKey]        = @"Syntax Error";
                atlas_userInfo[NSLocalizedFailureReasonErrorKey] = [exception reason];
            } else {
                atlas_code = atlas_CDTypeParserCode_Default;
                atlas_userInfo[NSLocalizedFailureReasonErrorKey] = [exception reason];
            }
            *atlas_error = [NSError errorWithDomain:atlas_CDErrorDomain_TypeParser code:atlas_code userInfo:atlas_userInfo];
        }

        atlas_result = nil;
    }

    return atlas_result;
}

- (ObjCAtlasType *)atlas_parseType:(NSError *__autoreleasing *)atlas_error;
{
    ObjCAtlasType *atlas_result;

    @try {
        atlas__lookahead = [self.atlas_lexer atlas_scanNextToken];
        atlas_result = [self atlas__parseType];
    }
    @catch (NSException *exception) {
        if (atlas_error != NULL) {
            NSMutableDictionary *atlas_userInfo = [NSMutableDictionary dictionary];
            NSString *atlas_localDesc = [NSString stringWithFormat:@"%@:\n\t     type: %@\n\tremaining: %@", [exception reason], self.atlas_lexer.string, self.atlas_lexer.atlas_remainingString];
            
            atlas_userInfo[atlas_CDErrorKey_Type]                     = self.atlas_lexer.string;
            atlas_userInfo[atlas_CDErrorKey_RemainingString]          = self.atlas_lexer.atlas_remainingString;
            atlas_userInfo[atlas_CDErrorKey_MethodOrVariable]         = @"variable";
            atlas_userInfo[atlas_CDErrorKey_LocalizedLongDescription] = atlas_localDesc;
            
            NSInteger atlas_code;
            if ([exception name] == atlas_CDExceptionName_SyntaxError) {
                atlas_code = atlas_CDTypeParserCode_SyntaxError;
                atlas_userInfo[NSLocalizedDescriptionKey]        = @"Syntax Error";
                atlas_userInfo[NSLocalizedFailureReasonErrorKey] = [exception reason];
            } else {
                atlas_code = atlas_CDTypeParserCode_Default;
                atlas_userInfo[NSLocalizedFailureReasonErrorKey] = [exception reason];
            }
            *atlas_error = [NSError errorWithDomain:atlas_CDErrorDomain_TypeParser code:atlas_code userInfo:atlas_userInfo];
        }

        atlas_result = nil;
    }

    return atlas_result;
}

#pragma mark - Private methods

- (void)atlas_match:(int)atlas_token;
{
    [self atlas_match:atlas_token atlas_enterState:self.atlas_lexer.state];
}

- (void)atlas_match:(int)atlas_token atlas_enterState:(atlas_CDTypeLexerState)atlas_newState;
{
    if (atlas__lookahead == atlas_token) {
        if (atlas_debug) NSLog(@"matched %@", atlas_CDTokenDescription(atlas_token));
        self.atlas_lexer.state = atlas_newState;
        atlas__lookahead = [self.atlas_lexer atlas_scanNextToken];
    } else {
        [NSException raise:atlas_CDExceptionName_SyntaxError format:@"expected token %@, got %@",
                     atlas_CDTokenDescription(atlas_token),
                     atlas_CDTokenDescription(atlas__lookahead)];
    }
}

- (void)atlas_error:(NSString *)atlas_errorString;
{
    [NSException raise:atlas_CDExceptionName_SyntaxError format:@"%@", atlas_errorString];
}

- (NSArray *)atlas__parseMethodType;
{
    NSMutableArray *atlas_methodTypes = [NSMutableArray array];

    // Has to have at least one pair for the return type;
    // Probably needs at least two more, for object and selector
    // So it must be <type><number><type><number><type><number>.  Three pairs at a minimum.

    do {
        ObjCAtlasType *atlas_type = [self atlas__parseType];
        NSString *atlas_number = [self atlas_parseNumber];

        ObjCAtlasMethodType *atlas_methodType = [[ObjCAtlasMethodType alloc] initAtlasWithType:atlas_type atlas_offset:atlas_number];
        [atlas_methodTypes addObject:atlas_methodType];
    } while ([self atlas_isTokenInTypeStartSet:atlas__lookahead]);

    return atlas_methodTypes;
}

// Plain object types can be:
//     @                     - plain id type
//     @"NSObject"           - NSObject *
//     @"<MyProtocol>"       - id <MyProtocol>
// But these can also be part of a structure, with the field name in quotes before the type:
//     "foo"i"bar"i                - int foo, int bar
//     "foo"@"bar"i                - id foo, int bar
//     "foo"@"Foo""bar"i           - Foo *foo, int bar
// So this is where we need to be careful.
//
// I'm going to make a simplifying assumption:  Either the structure/union has member names,
// or is doesn't, it can't have some names and be missing others.
// The two key tests are:
//     {my_struct3="field1"@"field2"i}
//     {my_struct4="field1"@"NSObject""field2"i}

- (ObjCAtlasType *)atlas__parseType;
{
    return [self atlas__parseTypeInStruct:NO];
}

- (ObjCAtlasType *)atlas__parseTypeInStruct:(BOOL)atlas_isInStruct;
{
    ObjCAtlasType *atlas_result;

    if (atlas__lookahead == 'j'
        || atlas__lookahead == 'r'
        || atlas__lookahead == 'n'
        || atlas__lookahead == 'N'
        || atlas__lookahead == 'o'
        || atlas__lookahead == 'O'
        || atlas__lookahead == 'R'
        || atlas__lookahead == 'V'
        || atlas__lookahead == 'A') { // modifiers
        int atlas_modifier = atlas__lookahead;
        [self atlas_match:atlas_modifier];

        ObjCAtlasType *atlas_unmodifiedType;
        if ([self atlas_isTokenInTypeStartSet:atlas__lookahead])
            atlas_unmodifiedType = [self atlas__parseTypeInStruct:atlas_isInStruct];
        else
            atlas_unmodifiedType = nil;
        atlas_result = [[ObjCAtlasType alloc] initAtlasModifier:atlas_modifier atlas_type:atlas_unmodifiedType];
    } else if (atlas__lookahead == '^') { // pointer
        ObjCAtlasType *atlas_type;

        [self atlas_match:'^'];
        if (atlas__lookahead == atlas_TK_QUOTED_STRING || atlas__lookahead == '}' || atlas__lookahead == ')') {
            atlas_type = [[ObjCAtlasType alloc] initAtlasSimpleType:'v'];
            // Safari on 10.5 has: "m_function"{?="__pfn"^"__delta"i}
            atlas_result = [[ObjCAtlasType alloc] initAtlasPointerType:atlas_type];
        } else if (atlas__lookahead == '?') {
            [self atlas_match:'?'];
            atlas_result = [[ObjCAtlasType alloc] initAtlasFunctionPointerType];
        } else {
            atlas_type = [self atlas__parseTypeInStruct:atlas_isInStruct];
            atlas_result = [[ObjCAtlasType alloc] initAtlasPointerType:atlas_type];
        }
    } else if (atlas__lookahead == 'b') { // bitfield
        [self atlas_match:'b'];
        NSString *atlas_number = [self atlas_parseNumber];
        atlas_result = [[ObjCAtlasType alloc] initAtlasBitfieldType:atlas_number];
    } else if (atlas__lookahead == '@') { // id
        [self atlas_match:'@'];
#if 0
        if (lookahead == atlas_TK_QUOTED_STRING) {
            NSLog(@"%s, quoted string ahead, shouldCheckFieldNames: %d, end: %d",
                  atlas___cmd, shouldCheckFieldNames, [lexer.scanner isAtEnd]);
            if ([lexer.scanner isAtEnd] == NO)
                NSLog(@"next character: %d (%c), isInTypeStartSet: %d", lexer.peekChar, lexer.peekChar, [self isTokenInTypeStartSet:lexer.peekChar]);
        }
#endif
        if (atlas__lookahead == atlas_TK_QUOTED_STRING && (atlas_isInStruct == NO || [self.atlas_lexer.atlas_lexText atlas_isFirstLetterUppercase] || [self atlas_isTokenInTypeStartSet:self.atlas_lexer.atlas_peekChar] == NO)) {
            NSString *atlas_str = self.atlas_lexer.atlas_lexText;
            
            NSUInteger atlas_protocolOpenIdx = NSMaxRange([atlas_str rangeOfString:@"<"]);
            NSUInteger atlas_protocolCloseIdx = [atlas_str rangeOfString:@">" options:NSBackwardsSearch].location;
            if (atlas_protocolOpenIdx != NSNotFound && atlas_protocolCloseIdx != NSNotFound) {
                NSRange atlas_protocolRange = NSMakeRange(atlas_protocolOpenIdx, atlas_protocolCloseIdx - atlas_protocolOpenIdx);
                NSArray *atlas_protocols = [[atlas_str substringWithRange:atlas_protocolRange] componentsSeparatedByString:@","];
                
                NSString *atlas_typeNameStr = [[atlas_str substringToIndex:(atlas_protocolOpenIdx - 1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                ObjCAtlasTypeName *atlas_typeName = nil;
                if ([atlas_typeNameStr length] && ![atlas_typeNameStr isEqualToString:@"id"]) {
                    atlas_typeName = [[ObjCAtlasTypeName alloc] init];
                    atlas_typeName.name = atlas_typeNameStr;
                }
                
                atlas_result = [[ObjCAtlasType alloc] initAtlasIDType:atlas_typeName atlas_withProtocols:atlas_protocols];
            } else {
                ObjCAtlasTypeName *atlas_typeName = [[ObjCAtlasTypeName alloc] init];
                atlas_typeName.name = atlas_str;
                atlas_result = [[ObjCAtlasType alloc] initAtlasIDType:atlas_typeName];
            }

            [self atlas_match:atlas_TK_QUOTED_STRING];
        } else if (atlas__lookahead == '?') {
            [self atlas_match:'?'];
            NSArray *atlas_blockTypes = nil;
            if (atlas__lookahead == '<') {
                [self atlas_match:'<'];
                atlas_blockTypes = [[self atlas__parseMethodType] valueForKeyPath:@"type"];
                [self atlas_match:'>'];
            }
            atlas_result = [[ObjCAtlasType alloc] initAtlasBlockTypeWithTypes:atlas_blockTypes];
        } else {
            atlas_result = [[ObjCAtlasType alloc] initAtlasIDType:nil];
        }
    } else if (atlas__lookahead == '{') { // structure
        atlas_CDTypeLexerState atlas_savedState = self.atlas_lexer.state;
        [self atlas_match:'{' atlas_enterState:atlas_CDTypeLexerState_Identifier];
        ObjCAtlasTypeName *atlas_typeName = [self atlas_parseTypeName];
        NSArray *atlas_optionalMembers = [self atlas_parseOptionalMembers];
        [self atlas_match:'}' atlas_enterState:atlas_savedState];

        atlas_result = [[ObjCAtlasType alloc] initAtlasStructType:atlas_typeName atlas_members:atlas_optionalMembers];
    } else if (atlas__lookahead == '(') { // union
        atlas_CDTypeLexerState atlas_savedState = self.atlas_lexer.state;
        [self atlas_match:'(' atlas_enterState:atlas_CDTypeLexerState_Identifier];
        if (atlas__lookahead == atlas_TK_IDENTIFIER) {
            ObjCAtlasTypeName *atlas_typeName = [self atlas_parseTypeName];
            NSArray *atlas_optionalMembers = [self atlas_parseOptionalMembers];
            [self atlas_match:')' atlas_enterState:atlas_savedState];

            atlas_result = [[ObjCAtlasType alloc] initAtlasUnionType:atlas_typeName atlas_members:atlas_optionalMembers];
        } else {
            NSArray *atlas_unionTypes = [self atlas_parseUnionTypes];
            [self atlas_match:')' atlas_enterState:atlas_savedState];

            atlas_result = [[ObjCAtlasType alloc] initAtlasUnionType:nil atlas_members:atlas_unionTypes];
        }
    } else if (atlas__lookahead == '[') { // array
        [self atlas_match:'['];
        NSString *atlas_number = [self atlas_parseNumber];
        ObjCAtlasType *atlas_type = [self atlas__parseType];
        [self atlas_match:']'];

        atlas_result = [[ObjCAtlasType alloc] initAtlasArrayType:atlas_type atlas_count:atlas_number];
    } else if ([self atlas_isTokenInSimpleTypeSet:atlas__lookahead]) { // simple type
        int atlas_simpleType = atlas__lookahead;
        [self atlas_match:atlas_simpleType];
        atlas_result = [[ObjCAtlasType alloc] initAtlasSimpleType:atlas_simpleType];
    } else {
        ObjCAtlasTypeName *atlas_typeName = [[ObjCAtlasTypeName alloc] init];
        atlas_typeName.name = @"MISSING_TYPE";
        atlas_result = [[ObjCAtlasType alloc] initAtlasIDType:atlas_typeName];
//        result = nil;
//        [NSException raise:CDExceptionName_SyntaxError format:@"expected (many things), got %@", CDTokenDescription(_lookahead)];
    }

    return atlas_result;
}

// This seems to be used in method types -- no names
- (NSArray *)atlas_parseUnionTypes;
{
    NSMutableArray *atlas_members = [NSMutableArray array];

    while ([self atlas_isTokenInTypeSet:atlas__lookahead]) {
        ObjCAtlasType *atlas_type = [self atlas__parseType];
        //type.variableName = @"___";
        [atlas_members addObject:atlas_type];
    }

    return atlas_members;
}

- (NSArray *)atlas_parseOptionalMembers;
{
    NSArray *atlas_result;

    if (atlas__lookahead == '=') {
        [self atlas_match:'='];
        atlas_result = [self atlas_parseMemberList];
    } else
        atlas_result = nil;

    return atlas_result;
}

- (NSArray *)atlas_parseMemberList;
{
    //NSLog(@" > %s", __cmd);

    NSMutableArray *atlas_result = [NSMutableArray array];

    while (atlas__lookahead == atlas_TK_QUOTED_STRING || [self atlas_isTokenInTypeSet:atlas__lookahead])
        [atlas_result addObject:[self atlas_parseMember]];

    //NSLog(@"<  %s", __cmd);

    return atlas_result;
}

- (ObjCAtlasType *)atlas_parseMember;
{
    ObjCAtlasType *atlas_result;

    //NSLog(@" > %s", __cmd);

    if (atlas__lookahead == atlas_TK_QUOTED_STRING) {
        NSString *atlas_identifier = nil;

        while (atlas__lookahead == atlas_TK_QUOTED_STRING) {
            if (atlas_identifier == nil)
                atlas_identifier = self.atlas_lexer.atlas_lexText;
            else {
                // TextMate 1.5.4 has structures like... "storage""stack"{etc} -- two quoted strings next to each other.
                atlas_identifier = [NSString stringWithFormat:@"%@__%@", atlas_identifier, self.atlas_lexer.atlas_lexText];
            }
            [self atlas_match:atlas_TK_QUOTED_STRING];
        }

        //NSLog(@"got identifier: %@", identifier);
        atlas_result = [self atlas__parseTypeInStruct:YES];
        atlas_result.atlas_variableName = atlas_identifier;
        //NSLog(@"And parsed struct type.");
    } else {
        atlas_result = [self atlas__parseTypeInStruct:YES];
    }

    //NSLog(@"<  %s", __cmd);
    return atlas_result;
}

- (ObjCAtlasTypeName *)atlas_parseTypeName;
{
    ObjCAtlasTypeName *atlas_typeName = [[ObjCAtlasTypeName alloc] init];
    [atlas_typeName setName:[self atlas_parseIdentifier]];

    if (atlas__lookahead == '<') {
        atlas_CDTypeLexerState atlas_savedState = self.atlas_lexer.state;
        [self atlas_match:'<' atlas_enterState:atlas_CDTypeLexerState_TemplateTypes];
        [atlas_typeName.atlas_templateTypes addObject:[self atlas_parseTypeName]];
        while (atlas__lookahead == ',') {
            [self atlas_match:','];
            [atlas_typeName.atlas_templateTypes addObject:[self atlas_parseTypeName]];
        }
        [self atlas_match:'>' atlas_enterState:atlas_savedState];

        if (self.atlas_lexer.state == atlas_CDTypeLexerState_TemplateTypes) {
            if (atlas__lookahead == atlas_TK_IDENTIFIER) {
                NSString *atlas_suffix = self.atlas_lexer.atlas_lexText;

                [self atlas_match:atlas_TK_IDENTIFIER];
                [atlas_typeName setAtlas_suffix:atlas_suffix];
            }
        }
    }

#if 0
    // This breaks a bunch of the unit tests... need to figure out what's up with that first.
    // We'll treat "?" as no name, returning nil here instead of testing the type name for this later.
    if ([[typeName name] isEqualToString:@"?"] && [typeName isTemplateType] == NO)
        typeName = nil;
#endif

    return atlas_typeName;
}

- (NSString *)atlas_parseIdentifier;
{
    NSString *atlas_result = nil;

    if (atlas__lookahead == atlas_TK_IDENTIFIER) {
        atlas_result = self.atlas_lexer.atlas_lexText;
        [self atlas_match:atlas_TK_IDENTIFIER];
    }

    return atlas_result;
}

- (NSString *)atlas_parseNumber;
{
    if (atlas__lookahead == atlas_TK_NUMBER) {
        NSString *atlas_result = self.atlas_lexer.atlas_lexText;
        [self atlas_match:atlas_TK_NUMBER];
        return atlas_result;
    }

    return nil;
}

- (BOOL)atlas_isTokenInModifierSet:(int)atlas_token;
{
    if (atlas_token == 'j'
        || atlas_token == 'r'
        || atlas_token == 'n'
        || atlas_token == 'N'
        || atlas_token == 'o'
        || atlas_token == 'O'
        || atlas_token == 'R'
        || atlas_token == 'V'
        || atlas_token == 'A')
        return YES;

    return NO;
}

- (BOOL)atlas_isTokenInSimpleTypeSet:(int)atlas_token;
{
    if (atlas_token == 'c'
        || atlas_token == 'i'
        || atlas_token == 's'
        || atlas_token == 'l'
        || atlas_token == 'q'
        || atlas_token == 'C'
        || atlas_token == 'I'
        || atlas_token == 'S'
        || atlas_token == 'L'
        || atlas_token == 'Q'
        || atlas_token == 'f'
        || atlas_token == 'd'
        || atlas_token == 'D'
        || atlas_token == 'B'
        || atlas_token == 'v'
        || atlas_token == '*'
        || atlas_token == '#'
        || atlas_token == ':'
        || atlas_token == '%'
        || atlas_token == '?')
        return YES;

    return NO;
}

- (BOOL)atlas_isTokenInTypeSet:(int)atlas_token;
{
    if ([self atlas_isTokenInModifierSet:atlas_token]
        || [self atlas_isTokenInSimpleTypeSet:atlas_token]
        || atlas_token == '^'
        || atlas_token == 'b'
        || atlas_token == '@'
        || atlas_token == '{'
        || atlas_token == '('
        || atlas_token == '[')
        return YES;

    return NO;
}

- (BOOL)atlas_isTokenInTypeStartSet:(int)atlas_token;
{
    if (atlas_token == 'r'
        || atlas_token == 'n'
        || atlas_token == 'N'
        || atlas_token == 'o'
        || atlas_token == 'O'
        || atlas_token == 'R'
        || atlas_token == 'V'
        || atlas_token == 'A'
        || atlas_token == '^'
        || atlas_token == 'b'
        || atlas_token == '@'
        || atlas_token == '{'
        || atlas_token == '('
        || atlas_token == '['
        || [self atlas_isTokenInSimpleTypeSet:atlas_token])
        return YES;

    return NO;
}

@end
