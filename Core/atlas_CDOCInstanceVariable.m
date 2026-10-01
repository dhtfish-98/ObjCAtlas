// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCInstanceVariable.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDTypeFormatter.h"
#import "atlas_CDTypeParser.h"
#import "atlas_CDTypeController.h"
#import "atlas_CDType.h"

@interface ObjCAtlasOCInstanceVariable ()
@property (assign) BOOL atlas_hasParsedType;
@end

#pragma mark -

@implementation ObjCAtlasOCInstanceVariable
{
    NSString *atlas__name;
    NSString *atlas__typeString;
    NSUInteger atlas__offset;
    
    BOOL atlas__hasParsedType;
    ObjCAtlasType *atlas__type;
    NSError *atlas__parseError;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_hasParsedType = atlas__hasParsedType;
@synthesize name = atlas__name;
@synthesize atlas_typeString = atlas__typeString;
@synthesize atlas_offset = atlas__offset;
@synthesize type = atlas__type;
@synthesize atlas_parseError = atlas__parseError;

- (id)initAtlasWithName:(NSString *)atlas_name atlas_typeString:(NSString *)atlas_typeString atlas_offset:(NSUInteger)atlas_offset;
{
    if ((self = [super init])) {
        atlas__name       = atlas_name;
        atlas__typeString = atlas_typeString;
        atlas__offset     = atlas_offset;
        
        atlas__hasParsedType = NO;
        atlas__type          = nil;
        atlas__parseError    = nil;
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, typeString: '%@', offset: %lu",
            NSStringFromClass([self class]), self.name, self.atlas_typeString, self.atlas_offset];
}

#pragma mark -

- (ObjCAtlasType *)type;
{
    if (self.atlas_hasParsedType == NO && self.atlas_parseError == nil) {
        ObjCAtlasTypeParser *atlas_parser = [[ObjCAtlasTypeParser alloc] initWithString:self.atlas_typeString];
        NSError *atlas_error;
        atlas__type = [atlas_parser atlas_parseType:&atlas_error];
        if (atlas__type == nil) {
            NSLog(@"Warning: Parsing instance variable type failed, %@", self.name);
            atlas__parseError = atlas_error;
        } else {
            self.atlas_hasParsedType = YES;
        }
    }

    return atlas__type;
}

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_typeController:(ObjCAtlasTypeController *)atlas_typeController;
{
    ObjCAtlasType *atlas_type = [self type]; // Parses it, if necessary;
    if (self.atlas_parseError != nil) {
        if ([self.atlas_typeString length] > 0) {
            [atlas_resultString appendFormat:@"    // Error: parsing type: '%@', name: %@", self.atlas_typeString, self.name];
        } else {
            [atlas_resultString appendFormat:@"    // Error: Empty type, name: %@", self.name];
        }
    } else {
        NSString *atlas_formattedString = [[atlas_typeController atlas_ivarTypeFormatter] atlas_formatVariable:self.name atlas_type:atlas_type];
        NSParameterAssert(atlas_formattedString != nil);
        [atlas_resultString appendString:atlas_formattedString];
        [atlas_resultString appendString:@";"];
        if ([atlas_typeController atlas_shouldShowIvarOffsets]) {
            [atlas_resultString appendFormat:@"\t// %ld = 0x%lx", self.atlas_offset, self.atlas_offset];
        }
    }
}

@end
