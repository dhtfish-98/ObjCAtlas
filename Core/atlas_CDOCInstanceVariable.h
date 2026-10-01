// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasType, ObjCAtlasTypeController;

@interface ObjCAtlasOCInstanceVariable : NSObject

- (id)initAtlasWithName:(NSString *)atlas_name atlas_typeString:(NSString *)atlas_typeString atlas_offset:(NSUInteger)atlas_offset;

@property (readonly) NSString *name;
@property (readonly) NSString *atlas_typeString;
@property (readonly) NSUInteger atlas_offset;

// Lazily parses the typeString.  Returns nil and sets the parseError if parsing failed.  Does not try to parse again in the event of an error.
@property (nonatomic, readonly) ObjCAtlasType *type;

// This is set after the typeString has been parsed if there was an error.  Doesn't trigger parsing.
@property (readonly) NSError *atlas_parseError;

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_typeController:(ObjCAtlasTypeController *)atlas_typeController;

@end
