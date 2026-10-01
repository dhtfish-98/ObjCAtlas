// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTypeFormatter.h"

#import "atlas_CDMethodType.h"
#import "atlas_CDType.h"
#import "atlas_CDTypeLexer.h"
#import "atlas_CDTypeParser.h"
#import "atlas_CDTypeController.h"

static BOOL atlas_debug = NO;

@interface ObjCAtlasTypeFormatter ()
@end

#pragma mark -

@implementation ObjCAtlasTypeFormatter
{
    __weak ObjCAtlasTypeController *atlas__typeController;
    
    NSUInteger atlas__baseLevel;
    
    BOOL atlas__shouldExpand; // But just top level struct, level == 0
    BOOL atlas__shouldAutoExpand;
    BOOL atlas__shouldShowLexing;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_typeController = atlas__typeController;
@synthesize atlas_baseLevel = atlas__baseLevel;
@synthesize atlas_shouldExpand = atlas__shouldExpand;
@synthesize atlas_shouldAutoExpand = atlas__shouldAutoExpand;
@synthesize atlas_shouldShowLexing = atlas__shouldShowLexing;

- (id)init;
{
    if ((self = [super init])) {
        atlas__typeController = nil;
        atlas__baseLevel = 0;
        atlas__shouldExpand = NO;
        atlas__shouldAutoExpand = NO;
        atlas__shouldShowLexing = atlas_debug;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> baseLevel: %lu, shouldExpand: %u, shouldAutoExpand: %u, shouldShowLexing: %u, tc: %p",
            NSStringFromClass([self class]), self,
            self.atlas_baseLevel, self.atlas_shouldExpand, self.atlas_shouldAutoExpand, self.atlas_shouldShowLexing, self.atlas_typeController];
}

#pragma mark -

- (NSString *)atlas__specialCaseVariable:(NSString *)atlas_name atlas_type:(NSString *)atlas_type;
{
    if ([atlas_type isEqual:@"c"]) {
        if (atlas_name == nil)
            return @"BOOL";
        else
            return [NSString stringWithFormat:@"BOOL %@", atlas_name];
#if 0
    } else if ([type isEqual:@"b1"]) {
        if (name == nil)
            return @"BOOL :1";
        else
            return [NSString stringWithFormat:@"BOOL %@:1", name];
#endif
    }

    return nil;
}

- (NSString *)atlas__specialCaseVariable:(NSString *)atlas_name atlas_parsedType:(ObjCAtlasType *)atlas_type;
{
    if (atlas_type.atlas_primitiveType == 'c') {
        if (atlas_name == nil)
            return @"BOOL";
        else
            return [NSString stringWithFormat:@"BOOL %@", atlas_name];
    }

    return nil;
}

- (NSString *)atlas_formatVariable:(NSString *)atlas_name atlas_type:(ObjCAtlasType *)atlas_type;
{
    NSMutableString *atlas_resultString = [NSMutableString string];

    NSString *atlas_specialCase = [self atlas__specialCaseVariable:atlas_name atlas_parsedType:atlas_type];
    [atlas_resultString atlas_appendSpacesIndentedToLevel:self.atlas_baseLevel atlas_spacesPerLevel:4];
    if (atlas_specialCase != nil) {
        [atlas_resultString appendString:atlas_specialCase];
    } else {
        // TODO: (2009-08-26) Ideally, just formatting a type shouldn't change it.  These changes should be done before, but this is handy.
        atlas_type.atlas_variableName = atlas_name;
        [atlas_type atlas_phase0RecursivelyFixStructureNames:NO]; // Nuke the $_ names
        [atlas_type atlas_phase3MergeWithTypeController:self.atlas_typeController];
        [atlas_resultString appendString:[atlas_type atlas_formattedString:nil atlas_formatter:self atlas_level:0]];
    }

    return atlas_resultString;
}

- (NSDictionary *)atlas_formattedTypesForMethodName:(NSString *)atlas_name atlas_type:(NSString *)atlas_type;
{
    ObjCAtlasTypeParser *atlas_parser = [[ObjCAtlasTypeParser alloc] initWithString:atlas_type];

    NSError *atlas_error = nil;
    NSArray *atlas_methodTypes = [atlas_parser atlas_parseMethodType:&atlas_error];
    if (atlas_methodTypes == nil)
        NSLog(@"Warning: Parsing method types failed, %@", atlas_name);

    if (atlas_methodTypes == nil || [atlas_methodTypes count] == 0) {
        return nil;
    }

    NSMutableDictionary *atlas_typeDict = [NSMutableDictionary dictionary];
    {
        NSUInteger atlas_count = [atlas_methodTypes count];
        NSUInteger atlas_index = 0;
        BOOL atlas_noMoreTypes = NO;

        ObjCAtlasMethodType *atlas_methodType = atlas_methodTypes[atlas_index];
        NSString *atlas_specialCase = [self atlas__specialCaseVariable:nil atlas_type:atlas_methodType.type.atlas_bareTypeString];
        if (atlas_specialCase != nil) {
            [atlas_typeDict setValue:atlas_specialCase forKey:@"return-type"];
        } else {
            NSString *atlas_str = [[atlas_methodType type] atlas_formattedString:nil atlas_formatter:self atlas_level:0];
            if (atlas_str != nil)
                [atlas_typeDict setValue:atlas_str forKey:@"return-type"];
        }

        atlas_index += 3;

        NSMutableArray *atlas_parameterTypes = [NSMutableArray array];
        [atlas_typeDict setValue:atlas_parameterTypes forKey:@"parametertypes"];

        NSScanner *atlas_scanner = [[NSScanner alloc] initWithString:atlas_name];
        while ([atlas_scanner isAtEnd] == NO) {
            NSString *atlas_str;

            // We can have unnamed parameters, :::
            if ([atlas_scanner scanUpToString:@":" intoString:&atlas_str]) {
                //NSLog(@"str += '%@'", str);
//				int unnamedCount, unnamedIndex;
//				unnamedCount = [str length];
//				for (unnamedIndex = 0; unnamedIndex < unnamedCount; unnamedIndex++)
//					[parameterTypes addObject:@{ @"type": @"", @"name": @""}];
            }
            if ([atlas_scanner scanString:@":" intoString:NULL]) {
                if (atlas_index >= atlas_count) {
                    atlas_noMoreTypes = YES;
                } else {
                    NSMutableDictionary *atlas_parameter = [NSMutableDictionary dictionary];

                    atlas_methodType = atlas_methodTypes[atlas_index];
                    atlas_specialCase = [self atlas__specialCaseVariable:nil atlas_type:atlas_methodType.type.atlas_bareTypeString];
                    if (atlas_specialCase != nil) {
                        [atlas_parameter setValue:atlas_specialCase forKey:@"type"];
                    } else {
                        NSString *atlas_typeString = [atlas_methodType.type atlas_formattedString:nil atlas_formatter:self atlas_level:0];
                        [atlas_parameter setValue:atlas_typeString forKey:@"type"];
                    }
                    //[parameter setValue:[NSString stringWithFormat:@"fp%@", methodType.offset] forKey:@"name"];
                    [atlas_parameter setValue:[NSString stringWithFormat:@"arg%lu", atlas_index-2] forKey:@"name"];
                    [atlas_parameterTypes addObject:atlas_parameter];
                    atlas_index++;
                }
            }
        }

        if (atlas_noMoreTypes) {
            NSLog(@" /* Error: Ran out of types for this method. */");
        }
    }

    return atlas_typeDict;
}

- (NSString *)atlas_formatMethodName:(NSString *)atlas_methodName atlas_typeString:(NSString *)atlas_typeString;
{
    ObjCAtlasTypeParser *atlas_parser = [[ObjCAtlasTypeParser alloc] initWithString:atlas_typeString];

    NSError *atlas_error = nil;
    NSArray *atlas_methodTypes = [atlas_parser atlas_parseMethodType:&atlas_error];
    if (atlas_methodTypes == nil)
        NSLog(@"Warning: Parsing method types failed, %@", atlas_methodName);

    if (atlas_methodTypes == nil || [atlas_methodTypes count] == 0) {
        return nil;
    }

    NSMutableString *atlas_resultString = [NSMutableString string];
    {
        NSUInteger atlas_count = [atlas_methodTypes count];
        NSUInteger atlas_index = 0;
        BOOL atlas_noMoreTypes = NO;

        ObjCAtlasMethodType *atlas_methodType = atlas_methodTypes[atlas_index];
        [atlas_resultString appendString:@"("];
        NSString *atlas_specialCase = [self atlas__specialCaseVariable:nil atlas_type:atlas_methodType.type.atlas_bareTypeString];
        if (atlas_specialCase != nil) {
            [atlas_resultString appendString:atlas_specialCase];
        } else {
            NSString *atlas_str = [atlas_methodType.type atlas_formattedString:nil atlas_formatter:self atlas_level:0];
            if (atlas_str != nil)
                [atlas_resultString appendFormat:@"%@", atlas_str];
        }
        [atlas_resultString appendString:@")"];

        atlas_index += 3;

        NSScanner *atlas_scanner = [[NSScanner alloc] initWithString:atlas_methodName];
        while ([atlas_scanner isAtEnd] == NO) {
            NSString *atlas_str;

            // We can have unnamed paramenters, :::
            if ([atlas_scanner scanUpToString:@":" intoString:&atlas_str]) {
                //NSLog(@"str += '%@'", str);
                [atlas_resultString appendString:atlas_str];
            }
            if ([atlas_scanner scanString:@":" intoString:NULL]) {
                [atlas_resultString appendString:@":"];
                if (atlas_index >= atlas_count) {
                    atlas_noMoreTypes = YES;
                } else {
                    atlas_methodType = atlas_methodTypes[atlas_index];
                    atlas_specialCase = [self atlas__specialCaseVariable:nil atlas_type:atlas_methodType.type.atlas_bareTypeString];
                    if (atlas_specialCase != nil) {
                        [atlas_resultString appendFormat:@"(%@)", atlas_specialCase];
                    } else {
                        NSString *atlas_formattedType = [atlas_methodType.type atlas_formattedString:nil atlas_formatter:self atlas_level:0];
                        //if ([[methodType type] isIDType] == NO)
                        [atlas_resultString appendFormat:@"(%@)", atlas_formattedType];
                    }
                    //[resultString appendFormat:@"fp%@", [methodType offset]];
                    [atlas_resultString appendFormat:@"arg%lu", atlas_index-2];

                    NSString *atlas_ch = [atlas_scanner atlas_peekCharacter];
                    // if next character is not ':' nor EOS then add space
                    if (atlas_ch != nil && [atlas_ch isEqual:@":"] == NO)
                        [atlas_resultString appendString:@" "];
                    atlas_index++;
                }
            }
        }

        if (atlas_noMoreTypes) {
            [atlas_resultString appendString:@" /* Error: Ran out of types for this method. */"];
        }
    }

    return atlas_resultString;
}

// Called from CDType, which gets a formatter but not a type controller.
- (ObjCAtlasType *)atlas_replacementForType:(ObjCAtlasType *)atlas_type;
{
    return [self.atlas_typeController atlas_typeFormatter:self atlas_replacementForType:atlas_type];
}

// Called from CDType, which gets a formatter but not a type controller.
- (NSString *)atlas_typedefNameForStructure:(ObjCAtlasType *)atlas_structureType atlas_level:(NSUInteger)atlas_level;
{
    return [self.atlas_typeController atlas_typeFormatter:self atlas_typedefNameForStructure:atlas_structureType atlas_level:atlas_level];
}

- (void)atlas_formattingDidReferenceClassName:(NSString *)atlas_name;
{
    [self.atlas_typeController atlas_typeFormatter:self atlas_didReferenceClassName:atlas_name];
}

- (void)atlas_formattingDidReferenceProtocolNames:(NSArray *)atlas_names;
{
    [self.atlas_typeController atlas_typeFormatter:self atlas_didReferenceProtocolNames:atlas_names];
}

@end
