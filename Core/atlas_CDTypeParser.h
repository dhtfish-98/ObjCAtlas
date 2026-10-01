// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasType, ObjCAtlasTypeLexer;

extern NSString *atlas_CDExceptionName_SyntaxError;
extern NSString *atlas_CDErrorDomain_TypeParser;

extern NSString *atlas_CDErrorKey_Type;
extern NSString *atlas_CDErrorKey_RemainingString;
extern NSString *atlas_CDErrorKey_MethodOrVariable;
extern NSString *atlas_CDErrorKey_LocalizedLongDescription;

#define atlas_CDTypeParserCode_Default     0
#define atlas_CDTypeParserCode_SyntaxError 1

@interface ObjCAtlasTypeParser : NSObject

- (id)initWithString:(NSString *)atlas_string;

@property (readonly) ObjCAtlasTypeLexer *atlas_lexer;

- (NSArray *)atlas_parseMethodType:(NSError **)atlas_error;
- (ObjCAtlasType *)atlas_parseType:(NSError **)atlas_error;

@end
