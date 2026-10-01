// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_NSScanner_CDExtensions.h"

@implementation NSScanner (CDExtensions)

// other: $_:*
// start: alpha + other
// remainder: alnum + other

+ (NSCharacterSet *)atlas_cdOtherCharacterSet;
{
    static NSCharacterSet *atlas_otherCharacterSet = nil;

    if (atlas_otherCharacterSet == nil)
        atlas_otherCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"$_:*"];

    return atlas_otherCharacterSet;
}

+ (NSCharacterSet *)atlas_cdIdentifierStartCharacterSet;
{
    static NSCharacterSet *atlas_identifierStartCharacterSet = nil;

    if (atlas_identifierStartCharacterSet == nil) {
        NSMutableCharacterSet *atlas_set = [[NSCharacterSet letterCharacterSet] mutableCopy];
        [atlas_set formUnionWithCharacterSet:[NSScanner atlas_cdOtherCharacterSet]];
        atlas_identifierStartCharacterSet = [atlas_set copy];
    }

    return atlas_identifierStartCharacterSet;
}

+ (NSCharacterSet *)atlas_cdIdentifierCharacterSet;
{
    static NSCharacterSet *atlas_identifierCharacterSet = nil;

    if (atlas_identifierCharacterSet == nil) {
        NSMutableCharacterSet *atlas_set = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [atlas_set formUnionWithCharacterSet:[NSScanner atlas_cdOtherCharacterSet]];
        atlas_identifierCharacterSet = [atlas_set copy];
    }

    return atlas_identifierCharacterSet;
}

+ (NSCharacterSet *)atlas_cdTemplateTypeCharacterSet;
{
    static NSCharacterSet *atlas_templateTypeCharacterSet = nil;

    if (atlas_templateTypeCharacterSet == nil)
        atlas_templateTypeCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"<,>"] invertedSet];

    return atlas_templateTypeCharacterSet;
}

- (NSString *)atlas_peekCharacter;
{
    //[self skipCharacters];

    if ([self isAtEnd])
        return nil;

    return [[self string] substringWithRange:NSMakeRange([self scanLocation], 1)];
}

- (unichar)atlas_peekChar;
{
    return [[self string] characterAtIndex:[self scanLocation]];
}

- (BOOL)atlas_scanCharacter:(unichar *)atlas_value;
{
    //[self skipCharacters];

    if ([self isAtEnd])
        return NO;

    unichar atlas_ch = [[self string] characterAtIndex:[self scanLocation]];
    if (atlas_value != NULL)
        *atlas_value = atlas_ch;

    [self setScanLocation:[self scanLocation] + 1];

    return YES;
}

- (BOOL)atlas_scanCharacterFromSet:(NSCharacterSet *)atlas_set atlas_intoString:(NSString *__autoreleasing *)atlas_value;
{
    //[self skipCharacters];

    if ([self isAtEnd])
        return NO;

    unichar atlas_ch = [[self string] characterAtIndex:[self scanLocation]];
    if ([atlas_set characterIsMember:atlas_ch]) {
        if (atlas_value != NULL) {
            *atlas_value = [NSString atlas_stringWithUnichar:atlas_ch];
        }

        [self setScanLocation:[self scanLocation] + 1];
        return YES;
    }

    return NO;
}

// On 10.3 (7D24) the Foundation scanCharactersFromSet:intoString: inverts the set each call, creating an autoreleased CFCharacterSet.
// This cuts the total CFCharacterSet allocations (when run on Foundation) from 161682 down to 17.

// This works for my purposes, but I haven't tested it to make sure it's fully compatible with the standard version.

- (BOOL)atlas_my_scanCharactersFromSet:(NSCharacterSet *)atlas_set atlas_intoString:(NSString *__autoreleasing *)atlas_value;
{
    NSUInteger atlas_currentLocation = [self scanLocation];

    // Skip over characters
    NSCharacterSet *atlas_skipSet = [self charactersToBeSkipped];
    while ([self isAtEnd] == NO) {
        unichar atlas_ch = [[self string] characterAtIndex:atlas_currentLocation];
        if ([atlas_skipSet characterIsMember:atlas_ch] == NO)
            break;

        atlas_currentLocation++;
        [self setScanLocation:atlas_currentLocation];
    }

    NSRange atlas_matchedRange = NSMakeRange(atlas_currentLocation, 0);

    while ([self isAtEnd] == NO) {
        unichar atlas_ch = [[self string] characterAtIndex:atlas_currentLocation];
        if ([atlas_set characterIsMember:atlas_ch] == NO)
            break;

        atlas_currentLocation++;
        [self setScanLocation:atlas_currentLocation];
    }

    atlas_matchedRange.length = atlas_currentLocation - atlas_matchedRange.location;

    if (atlas_matchedRange.length == 0)
        return NO;

    if (atlas_value != NULL) {
        *atlas_value = [[self string] substringWithRange:atlas_matchedRange];
    }

    return YES;
}

- (BOOL)atlas_scanIdentifierIntoString:(NSString *__autoreleasing *)atlas_stringPointer;
{
    NSString *atlas_start, *atlas_remainder;

    if ([self scanString:@"?" intoString:atlas_stringPointer]) {
        return YES;
    }

    if ([self atlas_scanCharacterFromSet:[NSScanner atlas_cdIdentifierStartCharacterSet] atlas_intoString:&atlas_start]) {
        NSString *atlas_str;

        if ([self atlas_my_scanCharactersFromSet:[NSScanner atlas_cdIdentifierCharacterSet] atlas_intoString:&atlas_remainder]) {
            atlas_str = [atlas_start stringByAppendingString:atlas_remainder];
        } else {
            atlas_str = atlas_start;
        }

        if (atlas_stringPointer != NULL)
            *atlas_stringPointer = atlas_str;

        return YES;
    }

    return NO;
}

@end
