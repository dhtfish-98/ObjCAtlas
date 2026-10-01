// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface NSString (CDExtensions)

+ (NSString *)atlas_stringWithFileSystemRepresentation:(const char *)atlas_str;
+ (NSString *)atlas_spacesIndentedToLevel:(NSUInteger)atlas_level;
+ (NSString *)atlas_spacesIndentedToLevel:(NSUInteger)atlas_level atlas_spacesPerLevel:(NSUInteger)atlas_spacesPerLevel;
+ (NSString *)atlas_stringWithUnichar:(unichar)atlas_character;

- (BOOL)atlas_isFirstLetterUppercase;

- (void)atlas_print;

- (NSString *)atlas_executablePathForFilename;

- (NSString *)atlas_SHA1DigestString;

- (BOOL)atlas_hasUnderscoreCapitalPrefix;
- (NSString *)atlas_capitalizeFirstCharacter;

@end

@interface NSMutableString (CDExtensions)

- (void)atlas_appendSpacesIndentedToLevel:(NSUInteger)atlas_level;
- (void)atlas_appendSpacesIndentedToLevel:(NSUInteger)atlas_level atlas_spacesPerLevel:(NSUInteger)atlas_spacesPerLevel;

@end
