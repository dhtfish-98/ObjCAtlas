// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface NSScanner (CDExtensions)

+ (NSCharacterSet *)atlas_cdOtherCharacterSet;
+ (NSCharacterSet *)atlas_cdIdentifierStartCharacterSet;
+ (NSCharacterSet *)atlas_cdIdentifierCharacterSet;
+ (NSCharacterSet *)atlas_cdTemplateTypeCharacterSet;

- (NSString *)atlas_peekCharacter;
- (unichar)atlas_peekChar;
- (BOOL)atlas_scanCharacter:(unichar *)atlas_value;
- (BOOL)atlas_scanCharacterFromSet:(NSCharacterSet *)atlas_set atlas_intoString:(NSString **)atlas_value;
- (BOOL)atlas_my_scanCharactersFromSet:(NSCharacterSet *)atlas_set atlas_intoString:(NSString **)atlas_value;

- (BOOL)atlas_scanIdentifierIntoString:(NSString **)atlas_stringPointer;

@end
