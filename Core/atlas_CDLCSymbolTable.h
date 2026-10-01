// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDLoadCommand.h"

@class ObjCAtlasSymbol;

@interface ObjCAtlasLCSymbolTable : ObjCAtlasLoadCommand

- (void)atlas_loadSymbols;

@property (nonatomic, readonly) uint32_t atlas_symoff;
@property (nonatomic, readonly) uint32_t atlas_nsyms;
@property (nonatomic, readonly) uint32_t atlas_stroff;
@property (nonatomic, readonly) uint32_t atlas_strsize;

@property (nonatomic, readonly) NSUInteger atlas_baseAddress;
@property (nonatomic, readonly) NSArray *atlas_symbols;

- (ObjCAtlasSymbol *)atlas_symbolForClassName:(NSString *)atlas_className;
- (ObjCAtlasSymbol *)atlas_symbolForExternalClassName:(NSString *)atlas_className;

@end
