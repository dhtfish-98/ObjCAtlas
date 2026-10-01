// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDType.h"

#import "atlas_CDTypeController.h"
#import "atlas_CDTypeName.h"
#import "atlas_CDTypeLexer.h" // For T_NAMED_OBJECT
#import "atlas_CDTypeFormatter.h"
#import "atlas_CDTypeParser.h"

static BOOL atlas_debugMerge = NO;

@interface ObjCAtlasType ()
@property (nonatomic, readonly) NSString *atlas_formattedStringForSimpleType;
@end

#pragma mark -

// primitive types:
// * gets turned into ^c (i.e. char *)
// T_NAMED_OBJECT w/ _typeName as the name
// @ - id
// { - structure w/ _typeName, members
// ( - union     w/ _typeName, members
// b - bitfield  w/ _bitfieldSize          - can these occur anywhere, or just in structures/unions?
// [ - array     w/ _arraySize, _subtype
// ^ - poiner to _subtype
// C++ template type...

// Primitive types:
// c: char
// i: int
// s: short
// l: long
// q: long long
// C: unsigned char
// I: unsigned int
// S: unsigned short
// L: unsigned long
// Q: unsigned long long
// f: float
// d: double
// D: long double
// B: _Bool // C99 _Bool or C++ bool
// v: void
// #: Class
// :: SEL
// %: NXAtom
// ?: void
//case '?': return @"UNKNOWN"; // For easier regression testing.
// j: _Complex - is this a modifier or a primitive type?
//
// modifier (which?) w/ _subtype.  Can we limit these to the top level of the type?
//   - n - in
//   - N - inout
//   - o - out
//   - O - bycopy
//   - R - byref
//   - V - oneway
// const is probably different from the previous modifiers.  You can have const int * const foo, or something like that.
//   - r - const


@implementation ObjCAtlasType
{
    int atlas__primitiveType;
    NSArray *atlas__protocols;
    ObjCAtlasType *atlas__subtype;
    ObjCAtlasTypeName *atlas__typeName;
    NSMutableArray *atlas__members;
    NSString *atlas__bitfieldSize;
    NSString *atlas__arraySize;
    
    NSString *atlas__variableName;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_variableName = atlas__variableName;
@synthesize atlas_primitiveType = atlas__primitiveType;
@synthesize atlas_subtype = atlas__subtype;
@synthesize atlas_typeName = atlas__typeName;
@synthesize atlas_members = atlas__members;

- (id)initAtlasSimpleType:(int)atlas_type;
{
    if ((self = [self init])) {
        if (atlas_type == '*') {
            atlas__primitiveType = '^';
            atlas__subtype = [[ObjCAtlasType alloc] initAtlasSimpleType:'c'];
        } else {
            atlas__primitiveType = atlas_type;
        }
    }

    return self;
}

- (id)initAtlasIDType:(ObjCAtlasTypeName *)atlas_name;
{
    return [self initAtlasIDType:atlas_name atlas_withProtocols:nil];
}

- (id)initAtlasIDType:(ObjCAtlasTypeName *)atlas_name atlas_withProtocols:(NSArray *)atlas_protocols;
{
    if ((self = [self init])) {
        if (atlas_name != nil) {
            atlas__primitiveType = atlas_T_NAMED_OBJECT;
            atlas__typeName = atlas_name;
        } else {
            atlas__primitiveType = '@';
        }
        atlas__protocols = atlas_protocols;
    }
    
    return self;
}

- (id)initAtlasIDTypeWithProtocols:(NSArray *)atlas_protocols;
{
    if ((self = [self init])) {
        atlas__primitiveType = '@';
        atlas__protocols = atlas_protocols;
    }

    return self;
}

- (id)initAtlasStructType:(ObjCAtlasTypeName *)atlas_name atlas_members:(NSArray *)atlas_members;
{
    if ((self = [self init])) {
        atlas__primitiveType = '{';
        atlas__typeName = atlas_name;
        atlas__members = [[NSMutableArray alloc] initWithArray:atlas_members];
    }

    return self;
}

- (id)initAtlasUnionType:(ObjCAtlasTypeName *)atlas_name atlas_members:(NSArray *)atlas_members;
{
    if ((self = [self init])) {
        atlas__primitiveType = '(';
        atlas__typeName = atlas_name;
        atlas__members = [[NSMutableArray alloc] initWithArray:atlas_members];
    }

    return self;
}

- (id)initAtlasBitfieldType:(NSString *)atlas_bitfieldSize;
{
    if ((self = [self init])) {
        atlas__primitiveType = 'b';
        atlas__bitfieldSize = atlas_bitfieldSize;
    }

    return self;
}

- (id)initAtlasArrayType:(ObjCAtlasType *)atlas_type atlas_count:(NSString *)atlas_count;
{
    if ((self = [self init])) {
        atlas__primitiveType = '[';
        atlas__arraySize = atlas_count;
        atlas__subtype = atlas_type;
    }

    return self;
}

- (id)initAtlasPointerType:(ObjCAtlasType *)atlas_type;
{
    if ((self = [self init])) {
        atlas__primitiveType = '^';
        atlas__subtype = atlas_type;
    }

    return self;
}

- (id)initAtlasFunctionPointerType;
{
    if ((self = [self init])) {
        atlas__primitiveType = atlas_T_FUNCTION_POINTER_TYPE;
    }

    return self;
}

- (id)initAtlasBlockTypeWithTypes:(NSArray *)atlas_types;
{
    if ((self = [self init])) {
        atlas__primitiveType = atlas_T_BLOCK_TYPE;
        _atlas_types = atlas_types;
    }

    return self;
}

- (id)initAtlasModifier:(int)atlas_modifier atlas_type:(ObjCAtlasType *)atlas_type;
{
    if ((self = [self init])) {
        atlas__primitiveType = atlas_modifier;
        atlas__subtype = atlas_type;
    }

    return self;
}

#pragma mark - NSCopying

// An easy deep copy.
- (id)copyWithZone:(NSZone *)atlas_zone;
{
    NSString *atlas_str = [self atlas_typeString];
    NSParameterAssert(atlas_str != nil);
    
    ObjCAtlasTypeParser *atlas_parser = [[ObjCAtlasTypeParser alloc] initWithString:atlas_str];

    NSError *atlas_error = nil;
    ObjCAtlasType *atlas_copiedType = [atlas_parser atlas_parseType:&atlas_error];
    if (atlas_copiedType == nil)
        NSLog(@"Warning: Parsing type in %s failed, %@", __PRETTY_FUNCTION__, atlas_str);
    
    NSParameterAssert([atlas_str isEqualToString:atlas_copiedType.atlas_typeString]);
    
    atlas_copiedType.atlas_variableName = atlas__variableName;
    
    return atlas_copiedType;
}

#pragma mark -

// TODO: (2009-08-26) Looks like this doesn't compare the variable name.
- (BOOL)isEqual:(id)atlas_object;
{
    if ([atlas_object isKindOfClass:[self class]]) {
        ObjCAtlasType *atlas_otherType = atlas_object;
        return [self.atlas_typeString isEqual:atlas_otherType.atlas_typeString];
    }
    
    return NO;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"[%@] type: %d('%c'), name: %@, subtype: %@, bitfieldSize: %@, arraySize: %@, members: %@, variableName: %@",
            NSStringFromClass([self class]), atlas__primitiveType, atlas__primitiveType, atlas__typeName, atlas__subtype, atlas__bitfieldSize, atlas__arraySize, atlas__members, atlas__variableName];
}

#pragma mark -

- (BOOL)atlas_isIDType;
{
    return atlas__primitiveType == '@' && atlas__typeName == nil;
}

- (BOOL)atlas_isNamedObject;
{
    return atlas__primitiveType == atlas_T_NAMED_OBJECT;
}

- (BOOL)atlas_isTemplateType;
{
    return atlas__typeName.atlas_isTemplateType;
}

- (BOOL)atlas_isModifierType;
{
    return atlas__primitiveType == 'j' || atlas__primitiveType == 'r' || atlas__primitiveType == 'n' || atlas__primitiveType == 'N' || atlas__primitiveType == 'o' || atlas__primitiveType == 'O' || atlas__primitiveType == 'R' || atlas__primitiveType == 'V' || atlas__primitiveType == 'A';
}

- (int)atlas_typeIgnoringModifiers;
{
    if (self.atlas_isModifierType && atlas__subtype != nil)
        return atlas__subtype.atlas_typeIgnoringModifiers;

    return atlas__primitiveType;
}

- (NSUInteger)atlas_structureDepth;
{
    if (atlas__subtype != nil)
        return atlas__subtype.atlas_structureDepth;

    if (atlas__primitiveType == '{' || atlas__primitiveType == '(') {
        NSUInteger atlas_maxDepth = 0;

        for (ObjCAtlasType *atlas_member in atlas__members) {
            if (atlas_maxDepth < atlas_member.atlas_structureDepth)
                atlas_maxDepth = atlas_member.atlas_structureDepth;
        }

        return atlas_maxDepth + 1;
    }

    return 0;
}

- (NSString *)atlas_formattedString:(NSString *)atlas_previousName atlas_formatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_level:(NSUInteger)atlas_level;
{
    NSString *atlas_result, *atlas_currentName;
    NSString *atlas_baseType, *atlas_memberString;

    assert(atlas__variableName == nil || atlas_previousName == nil);
    if (atlas__variableName != nil)
        atlas_currentName = atlas__variableName;
    else
        atlas_currentName = atlas_previousName;
    
    if ([atlas__protocols count])
        [atlas_typeFormatter atlas_formattingDidReferenceProtocolNames:atlas__protocols];

    switch (self.atlas_primitiveType) {
        case atlas_T_NAMED_OBJECT: {
            assert(self.atlas_typeName != nil);
            [atlas_typeFormatter atlas_formattingDidReferenceClassName:atlas__typeName.name];

            NSString *atlas_typeName = nil;
            if (atlas__protocols == nil)
                atlas_typeName = [NSString stringWithFormat:@"%@", atlas__typeName];
            else
                atlas_typeName = [NSString stringWithFormat:@"%@<%@>", atlas__typeName, [atlas__protocols componentsJoinedByString:@", "]];

            if (atlas_currentName == nil)
                atlas_result = [NSString stringWithFormat:@"%@ *", atlas_typeName];
            else
                atlas_result = [NSString stringWithFormat:@"%@ *%@", atlas_typeName, atlas_currentName];
            break;
        }
        case '@':
            if (atlas_currentName == nil) {
                if (atlas__protocols == nil)
                    atlas_result = @"id";
                else
                    atlas_result = [NSString stringWithFormat:@"id <%@>", [atlas__protocols componentsJoinedByString:@", "]];
            } else {
                if (atlas__protocols == nil)
                    atlas_result = [NSString stringWithFormat:@"id %@", atlas_currentName];
                else
                    atlas_result = [NSString stringWithFormat:@"id <%@> %@", [atlas__protocols componentsJoinedByString:@", "], atlas_currentName];
            }
            break;
            
        case 'b':
            if (atlas_currentName == nil) {
                // This actually compiles!
                atlas_result = [NSString stringWithFormat:@"unsigned int :%@", atlas__bitfieldSize];
            } else
                atlas_result = [NSString stringWithFormat:@"unsigned int %@:%@", atlas_currentName, atlas__bitfieldSize];
            break;
            
        case '[':
            if (atlas_currentName == nil)
                atlas_result = [NSString stringWithFormat:@"[%@]", atlas__arraySize];
            else
                atlas_result = [NSString stringWithFormat:@"%@[%@]", atlas_currentName, atlas__arraySize];
            
            atlas_result = [atlas__subtype atlas_formattedString:atlas_result atlas_formatter:atlas_typeFormatter atlas_level:atlas_level];
            break;
            
        case '(':
            atlas_baseType = nil;
            /*if (typeName == nil || [@"?" isEqual:[typeName description]])*/ {
                NSString *atlas_typedefName = [atlas_typeFormatter atlas_typedefNameForStructure:self atlas_level:atlas_level];
                if (atlas_typedefName != nil) {
                    atlas_baseType = atlas_typedefName;
                }
            }
            
            if (atlas_baseType == nil) {
                if (atlas__typeName == nil || [@"?" isEqual:[atlas__typeName description]])
                    atlas_baseType = @"union";
                else
                    atlas_baseType = [NSString stringWithFormat:@"union %@", atlas__typeName];
                
                if ((atlas_typeFormatter.atlas_shouldAutoExpand && [atlas_typeFormatter.atlas_typeController atlas_shouldExpandType:self] && [atlas__members count] > 0)
                    || (atlas_level == 0 && atlas_typeFormatter.atlas_shouldExpand && [atlas__members count] > 0))
                    atlas_memberString = [NSString stringWithFormat:@" {\n%@%@}",
                                    [self atlas_formattedStringForMembersAtLevel:atlas_level + 1 atlas_formatter:atlas_typeFormatter],
                                    [NSString atlas_spacesIndentedToLevel:atlas_typeFormatter.atlas_baseLevel + atlas_level atlas_spacesPerLevel:4]];
                else
                    atlas_memberString = @"";
                
                atlas_baseType = [atlas_baseType stringByAppendingString:atlas_memberString];
            }
            
            if (atlas_currentName == nil /*|| [currentName hasPrefix:@"?"]*/) // Not sure about this
                atlas_result = atlas_baseType;
            else
                atlas_result = [NSString stringWithFormat:@"%@ %@", atlas_baseType, atlas_currentName];
            break;
            
        case '{':
            atlas_baseType = nil;
            /*if (typeName == nil || [@"?" isEqual:[typeName description]])*/ {
                NSString *atlas_typedefName = [atlas_typeFormatter atlas_typedefNameForStructure:self atlas_level:atlas_level];
                if (atlas_typedefName != nil) {
                    atlas_baseType = atlas_typedefName;
                }
            }
            if (atlas_baseType == nil) {
                if (atlas__typeName == nil || [@"?" isEqual:[atlas__typeName description]])
                    atlas_baseType = @"struct";
                else
                    atlas_baseType = [NSString stringWithFormat:@"struct %@", atlas__typeName];
                
                if ((atlas_typeFormatter.atlas_shouldAutoExpand && [atlas_typeFormatter.atlas_typeController atlas_shouldExpandType:self] && [atlas__members count] > 0)
                    || (atlas_level == 0 && atlas_typeFormatter.atlas_shouldExpand && [atlas__members count] > 0))
                    atlas_memberString = [NSString stringWithFormat:@" {\n%@%@}",
                                    [self atlas_formattedStringForMembersAtLevel:atlas_level + 1 atlas_formatter:atlas_typeFormatter],
                                    [NSString atlas_spacesIndentedToLevel:atlas_typeFormatter.atlas_baseLevel + atlas_level atlas_spacesPerLevel:4]];
                else
                    atlas_memberString = @"";
                
                atlas_baseType = [atlas_baseType stringByAppendingString:atlas_memberString];
            }
            
            if (atlas_currentName == nil /*|| [currentName hasPrefix:@"?"]*/) // Not sure about this
                atlas_result = atlas_baseType;
            else
                atlas_result = [NSString stringWithFormat:@"%@ %@", atlas_baseType, atlas_currentName];
            break;
            
        case '^':
            if (atlas_currentName == nil)
                atlas_result = @"*";
            else
                atlas_result = [@"*" stringByAppendingString:atlas_currentName];
            
            if (atlas__subtype != nil && atlas__subtype.atlas_primitiveType == '[')
                atlas_result = [NSString stringWithFormat:@"(%@)", atlas_result];
            
            atlas_result = [atlas__subtype atlas_formattedString:atlas_result atlas_formatter:atlas_typeFormatter atlas_level:atlas_level];
            break;
            
        case atlas_T_FUNCTION_POINTER_TYPE:
            if (atlas_currentName == nil)
                atlas_result = @"CDUnknownFunctionPointerType";
            else
                atlas_result = [NSString stringWithFormat:@"CDUnknownFunctionPointerType %@", atlas_currentName];
            break;
            
        case atlas_T_BLOCK_TYPE:
            if (self.atlas_types) {
                atlas_result = [self atlas_blockSignatureString];
            } else {
                if (atlas_currentName == nil)
                    atlas_result = @"CDUnknownBlockType";
                else
                    atlas_result = [NSString stringWithFormat:@"CDUnknownBlockType %@", atlas_currentName];
            }
            break;
            
        case 'j':
        case 'r':
        case 'n':
        case 'N':
        case 'o':
        case 'O':
        case 'R':
        case 'V':
        case 'A':
            if (atlas__subtype == nil) {
                if (atlas_currentName == nil)
                    atlas_result = [self atlas_formattedStringForSimpleType];
                else
                    atlas_result = [NSString stringWithFormat:@"%@ %@", self.atlas_formattedStringForSimpleType, atlas_currentName];
            } else
                atlas_result = [NSString stringWithFormat:@"%@ %@",
                          self.atlas_formattedStringForSimpleType, [atlas__subtype atlas_formattedString:atlas_currentName atlas_formatter:atlas_typeFormatter atlas_level:atlas_level]];
            break;
            
        default:
            if (atlas_currentName == nil)
                atlas_result = self.atlas_formattedStringForSimpleType;
            else
                atlas_result = [NSString stringWithFormat:@"%@ %@", self.atlas_formattedStringForSimpleType, atlas_currentName];
            break;
    }
    
    return atlas_result;
}

- (NSString *)atlas_formattedStringForMembersAtLevel:(NSUInteger)atlas_level atlas_formatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter;
{
    NSParameterAssert(atlas__primitiveType == '{' || atlas__primitiveType == '(');
    NSMutableString *atlas_str = [NSMutableString string];

    for (ObjCAtlasType *atlas_member in atlas__members) {
        [atlas_str appendString:[NSString atlas_spacesIndentedToLevel:atlas_typeFormatter.atlas_baseLevel + atlas_level atlas_spacesPerLevel:4]];
        [atlas_str appendString:[atlas_member atlas_formattedString:nil
                                  atlas_formatter:atlas_typeFormatter
                                  atlas_level:atlas_level]];
        [atlas_str appendString:@";\n"];
    }

    return atlas_str;
}

- (NSString *)atlas_formattedStringForSimpleType;
{
    // Ugly but simple:
    switch (atlas__primitiveType) {
        case 'c': return @"char";
        case 'i': return @"int";
        case 's': return @"short";
        case 'l': return @"long";
        case 'q': return @"long long";
        case 'C': return @"unsigned char";
        case 'I': return @"unsigned int";
        case 'S': return @"unsigned short";
        case 'L': return @"unsigned long";
        case 'Q': return @"unsigned long long";
        case 'f': return @"float";
        case 'd': return @"double";
        case 'D': return @"long double";
        case 'B': return @"_Bool"; // C99 _Bool or C++ bool
        case 'v': return @"void";
        case '*': return @"STR";
        case '#': return @"Class";
        case ':': return @"SEL";
        case '%': return @"NXAtom";
        case '?': return @"void";
            //case '?': return @"UNKNOWN"; // For easier regression testing.
        case 'j': return @"_Complex";
        case 'r': return @"const";
        case 'n': return @"in";
        case 'N': return @"inout";
        case 'o': return @"out";
        case 'O': return @"bycopy";
        case 'R': return @"byref";
        case 'V': return @"oneway";
        case 'A': return @"_Atomic";
        default:
            break;
    }

    return nil;
}

- (NSString *)atlas_typeString;
{
    return [self atlas__typeStringWithVariableNamesToLevel:1e6 atlas_showObjectTypes:YES];
}

- (NSString *)atlas_bareTypeString;
{
    return [self atlas__typeStringWithVariableNamesToLevel:0 atlas_showObjectTypes:YES];
}

- (NSString *)atlas_reallyBareTypeString;
{
    return [self atlas__typeStringWithVariableNamesToLevel:0 atlas_showObjectTypes:NO];
}

- (NSString *)atlas_keyTypeString;
{
    // use variable names at top level
    return [self atlas__typeStringWithVariableNamesToLevel:1 atlas_showObjectTypes:YES];
}

- (NSString *)atlas__typeStringWithVariableNamesToLevel:(NSUInteger)atlas_level atlas_showObjectTypes:(BOOL)atlas_shouldShowObjectTypes;
{
    NSString *atlas_result;
    
    switch (atlas__primitiveType) {
        case atlas_T_NAMED_OBJECT:
            assert(atlas__typeName != nil);
            if (atlas_shouldShowObjectTypes)
                atlas_result = [NSString stringWithFormat:@"@\"%@\"", atlas__typeName];
            else
                atlas_result = @"@";
            break;
            
        case '@':
            atlas_result = @"@";
            break;
            
        case 'b':
            atlas_result = [NSString stringWithFormat:@"b%@", atlas__bitfieldSize];
            break;
            
        case '[':
            atlas_result = [NSString stringWithFormat:@"[%@%@]", atlas__arraySize, [atlas__subtype atlas__typeStringWithVariableNamesToLevel:atlas_level atlas_showObjectTypes:atlas_shouldShowObjectTypes]];
            break;
            
        case '(':
            if (atlas__typeName == nil) {
                return [NSString stringWithFormat:@"(%@)", [self atlas__typeStringForMembersWithVariableNamesToLevel:atlas_level atlas_showObjectTypes:atlas_shouldShowObjectTypes]];
            } else if ([atlas__members count] == 0) {
                return [NSString stringWithFormat:@"(%@)", atlas__typeName];
            } else {
                return [NSString stringWithFormat:@"(%@=%@)", atlas__typeName, [self atlas__typeStringForMembersWithVariableNamesToLevel:atlas_level atlas_showObjectTypes:atlas_shouldShowObjectTypes]];
            }
            
        case '{':
            if (atlas__typeName == nil) {
                return [NSString stringWithFormat:@"{%@}", [self atlas__typeStringForMembersWithVariableNamesToLevel:atlas_level atlas_showObjectTypes:atlas_shouldShowObjectTypes]];
            } else if ([atlas__members count] == 0) {
                return [NSString stringWithFormat:@"{%@}", atlas__typeName];
            } else {
                return [NSString stringWithFormat:@"{%@=%@}", atlas__typeName, [self atlas__typeStringForMembersWithVariableNamesToLevel:atlas_level atlas_showObjectTypes:atlas_shouldShowObjectTypes]];
            }
            
        case '^':
            atlas_result = [NSString stringWithFormat:@"^%@", [atlas__subtype atlas__typeStringWithVariableNamesToLevel:atlas_level atlas_showObjectTypes:atlas_shouldShowObjectTypes]];
            break;
            
        case 'j':
        case 'r':
        case 'n':
        case 'N':
        case 'o':
        case 'O':
        case 'R':
        case 'V':
        case 'A':
            atlas_result = [NSString stringWithFormat:@"%c%@", atlas__primitiveType, [atlas__subtype atlas__typeStringWithVariableNamesToLevel:atlas_level atlas_showObjectTypes:atlas_shouldShowObjectTypes]];
            break;
            
        case atlas_T_FUNCTION_POINTER_TYPE:
            atlas_result = @"^?";
            break;
            
        case atlas_T_BLOCK_TYPE:
            atlas_result = @"@?";
            break;
            
        default:
            atlas_result = [NSString stringWithFormat:@"%c", atlas__primitiveType];
            break;
    }

    return atlas_result;
}

- (NSString *)atlas__typeStringForMembersWithVariableNamesToLevel:(NSInteger)atlas_level atlas_showObjectTypes:(BOOL)atlas_shouldShowObjectTypes;
{
    NSParameterAssert(atlas__primitiveType == '{' || atlas__primitiveType == '(');
    NSMutableString *atlas_str = [NSMutableString string];

    for (ObjCAtlasType *atlas_member in atlas__members) {
        if (atlas_member.atlas_variableName != nil && atlas_level > 0)
            [atlas_str appendFormat:@"\"%@\"", atlas_member.atlas_variableName];
        [atlas_str appendString:[atlas_member atlas__typeStringWithVariableNamesToLevel:atlas_level - 1 atlas_showObjectTypes:atlas_shouldShowObjectTypes]];
    }

    return atlas_str;
}

- (BOOL)atlas_canMergeWithType:(ObjCAtlasType *)atlas_otherType;
{
    if (self.atlas_isIDType && atlas_otherType.atlas_isNamedObject)
        return YES;

    if (self.atlas_isNamedObject && atlas_otherType.atlas_isIDType) {
        return YES;
    }

    if (atlas__primitiveType != atlas_otherType.atlas_primitiveType) {
        if (atlas_debugMerge) {
            NSLog(@"--------------------");
            NSLog(@"this: %@", self.atlas_typeString);
            NSLog(@"other: %@", atlas_otherType.atlas_typeString);
            NSLog(@"self isIDType? %u", self.atlas_isIDType);
            NSLog(@"self isNamedObject? %u", self.atlas_isNamedObject);
            NSLog(@"other isIDType? %u", atlas_otherType.atlas_isIDType);
            NSLog(@"other isNamedObject? %u", atlas_otherType.atlas_isNamedObject);
        }
        if (atlas_debugMerge) NSLog(@"%s, Can't merge because of type... %@ vs %@", atlas___cmd, self.atlas_typeString, atlas_otherType.atlas_typeString);
        return NO;
    }

    if (atlas__subtype != nil && [atlas__subtype atlas_canMergeWithType:atlas_otherType.atlas_subtype] == NO) {
        if (atlas_debugMerge) NSLog(@"%s, Can't merge subtype", atlas___cmd);
        return NO;
    }

    if (atlas__subtype == nil && atlas_otherType.atlas_subtype != nil) {
        if (atlas_debugMerge) NSLog(@"%s, This subtype is nil, other isn't.", atlas___cmd);
        return NO;
    }

    NSArray *atlas_otherMembers = atlas_otherType.atlas_members;
    NSUInteger atlas_count = [atlas__members count];
    NSUInteger atlas_otherCount = [atlas_otherMembers count];

    //NSLog(@"members: %p", members);
    //NSLog(@"otherMembers: %p", otherMembers);
    //NSLog(@"%s, count: %u, otherCount: %u", __cmd, count, otherCount);

    if (atlas_count != 0 && atlas_otherCount == 0) {
        if (atlas_debugMerge) NSLog(@"%s, count != 0 && otherCount is 0", atlas___cmd);
        return NO;
    }

    if (atlas_count != 0 && atlas_count != atlas_otherCount) {
        if (atlas_debugMerge) NSLog(@"%s, count != 0 && count != otherCount", atlas___cmd);
        return NO;
    }

    // count == 0 is ok: we just have a name in that case.
    if (atlas_count == atlas_otherCount) {
        for (NSUInteger atlas_index = 0; atlas_index < atlas_count; atlas_index++) { // Oooh
            ObjCAtlasType *atlas_thisMember = atlas__members[atlas_index];
            ObjCAtlasType *atlas_otherMember = atlas_otherMembers[atlas_index];

            ObjCAtlasTypeName *atlas_thisTypeName = atlas_thisMember.atlas_typeName;
            ObjCAtlasTypeName *atlas_otherTypeName = atlas_otherMember.atlas_typeName;
            NSString *atlas_thisVariableName = atlas_thisMember.atlas_variableName;
            NSString *atlas_otherVariableName = atlas_otherMember.atlas_variableName;

            // It seems to be okay if one of them didn't have a name
            if (atlas_thisTypeName != nil && atlas_otherTypeName != nil && [atlas_thisTypeName isEqual:atlas_otherTypeName] == NO) {
                if (atlas_debugMerge) NSLog(@"%s, typeName mismatch on member %lu", atlas___cmd, atlas_index);
                return NO;
            }

            if (atlas_thisVariableName != nil && atlas_otherVariableName != nil && [atlas_thisVariableName isEqual:atlas_otherVariableName] == NO) {
                if (atlas_debugMerge) NSLog(@"%s, variableName mismatch on member %lu", atlas___cmd, atlas_index);
                return NO;
            }

            if ([atlas_thisMember atlas_canMergeWithType:atlas_otherMember] == NO) {
                if (atlas_debugMerge) NSLog(@"%s, Can't merge member %lu", atlas___cmd, atlas_index);
                return NO;
            }
        }
    }

    return YES;
}

// Merge struct/union member names.  Should check using -canMergeWithType: first.
// Recursively merges, not just the top level.
- (void)atlas_mergeWithType:(ObjCAtlasType *)atlas_otherType;
{
    NSString *atlas_before = self.atlas_typeString;
    [self atlas__recursivelyMergeWithType:atlas_otherType];
    NSString *atlas_after = self.atlas_typeString;
    if (atlas_debugMerge) {
        NSLog(@"----------------------------------------");
        NSLog(@"%s", atlas___cmd);
        NSLog(@"before: %@", atlas_before);
        NSLog(@" after: %@", atlas_after);
        NSLog(@"----------------------------------------");
    }
}

- (void)atlas__recursivelyMergeWithType:(ObjCAtlasType *)atlas_otherType;
{
    if (self.atlas_isIDType && atlas_otherType.atlas_isNamedObject) {
        //NSLog(@"thisType: %@", [self typeString]);
        //NSLog(@"otherType: %@", [otherType typeString]);
        atlas__primitiveType = atlas_T_NAMED_OBJECT;
        atlas__typeName = [atlas_otherType.atlas_typeName copy];
        return;
    }

    if (self.atlas_isNamedObject && atlas_otherType.atlas_isIDType) {
        return;
    }

    if (atlas__primitiveType != atlas_otherType.atlas_primitiveType) {
        NSLog(@"Warning: Trying to merge different types in %s", atlas___cmd);
        return;
    }

    [atlas__subtype atlas__recursivelyMergeWithType:atlas_otherType.atlas_subtype];

    NSArray *atlas_otherMembers = atlas_otherType.atlas_members;
    NSUInteger atlas_count = [atlas__members count];
    NSUInteger atlas_otherCount = [atlas_otherMembers count];

    // The counts can be zero when we register structures that just have a name.  That happened while I was working on the
    // structure registration.
    if (atlas_otherCount == 0) {
        return;
    } else if (atlas_count == 0 && atlas_otherCount != 0) {
        NSParameterAssert(atlas__members != nil);
        [atlas__members removeAllObjects];
        [atlas__members addObjectsFromArray:atlas_otherMembers];
        //[self setMembers:otherMembers];
    } else if (atlas_count != atlas_otherCount) {
        // Not so bad after all.  Even kind of common.  Consider _flags.
        NSLog(@"Warning: Types have different number of members.  This is bad. (%lu vs %lu)", atlas_count, atlas_otherCount);
        NSLog(@"%@ vs %@", self.atlas_typeString, atlas_otherType.atlas_typeString);
        return;
    }

    //NSLog(@"****************************************");
    for (NSUInteger atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
        ObjCAtlasType *atlas_thisMember = atlas__members[atlas_index];
        ObjCAtlasType *atlas_otherMember = atlas_otherMembers[atlas_index];

        ObjCAtlasTypeName *atlas_thisTypeName = atlas_thisMember.atlas_typeName;
        ObjCAtlasTypeName *atlas_otherTypeName = atlas_otherMember.atlas_typeName;
        NSString *atlas_thisVariableName = atlas_thisMember.atlas_variableName;
        NSString *atlas_otherVariableName = atlas_otherMember.atlas_variableName;
        //NSLog(@"%d: type: %@ vs %@", index, thisTypeName, otherTypeName);
        //NSLog(@"%d: vari: %@ vs %@", index, thisVariableName, otherVariableName);

        if ((atlas_thisTypeName == nil && atlas_otherTypeName != nil) || (atlas_thisTypeName != nil && atlas_otherTypeName == nil)) {
            ; // It seems to be okay if one of them didn't have a name
            //NSLog(@"Warning: (1) type names don't match, %@ vs %@", thisTypeName, otherTypeName);
        } else if (atlas_thisTypeName != nil && [atlas_thisTypeName isEqual:atlas_otherTypeName] == NO) {
            NSLog(@"Warning: (2) type names don't match:\n\t%@ vs \n\t%@.", atlas_thisTypeName, atlas_otherTypeName);
            // In this case, we should skip the merge.
        }

        if (atlas_otherVariableName != nil) {
            if (atlas_thisVariableName == nil)
                atlas_thisMember.atlas_variableName = atlas_otherVariableName;
            else if ([atlas_thisVariableName isEqual:atlas_otherVariableName] == NO)
                NSLog(@"Warning: Different variable names for same member...");
        }

        [atlas_thisMember atlas__recursivelyMergeWithType:atlas_otherMember];
    }
}

- (NSArray *)atlas_memberVariableNames;
{
    NSMutableArray *atlas_names = [[NSMutableArray alloc] init];
    [atlas__members enumerateObjectsUsingBlock:^(ObjCAtlasType *atlas_memberType, NSUInteger atlas_index, BOOL *atlas_stop){
        if (atlas_memberType.atlas_variableName != nil)
            [atlas_names addObject:atlas_memberType.atlas_variableName];
    }];
    
    return [atlas_names copy];
}

- (void)atlas_generateMemberNames;
{
    if (atlas__primitiveType == '{' || atlas__primitiveType == '(') {
        NSSet *atlas_usedNames = [[NSSet alloc] initWithArray:self.atlas_memberVariableNames];

        NSUInteger atlas_number = 1;
        for (ObjCAtlasType *atlas_member in atlas__members) {
            [atlas_member atlas_generateMemberNames];

            // Bitfields don't need a name.
            if (atlas_member.atlas_variableName == nil && atlas_member.atlas_primitiveType != 'b') {
                NSString *atlas_name;
                do {
                    atlas_name = [NSString stringWithFormat:@"_field%lu", atlas_number++];
                } while ([atlas_usedNames containsObject:atlas_name]);
                atlas_member.atlas_variableName = atlas_name;
            }
        }
    }

    [atlas__subtype atlas_generateMemberNames];
}

- (NSString *)atlas_blockSignatureString;
{
    NSMutableString *atlas_blockSignatureString = [[NSMutableString alloc] init];
    ObjCAtlasTypeFormatter *atlas_blockSignatureTypeFormatter = [[ObjCAtlasTypeFormatter alloc] init];
    atlas_blockSignatureTypeFormatter.atlas_shouldExpand = NO;
    atlas_blockSignatureTypeFormatter.atlas_shouldAutoExpand = NO;
    atlas_blockSignatureTypeFormatter.atlas_baseLevel = 0;
    [self.atlas_types enumerateObjectsUsingBlock:^(ObjCAtlasType *atlas_type, NSUInteger atlas_idx, BOOL *atlas_stop) {
        if (atlas_idx != 1)
            [atlas_blockSignatureString appendString:[atlas_blockSignatureTypeFormatter atlas_formatVariable:nil atlas_type:atlas_type]];
        else
            [atlas_blockSignatureString appendString:@"(^)"];
        
        BOOL atlas_isLastType = atlas_idx == [self.atlas_types count] - 1;
        
        if (atlas_idx == 0)
            [atlas_blockSignatureString appendString:@" "];
        else if (atlas_idx == 1)
            [atlas_blockSignatureString appendString:@"("];
        else if (atlas_idx >= 2 && !atlas_isLastType)
            [atlas_blockSignatureString appendString:@", "];
        
        if (atlas_isLastType) {
            if ([self.atlas_types count] == 2) {
                [atlas_blockSignatureString appendString:@"void"];
            }
            [atlas_blockSignatureString appendString:@")"];
        }
    }];
    
    return atlas_blockSignatureString;
}

#pragma mark - Phase 0

- (void)atlas_phase:(NSUInteger)atlas_phase atlas_registerTypesWithObject:(ObjCAtlasTypeController *)atlas_typeController atlas_usedInMethod:(BOOL)atlas_isUsedInMethod;
{
    if (atlas_phase == 0) {
        [self atlas_phase0RegisterStructuresWithObject:atlas_typeController atlas_usedInMethod:atlas_isUsedInMethod];
    }
}

// Just top level structures
- (void)atlas_phase0RegisterStructuresWithObject:(ObjCAtlasTypeController *)atlas_typeController atlas_usedInMethod:(BOOL)atlas_isUsedInMethod;
{
    // ^{ComponentInstanceRecord=}
    if (atlas__subtype != nil)
        [atlas__subtype atlas_phase0RegisterStructuresWithObject:atlas_typeController atlas_usedInMethod:atlas_isUsedInMethod];

    if ((atlas__primitiveType == '{' || atlas__primitiveType == '(') && [atlas__members count] > 0) {
        [atlas_typeController atlas_phase0RegisterStructure:self atlas_usedInMethod:atlas_isUsedInMethod];
    } else if (self.atlas_primitiveType == atlas_T_FUNCTION_POINTER_TYPE && self.atlas_types == nil) {
        atlas_typeController.atlas_hasUnknownFunctionPointers = YES;
    } else if (self.atlas_primitiveType == atlas_T_BLOCK_TYPE && self.atlas_types == nil) {
        atlas_typeController.atlas_hasUnknownBlocks = YES;
    }
}

- (void)atlas_phase0RecursivelyFixStructureNames:(BOOL)atlas_flag;
{
    [atlas__subtype atlas_phase0RecursivelyFixStructureNames:atlas_flag];

    if ([atlas__typeName.name hasPrefix:@"$"]) {
        if (atlas_flag) NSLog(@"%s, changing type name %@ to ?", atlas___cmd, atlas__typeName.name);
        atlas__typeName.name = @"?";
    }

    for (ObjCAtlasType *atlas_member in atlas__members)
        [atlas_member atlas_phase0RecursivelyFixStructureNames:atlas_flag];
}

#pragma mark - Phase 1

// Recursively go through type, registering structs/unions.
- (void)atlas_phase1RegisterStructuresWithObject:(ObjCAtlasTypeController *)atlas_typeController;
{
    // ^{ComponentInstanceRecord=}
    if (atlas__subtype != nil)
        [atlas__subtype atlas_phase1RegisterStructuresWithObject:atlas_typeController];

    if ((atlas__primitiveType == '{' || atlas__primitiveType == '(') && [atlas__members count] > 0) {
        [atlas_typeController atlas_phase1RegisterStructure:self];
        for (ObjCAtlasType *atlas_member in atlas__members)
            [atlas_member atlas_phase1RegisterStructuresWithObject:atlas_typeController];
    }
}

#pragma mark - Phase 2

// This wraps the recursive method, optionally logging if anything changed.
- (void)atlas_phase2MergeWithTypeController:(ObjCAtlasTypeController *)atlas_typeController atlas_debug:(BOOL)atlas_phase2Debug;
{
    NSString *atlas_before = self.atlas_typeString;
    [self atlas__phase2MergeWithTypeController:atlas_typeController atlas_debug:atlas_phase2Debug];
    NSString *atlas_after = self.atlas_typeString;
    if (atlas_phase2Debug && [atlas_before isEqualToString:atlas_after] == NO) {
        NSLog(@"----------------------------------------");
        NSLog(@"%s, merge changed type", atlas___cmd);
        NSLog(@"before: %@", atlas_before);
        NSLog(@" after: %@", atlas_after);
    }
}

// Recursive, bottom-up
- (void)atlas__phase2MergeWithTypeController:(ObjCAtlasTypeController *)atlas_typeController atlas_debug:(BOOL)atlas_phase2Debug;
{
    [atlas__subtype atlas__phase2MergeWithTypeController:atlas_typeController atlas_debug:atlas_phase2Debug];

    for (ObjCAtlasType *atlas_member in atlas__members)
        [atlas_member atlas__phase2MergeWithTypeController:atlas_typeController atlas_debug:atlas_phase2Debug];

    if ((atlas__primitiveType == '{' || atlas__primitiveType == '(') && [atlas__members count] > 0) {
        ObjCAtlasType *atlas_phase2Type = [atlas_typeController atlas_phase2ReplacementForType:self];
        if (atlas_phase2Type != nil) {
            // >0 members so we don't try replacing things like... {_xmlNode=^{_xmlNode}}
            if ([atlas__members count] > 0 && [self atlas_canMergeWithType:atlas_phase2Type]) {
                [self atlas_mergeWithType:atlas_phase2Type];
            } else {
                if (atlas_phase2Debug) {
                    NSLog(@"Found phase2 type, but can't merge with it.");
                    NSLog(@"this: %@", [self atlas_typeString]);
                    NSLog(@"that: %@", [atlas_phase2Type atlas_typeString]);
                }
            }
        }
    }
}

#pragma mark - Phase 3

- (void)atlas_phase3RegisterWithTypeController:(ObjCAtlasTypeController *)atlas_typeController;
{
    [atlas__subtype atlas_phase3RegisterWithTypeController:atlas_typeController];

    if (atlas__primitiveType == '{' || atlas__primitiveType == '(') {
        [atlas_typeController atlas_phase3RegisterStructure:self /*count:1 usedInMethod:NO*/];
    }
}

- (void)atlas_phase3RegisterMembersWithTypeController:(ObjCAtlasTypeController *)atlas_typeController;
{
    //NSLog(@" > %s %@", __cmd, [self typeString]);
    for (ObjCAtlasType *atlas_member in atlas__members) {
        [atlas_member atlas_phase3RegisterWithTypeController:atlas_typeController];
    }
    //NSLog(@"<  %s", __cmd);
}

// Bottom-up
- (void)atlas_phase3MergeWithTypeController:(ObjCAtlasTypeController *)atlas_typeController;
{
    [atlas__subtype atlas_phase3MergeWithTypeController:atlas_typeController];

    for (ObjCAtlasType *atlas_member in atlas__members)
        [atlas_member atlas_phase3MergeWithTypeController:atlas_typeController];

    if ((atlas__primitiveType == '{' || atlas__primitiveType == '(') && [atlas__members count] > 0) {
        ObjCAtlasType *atlas_phase3Type = [atlas_typeController atlas_phase3ReplacementForType:self];
        if (atlas_phase3Type != nil) {
            // >0 members so we don't try replacing things like... {_xmlNode=^{_xmlNode}}
            if ([atlas__members count] > 0 && [self atlas_canMergeWithType:atlas_phase3Type]) {
                [self atlas_mergeWithType:atlas_phase3Type];
            } else {
#if 0
                // This can happen in AU Lab, that struct has no members...
                NSLog(@"Found phase3 type, but can't merge with it.");
                NSLog(@"this: %@", self.typeString);
                NSLog(@"that: %@", phase3Type.typeString);
#endif
            }
        }
    }
}

@end
