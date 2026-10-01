// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTypeLexer.h"

static BOOL atlas_debug = NO;

static NSString *atlas_CDTypeLexerStateName(atlas_CDTypeLexerState atlas_state)
{
    switch (atlas_state) {
        case atlas_CDTypeLexerState_Normal:        return @"Normal";
        case atlas_CDTypeLexerState_Identifier:    return @"Identifier";
        case atlas_CDTypeLexerState_TemplateTypes: return @"Template";
    }
}

@implementation ObjCAtlasTypeLexer
{
    NSScanner *atlas__scanner;
    atlas_CDTypeLexerState atlas__state;
    NSString *atlas__lexText;
    
    BOOL atlas__shouldShowLexing;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_scanner = atlas__scanner;
@synthesize state = atlas__state;
@synthesize atlas_shouldShowLexing = atlas__shouldShowLexing;
@synthesize atlas_lexText = atlas__lexText;

- (id)initWithString:(NSString *)atlas_string;
{
    if ((self = [super init])) {
        atlas__scanner = [[NSScanner alloc] initWithString:atlas_string];
        [atlas__scanner setCharactersToBeSkipped:nil];
        atlas__state = atlas_CDTypeLexerState_Normal;
        atlas__shouldShowLexing = atlas_debug;
    }

    return self;
}

#pragma mark -

- (void)atlas_setState:(atlas_CDTypeLexerState)atlas_newState;
{
    if (atlas_debug) NSLog(@"CDTypeLexer - changing state from %lu (%@) to %lu (%@)", atlas__state, atlas_CDTypeLexerStateName(atlas__state), atlas_newState, atlas_CDTypeLexerStateName(atlas_newState));
    atlas__state = atlas_newState;
}

- (NSString *)string;
{
    return [atlas__scanner string];
}

- (int)atlas_scanNextToken;
{
    NSString *atlas_str;
    unichar atlas_ch;

    atlas__lexText = nil;

    if ([atlas__scanner isAtEnd]) {
        if (atlas__shouldShowLexing)                       NSLog(@"%s [state=%lu], token = TK_EOS", atlas___cmd, atlas__state);
        return atlas_TK_EOS;
    }

    if (atlas__state == atlas_CDTypeLexerState_TemplateTypes) {
        // Skip whitespace, scan '<', ',', '>'.  Everything else is lumped together as a string.
        [atlas__scanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
        if ([atlas__scanner scanString:@"<" intoString:NULL]) {
            if (atlas__shouldShowLexing)                   NSLog(@"%s [state=%lu], token = %d '%c'", atlas___cmd, atlas__state, '<', '<');
            return '<';
        }

        if ([atlas__scanner scanString:@">" intoString:NULL]) {
            if (atlas__shouldShowLexing)                   NSLog(@"%s [state=%lu], token = %d '%c'", atlas___cmd, atlas__state, '>', '>');
            return '>';
        }

        if ([atlas__scanner scanString:@"," intoString:NULL]) {
            if (atlas__shouldShowLexing)                   NSLog(@"%s [state=%lu], token = %d '%c'", atlas___cmd, atlas__state, ',', ',');
            return ',';
        }

        if ([atlas__scanner atlas_my_scanCharactersFromSet:[NSScanner atlas_cdTemplateTypeCharacterSet] atlas_intoString:&atlas_str]) {
            atlas__lexText = atlas_str;
            if (atlas__shouldShowLexing)                   NSLog(@"%s [state=%lu], token = TK_TEMPLATE_TYPE (%@)", atlas___cmd, atlas__state, atlas__lexText);
            return atlas_TK_TEMPLATE_TYPE;
        }

        NSLog(@"Ooops, fell through in template types state.");
    } else if (atlas__state == atlas_CDTypeLexerState_Identifier) {
        NSString *atlas_identifier;

        //NSLog(@"Scanning in identifier state.");
        [atlas__scanner setCharactersToBeSkipped:nil];

        if ([atlas__scanner atlas_scanIdentifierIntoString:&atlas_identifier]) {
            atlas__lexText = atlas_identifier;
            if (atlas__shouldShowLexing)                   NSLog(@"%s [state=%lu], token = TK_IDENTIFIER (%@)", atlas___cmd, atlas__state, atlas__lexText);
            atlas__state = atlas_CDTypeLexerState_Normal;
            return atlas_TK_IDENTIFIER;
        }
    } else {
        [atlas__scanner setCharactersToBeSkipped:nil];

        if ([atlas__scanner scanString:@"\"" intoString:NULL]) {
            if ([atlas__scanner scanUpToString:@"\"" intoString:&atlas_str])
                atlas__lexText = atlas_str;
            else
                atlas__lexText = @"";

            [atlas__scanner scanString:@"\"" intoString:NULL];
            if (atlas__shouldShowLexing)                   NSLog(@"%s [state=%lu], token = TK_QUOTED_STRING (%@)", atlas___cmd, atlas__state, atlas__lexText);
            return atlas_TK_QUOTED_STRING;
        }

        if ([atlas__scanner atlas_my_scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] atlas_intoString:&atlas_str]) {
            atlas__lexText = atlas_str;
            if (atlas__shouldShowLexing)                   NSLog(@"%s [state=%lu], token = TK_NUMBER (%@)", atlas___cmd, atlas__state, atlas__lexText);
            return atlas_TK_NUMBER;
        }

        if ([atlas__scanner atlas_scanCharacter:&atlas_ch]) {
            if (atlas__shouldShowLexing)                   NSLog(@"%s [state=%lu], token = %d '%c'", atlas___cmd, atlas__state, atlas_ch, atlas_ch);
            return atlas_ch;
        }
    }

    if (atlas__shouldShowLexing)                           NSLog(@"%s [state=%lu], token = TK_EOS", atlas___cmd, atlas__state);

    return atlas_TK_EOS;
}

- (unichar)atlas_peekChar;
{
    return [atlas__scanner atlas_peekChar];
}

- (NSString *)atlas_remainingString;
{
    return [[atlas__scanner string] substringFromIndex:[atlas__scanner scanLocation]];
}

- (NSString *)atlas_peekIdentifier;
{
    NSScanner *atlas_peekScanner = [[NSScanner alloc] initWithString:[atlas__scanner string]];
    [atlas_peekScanner setScanLocation:[atlas__scanner scanLocation]];

    NSString *atlas_identifier;
    if ([atlas_peekScanner atlas_scanIdentifierIntoString:&atlas_identifier]) {
        return atlas_identifier;
    }

    return nil;
}

@end
