// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_NSString_CDExtensions.h"

@implementation NSString (CDExtensions)

+ (NSString *)atlas_stringWithFileSystemRepresentation:(const char *)atlas_str;
{
    // 2004-01-16: I'm don't understand why we need to pass in the length.
    return [[NSFileManager defaultManager] stringWithFileSystemRepresentation:atlas_str length:strlen(atlas_str)];
}

+ (NSString *)atlas_spacesIndentedToLevel:(NSUInteger)atlas_level;
{
    return [self atlas_spacesIndentedToLevel:atlas_level atlas_spacesPerLevel:4];
}

+ (NSString *)atlas_spacesIndentedToLevel:(NSUInteger)atlas_level atlas_spacesPerLevel:(NSUInteger)atlas_spacesPerLevel;
{
    NSString *atlas_spaces = @"                                        ";

    NSParameterAssert(atlas_spacesPerLevel <= [atlas_spaces length]);
    NSString *atlas_levelSpaces = [atlas_spaces substringToIndex:atlas_spacesPerLevel];

    NSMutableString *atlas_str = [NSMutableString string];
    for (NSUInteger atlas_l = 0; atlas_l < atlas_level; atlas_l++)
        [atlas_str appendString:atlas_levelSpaces];

    return atlas_str;
}

+ (NSString *)atlas_stringWithUnichar:(unichar)atlas_character;
{
    return [NSString stringWithCharacters:&atlas_character length:1];
}

- (BOOL)atlas_isFirstLetterUppercase;
{
    NSRange atlas_letterRange = [self rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
    if (atlas_letterRange.length == 0)
        return NO;

    return [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[self characterAtIndex:atlas_letterRange.location]];
}

- (void)atlas_print;
{
    NSData *atlas_data = [self dataUsingEncoding:NSUTF8StringEncoding];
    [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:atlas_data];
}

- (NSString *)atlas_executablePathForFilename;
{
    NSString *atlas_path;

    // I give up, all the methods dealing with paths seem to resolve symlinks with a vengence.
    NSBundle *atlas_bundle = [NSBundle bundleWithPath:self];
    if (atlas_bundle != nil) {
        if ([atlas_bundle executablePath] == nil)
            return nil;

        atlas_path = [[[atlas_bundle executablePath] stringByResolvingSymlinksInPath] stringByStandardizingPath];
    } else {
        atlas_path = [[self stringByResolvingSymlinksInPath] stringByStandardizingPath];
    }

    return atlas_path;
}

- (NSString *)atlas_SHA1DigestString;
{
    return [[[[self decomposedStringWithCanonicalMapping] dataUsingEncoding:NSUTF8StringEncoding] atlas_SHA1Digest] atlas_hexString];
}

- (BOOL)atlas_hasUnderscoreCapitalPrefix;
{
    if ([self length] < 2)
        return NO;

    return [self hasPrefix:@"_"] && [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[self characterAtIndex:1]];
}

- (NSString *)atlas_capitalizeFirstCharacter;
{
    if ([self length] < 2)
        return [self capitalizedString];

    return [NSString stringWithFormat:@"%@%@", [[self substringToIndex:1] capitalizedString], [self substringFromIndex:1]];
}

@end

@implementation NSMutableString (CDExtensions)

- (void)atlas_appendSpacesIndentedToLevel:(NSUInteger)atlas_level;
{
    [self atlas_appendSpacesIndentedToLevel:atlas_level atlas_spacesPerLevel:4];
}

- (void)atlas_appendSpacesIndentedToLevel:(NSUInteger)atlas_level atlas_spacesPerLevel:(NSUInteger)atlas_spacesPerLevel;
{
    NSString *atlas_spaces = @"                                        ";

    NSParameterAssert(atlas_spacesPerLevel <= [atlas_spaces length]);
    NSString *atlas_levelSpaces = [atlas_spaces substringToIndex:atlas_spacesPerLevel];

    for (NSUInteger atlas_l = 0; atlas_l < atlas_level; atlas_l++)
        [self appendString:atlas_levelSpaces];
}

@end
