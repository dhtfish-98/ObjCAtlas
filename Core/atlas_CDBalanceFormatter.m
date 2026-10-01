// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDBalanceFormatter.h"

static BOOL atlas_debug = NO;

@implementation ObjCAtlasBalanceFormatter
{
    NSScanner *atlas__scanner;
    NSCharacterSet *atlas__openCloseSet;
    
    NSMutableString *atlas__result;
}

- (id)initWithString:(NSString *)atlas_str;
{
    if ((self = [super init])) {
        atlas__scanner = [[NSScanner alloc] initWithString:atlas_str];
        atlas__openCloseSet = [NSCharacterSet characterSetWithCharactersInString:@"{}<>()"];
        
        atlas__result = [[NSMutableString alloc] init];
    }

    return self;
}

#pragma mark -

- (void)atlas_parse:(NSString *)atlas_open atlas_index:(NSUInteger)atlas_openIndex atlas_level:(NSUInteger)atlas_level;
{
    NSString *atlas_opens[] = { @"{", @"<", @"(", nil};
    NSString *atlas_closes[] = { @"}", @">", @")", nil};
    BOOL atlas_foundOpen = NO;
    BOOL atlas_foundClose = NO;

    while ([atlas__scanner isAtEnd] == NO) {
        NSString *atlas_pre;

        if ([atlas__scanner scanUpToCharactersFromSet:atlas__openCloseSet intoString:&atlas_pre]) {
            if (atlas_debug) NSLog(@"pre = '%@'", atlas_pre);
            [atlas__result appendFormat:@"%@%@\n", [NSString atlas_spacesIndentedToLevel:atlas_level], atlas_pre];
        }
        if (atlas_debug) NSLog(@"remaining: '%@'", [[atlas__scanner string] substringFromIndex:[atlas__scanner scanLocation]]);

        atlas_foundOpen = atlas_foundClose = NO;
        for (NSUInteger atlas_index = 0; atlas_index < 3; atlas_index++) {
            if (atlas_debug) NSLog(@"Checking open %lu: '%@'", atlas_index, atlas_opens[atlas_index]);
            if ([atlas__scanner scanString:atlas_opens[atlas_index] intoString:NULL]) {
                if (atlas_debug) NSLog(@"Start %@", atlas_opens[atlas_index]);
                [atlas__result atlas_appendSpacesIndentedToLevel:atlas_level];
                [atlas__result appendString:atlas_opens[atlas_index]];
                [atlas__result appendString:@"\n"];

                [self atlas_parse:atlas_opens[atlas_index] atlas_index:[atlas__scanner scanLocation] - 1 atlas_level:atlas_level + 1];

                [atlas__result atlas_appendSpacesIndentedToLevel:atlas_level];
                [atlas__result appendString:atlas_closes[atlas_index]];
                [atlas__result appendString:@"\n"];
                atlas_foundOpen = YES;
                break;
            }

            if (atlas_debug) NSLog(@"Checking close %lu: '%@'", atlas_index, atlas_closes[atlas_index]);
            if ([atlas__scanner scanString:atlas_closes[atlas_index] intoString:NULL]) {
                if ([atlas_open isEqualToString:atlas_opens[atlas_index]]) {
                    if (atlas_debug) NSLog(@"End %@", atlas_closes[atlas_index]);
                } else {
                    NSLog(@"ERROR: Unmatched end %@", atlas_closes[atlas_index]);
                }
                atlas_foundClose = YES;
                break;
            }
        }

        if (atlas_foundOpen == NO && atlas_foundClose == NO) {
            if (atlas_debug) NSLog(@"Unknown @ %lu: %@", [atlas__scanner scanLocation], [[atlas__scanner string] substringFromIndex:[atlas__scanner scanLocation]]);
            break;
        }

        if (atlas_foundClose)
            break;
    }
}

- (NSString *)format;
{
    [self atlas_parse:nil atlas_index:0 atlas_level:0];

    if (atlas_debug) NSLog(@"result:\n%@", atlas__result);

    return [NSString stringWithString:atlas__result];
}

@end
