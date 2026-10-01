// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCMethod.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDTypeFormatter.h"
#import "atlas_CDTypeParser.h"
#import "atlas_CDTypeController.h"

@implementation ObjCAtlasOCMethod
{
    NSString *atlas__name;
    NSString *atlas__typeString;
    NSUInteger atlas__address;
    
    BOOL atlas__hasParsedType;
    NSArray *atlas__parsedMethodTypes;
}

// Preserve the original explicit property storage after renaming.
@synthesize name = atlas__name;
@synthesize atlas_typeString = atlas__typeString;
@synthesize address = atlas__address;

- (id)init;
{
    [NSException raise:@"RejectUnusedImplementation" format:@"-initWithName:typeString:imp: is the designated initializer"];
    return nil;
}

- (id)initAtlasWithName:(NSString *)atlas_name atlas_typeString:(NSString *)atlas_typeString;
{
    return [self initAtlasWithName:atlas_name atlas_typeString:atlas_typeString atlas_address:0];
}

- (id)initAtlasWithName:(NSString *)atlas_name atlas_typeString:(NSString *)atlas_typeString atlas_address:(NSUInteger)atlas_address;
{
    if ((self = [super init])) {
        atlas__name = atlas_name;
        atlas__typeString = atlas_typeString;
        atlas__address = atlas_address;
        
        atlas__hasParsedType = NO;
        atlas__parsedMethodTypes = nil;
    }

    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)atlas_zone;
{
    return [[ObjCAtlasOCMethod alloc] initAtlasWithName:self.name atlas_typeString:self.atlas_typeString atlas_address:self.address];
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] name: %@, typeString: %@, address: 0x%016lx",
            NSStringFromClass([self class]), self.name, self.atlas_typeString, self.address];
}

#pragma mark -

- (NSArray *)atlas_parsedMethodTypes;
{
    if (atlas__hasParsedType == NO) {
        NSError *atlas_error = nil;

        ObjCAtlasTypeParser *atlas_parser = [[ObjCAtlasTypeParser alloc] initWithString:self.atlas_typeString];
        atlas__parsedMethodTypes = [atlas_parser atlas_parseMethodType:&atlas_error];
        if (atlas__parsedMethodTypes == nil)
            NSLog(@"Warning: Parsing method types failed, %@", self.name);
        atlas__hasParsedType = YES;
    }

    return atlas__parsedMethodTypes;
}

- (void)atlas_appendToString:(NSMutableString *)atlas_resultString atlas_typeController:(ObjCAtlasTypeController *)atlas_typeController;
{
    NSString *atlas_formattedString = [atlas_typeController.atlas_methodTypeFormatter atlas_formatMethodName:self.name atlas_typeString:self.atlas_typeString];
    if (atlas_formattedString != nil) {
        [atlas_resultString appendString:atlas_formattedString];
        [atlas_resultString appendString:@";"];
        if (atlas_typeController.atlas_shouldShowMethodAddresses && self.address != 0) {
            if (atlas_typeController.atlas_targetArchUses64BitABI)
                [atlas_resultString appendFormat:@"\t// IMP=0x%016lx", self.address];
            else
                [atlas_resultString appendFormat:@"\t// IMP=0x%08lx", self.address];
        }
    } else
        [atlas_resultString appendFormat:@"    // Error parsing type: %@, name: %@", self.atlas_typeString, self.name];
}

#pragma mark - Sorting

- (NSComparisonResult)atlas_ascendingCompareByName:(ObjCAtlasOCMethod *)atlas_other;
{
    return [self.name compare:atlas_other.name];
}

@end
