// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCProperty.h"

#import "atlas_CDTypeParser.h"
#import "atlas_CDTypeLexer.h"
#import "atlas_CDType.h"

// http://developer.apple.com/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html

static BOOL atlas_debug = NO;

@interface ObjCAtlasOCProperty ()
@end

#pragma mark -

@implementation ObjCAtlasOCProperty
{
    NSString *atlas__name;
    NSString *atlas__attributeString;
    
    ObjCAtlasType *atlas__type;
    NSMutableArray *atlas__attributes;
    
    BOOL atlas__hasParsedAttributes;
    NSString *atlas__attributeStringAfterType;
    NSString *atlas__customGetter;
    NSString *atlas__customSetter;
    
    BOOL atlas__isReadOnly;
    BOOL atlas__isDynamic;
}

// Preserve the original explicit property storage after renaming.
@synthesize name = atlas__name;
@synthesize atlas_attributeString = atlas__attributeString;
@synthesize type = atlas__type;
@synthesize attributes = atlas__attributes;
@synthesize atlas_attributeStringAfterType = atlas__attributeStringAfterType;
@synthesize atlas_customGetter = atlas__customGetter;
@synthesize atlas_customSetter = atlas__customSetter;
@synthesize atlas_isReadOnly = atlas__isReadOnly;
@synthesize atlas_isDynamic = atlas__isDynamic;

- (id)initAtlasWithName:(NSString *)atlas_name atlas_attributes:(NSString *)atlas_attributes;
{
    if ((self = [super init])) {
        atlas__name = atlas_name;
        atlas__attributeString = atlas_attributes;
        atlas__type = nil;
        atlas__attributes = [[NSMutableArray alloc] init];
        
        atlas__hasParsedAttributes = NO;
        atlas__attributeStringAfterType = nil;
        atlas__customGetter = nil;
        atlas__customSetter = nil;
        
        atlas__isReadOnly = NO;
        atlas__isDynamic = NO;
        
        [self atlas__parseAttributes];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> name: %@, attributeString: %@",
            NSStringFromClass([self class]), self,
            self.name, self.atlas_attributeString];
}

#pragma mark -

- (NSString *)atlas_defaultGetter;
{
    return self.name;
}

- (NSString *)atlas_defaultSetter;
{
    return [NSString stringWithFormat:@"set%@:", [self.name atlas_capitalizeFirstCharacter]];
}

- (NSString *)atlas_getter;
{
    if (self.atlas_customGetter != nil)
        return self.atlas_customGetter;

    return self.atlas_defaultGetter;
}

- (NSString *)atlas_setter;
{
    if (self.atlas_customSetter != nil)
        return self.atlas_customSetter;

    return self.atlas_defaultSetter;
}

#pragma mark - Sorting

- (NSComparisonResult)atlas_ascendingCompareByName:(ObjCAtlasOCProperty *)atlas_other;
{
    return [self.name compare:atlas_other.name];
}

#pragma mark -

// TODO: (2009-07-09) Really, I don't need to require the "T" at the start.
- (void)atlas__parseAttributes;
{
    // On 10.6, Finder's TTaskErrorViewController class has a property with a nasty C++ type.  I just knew someone would make this difficult.
    NSScanner *atlas_scanner = [[NSScanner alloc] initWithString:self.atlas_attributeString];

    if ([atlas_scanner scanString:@"T" intoString:NULL]) {
        NSError *atlas_error = nil;
        NSRange atlas_typeRange;

        atlas_typeRange.location = [atlas_scanner scanLocation];
        ObjCAtlasTypeParser *atlas_parser = [[ObjCAtlasTypeParser alloc] initWithString:[[atlas_scanner string] substringFromIndex:[atlas_scanner scanLocation]]];
        atlas__type = [atlas_parser atlas_parseType:&atlas_error];
        if (atlas__type != nil) {
            atlas_typeRange.length = [atlas_parser.atlas_lexer.atlas_scanner scanLocation];

            NSString *atlas_str = [self.atlas_attributeString substringFromIndex:NSMaxRange(atlas_typeRange)];

            // Filter out so we don't get an empty string as an attribute.
            if ([atlas_str hasPrefix:@","])
                atlas_str = [atlas_str substringFromIndex:1];

            self.atlas_attributeStringAfterType = atlas_str;
            if ([self.atlas_attributeStringAfterType length] > 0) {
                [atlas__attributes addObjectsFromArray:[self.atlas_attributeStringAfterType componentsSeparatedByString:@","]];
            } else {
                // For a simple case like "Ti", we'd get the empty string.
                // Then, using componentsSeparatedByString:, since it has no separator we'd get back an array containing the (empty) string
            }
        }
    } else {
        if (atlas_debug) NSLog(@"Error: Property attributes should begin with the type ('T') attribute, property name: %@", self.name);
    }

    for (NSString *atlas_attr in atlas__attributes) {
        if ([atlas_attr hasPrefix:@"R"])
            atlas__isReadOnly = YES;
        else if ([atlas_attr hasPrefix:@"D"])
            atlas__isDynamic = YES;
        else if ([atlas_attr hasPrefix:@"G"])
            self.atlas_customGetter = [atlas_attr substringFromIndex:1];
        else if ([atlas_attr hasPrefix:@"S"])
            self.atlas_customSetter = [atlas_attr substringFromIndex:1];
    }

    atlas__hasParsedAttributes = YES;
    // And then if parsedType is nil, we know we couldn't parse the type.
}

@end
