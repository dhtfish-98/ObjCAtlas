// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#define atlas_TK_EOS                  0
#define atlas_TK_NUMBER               257
#define atlas_TK_IDENTIFIER           258
#define atlas_T_NAMED_OBJECT          259
#define atlas_TK_QUOTED_STRING        260
#define atlas_TK_TEMPLATE_TYPE        atlas_TK_IDENTIFIER
#define atlas_T_FUNCTION_POINTER_TYPE 1001
#define atlas_T_BLOCK_TYPE            1002

typedef enum : NSUInteger {
    atlas_CDTypeLexerState_Normal        = 0,
    atlas_CDTypeLexerState_Identifier    = 1,
    atlas_CDTypeLexerState_TemplateTypes = 2,
} atlas_CDTypeLexerState;

@interface ObjCAtlasTypeLexer : NSObject

- (id)initWithString:(NSString *)atlas_string;

@property (readonly) NSScanner *atlas_scanner;
@property (nonatomic, assign) atlas_CDTypeLexerState state;
@property (assign) BOOL atlas_shouldShowLexing;

@property (nonatomic, readonly) NSString *string;
- (int)atlas_scanNextToken;

@property (strong) NSString *atlas_lexText;

@property (nonatomic, readonly) unichar atlas_peekChar;
@property (nonatomic, readonly) NSString *atlas_remainingString;
@property (nonatomic, readonly) NSString *atlas_peekIdentifier;

@end
