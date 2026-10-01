// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@interface ObjCAtlasBalanceFormatter : NSObject

- (id)initWithString:(NSString *)atlas_str;

- (void)atlas_parse:(NSString *)atlas_open atlas_index:(NSUInteger)atlas_openIndex atlas_level:(NSUInteger)atlas_level;

- (NSString *)format;

@end
