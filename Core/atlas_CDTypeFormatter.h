// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasType, ObjCAtlasTypeController;

@interface ObjCAtlasTypeFormatter : NSObject

@property (weak) ObjCAtlasTypeController *atlas_typeController;

@property (assign) NSUInteger atlas_baseLevel;
@property (assign) BOOL atlas_shouldExpand;
@property (assign) BOOL atlas_shouldAutoExpand;
@property (assign) BOOL atlas_shouldShowLexing;

- (NSString *)atlas_formatVariable:(NSString *)atlas_name atlas_type:(ObjCAtlasType *)atlas_type;
- (NSString *)atlas_formatMethodName:(NSString *)atlas_name atlas_typeString:(NSString *)atlas_typeString;

- (NSString *)atlas_typedefNameForStructure:(ObjCAtlasType *)atlas_structureType atlas_level:(NSUInteger)atlas_level;

- (void)atlas_formattingDidReferenceClassName:(NSString *)atlas_name;
- (void)atlas_formattingDidReferenceProtocolNames:(NSArray *)atlas_names;

@end
