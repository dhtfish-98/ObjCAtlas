// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDTypeController.h"

#import "atlas_CDStructureTable.h"
#import "atlas_CDClassDump.h"
#import "atlas_CDTypeFormatter.h"
#import "atlas_CDType.h"

static BOOL atlas_debug = NO;

@interface ObjCAtlasTypeController ()
@property (weak, readonly) ObjCAtlasClassDump *atlas_classDump;
@property (readonly) ObjCAtlasStructureTable *atlas_structureTable;
@property (readonly) ObjCAtlasStructureTable *atlas_unionTable;
@end

#pragma mark -

@implementation ObjCAtlasTypeController
{
    __weak ObjCAtlasClassDump *atlas__classDump; // passed during formatting, to get at options.
    __weak id <ObjCAtlasTypeControllerDelegate> atlas__delegate;
    
    ObjCAtlasTypeFormatter *atlas__ivarTypeFormatter;
    ObjCAtlasTypeFormatter *atlas__methodTypeFormatter;
    ObjCAtlasTypeFormatter *atlas__propertyTypeFormatter;
    ObjCAtlasTypeFormatter *atlas__structDeclarationTypeFormatter;
    
    ObjCAtlasStructureTable *atlas__structureTable;
    ObjCAtlasStructureTable *atlas__unionTable;
}

// Preserve the original explicit property storage after renaming.
@synthesize delegate = atlas__delegate;
@synthesize atlas_ivarTypeFormatter = atlas__ivarTypeFormatter;
@synthesize atlas_methodTypeFormatter = atlas__methodTypeFormatter;
@synthesize atlas_propertyTypeFormatter = atlas__propertyTypeFormatter;
@synthesize atlas_structDeclarationTypeFormatter = atlas__structDeclarationTypeFormatter;
@synthesize atlas_classDump = atlas__classDump;
@synthesize atlas_structureTable = atlas__structureTable;
@synthesize atlas_unionTable = atlas__unionTable;

- (id)initAtlasWithClassDump:(ObjCAtlasClassDump *)atlas_classDump;
{
    if ((self = [super init])) {
        atlas__classDump = atlas_classDump;
        
        atlas__ivarTypeFormatter = [[ObjCAtlasTypeFormatter alloc] init];
        atlas__ivarTypeFormatter.atlas_shouldExpand = NO;
        atlas__ivarTypeFormatter.atlas_shouldAutoExpand = YES;
        atlas__ivarTypeFormatter.atlas_baseLevel = 1;
        atlas__ivarTypeFormatter.atlas_typeController = self;
        
        atlas__methodTypeFormatter = [[ObjCAtlasTypeFormatter alloc] init];
        atlas__methodTypeFormatter.atlas_shouldExpand = NO;
        atlas__methodTypeFormatter.atlas_shouldAutoExpand = NO;
        atlas__methodTypeFormatter.atlas_baseLevel = 0;
        atlas__methodTypeFormatter.atlas_typeController = self;
        
        atlas__propertyTypeFormatter = [[ObjCAtlasTypeFormatter alloc] init];
        atlas__propertyTypeFormatter.atlas_shouldExpand = NO;
        atlas__propertyTypeFormatter.atlas_shouldAutoExpand = NO;
        atlas__propertyTypeFormatter.atlas_baseLevel = 0;
        atlas__propertyTypeFormatter.atlas_typeController = self;
        
        atlas__structDeclarationTypeFormatter = [[ObjCAtlasTypeFormatter alloc] init];
        atlas__structDeclarationTypeFormatter.atlas_shouldExpand = YES; // But don't expand named struct members...
        atlas__structDeclarationTypeFormatter.atlas_shouldAutoExpand = YES;
        atlas__structDeclarationTypeFormatter.atlas_baseLevel = 0;
        atlas__structDeclarationTypeFormatter.atlas_typeController = self; // But need to ignore some things?
        
        atlas__structureTable = [[ObjCAtlasStructureTable alloc] init];
        atlas__structureTable.atlas_anonymousBaseName = @"CDStruct_";
        atlas__structureTable.identifier = @"Structs";
        atlas__structureTable.atlas_typeController = self;
        
        atlas__unionTable = [[ObjCAtlasStructureTable alloc] init];
        atlas__unionTable.atlas_anonymousBaseName = @"CDUnion_";
        atlas__unionTable.identifier = @"Unions";
        atlas__unionTable.atlas_typeController = self;
        
        //[structureTable debugName:@"_xmlSAXHandler"];
        //[structureTable debugName:@"UCKeyboardTypeHeader"];
        //[structureTable debugName:@"UCKeyboardLayout"];
        //[structureTable debugName:@"ppd_group_s"];
        //[structureTable debugName:@"stat"];
        //[structureTable debugName:@"timespec"];
        //[structureTable debugName:@"AudioUnitEvent"];
        //[structureTable debugAnon:@"{?=II}"];
        //[structureTable debugName:@"_CommandStackEntry"];
        //[structureTable debugName:@"_flags"];
    }

    return self;
}

#pragma mark -

- (BOOL)atlas_shouldShowIvarOffsets;
{
    return self.atlas_classDump.atlas_shouldShowIvarOffsets;
}

- (BOOL)atlas_shouldShowMethodAddresses;
{
    return self.atlas_classDump.atlas_shouldShowMethodAddresses;
}

- (BOOL)atlas_targetArchUses64BitABI;
{
    return atlas_CDArchUses64BitABI(self.atlas_classDump.atlas_targetArch);
}

#pragma mark -

- (ObjCAtlasType *)atlas_typeFormatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_replacementForType:(ObjCAtlasType *)atlas_type;
{
#if 0
    if (type.type == '{') return [structureTable replacementForType:type];
    if (type.type == '(') return [unionTable     replacementForType:type];
#endif
    return nil;
}

- (NSString *)atlas_typeFormatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_typedefNameForStructure:(ObjCAtlasType *)atlas_structureType atlas_level:(NSUInteger)atlas_level;
{
    if (atlas_level == 0 && atlas_typeFormatter == self.atlas_structDeclarationTypeFormatter)
        return nil;

    if ([self atlas_shouldExpandType:atlas_structureType] == NO)
        return [self atlas_typedefNameForType:atlas_structureType];

    return nil;
}

- (void)atlas_typeFormatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_didReferenceClassName:(NSString *)atlas_name;
{
    if ([self.delegate respondsToSelector:@selector(typeController:didReferenceClassName:)])
        [self.delegate atlas_typeController:self atlas_didReferenceClassName:atlas_name];
}

- (void)atlas_typeFormatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_didReferenceProtocolNames:(NSArray *)atlas_names;
{
    if ([self.delegate respondsToSelector:@selector(typeController:didReferenceProtocolNames:)])
        [self.delegate atlas_typeController:self atlas_didReferenceProtocolNames:atlas_names];
}

#pragma mark -

- (void)atlas_appendStructuresToString:(NSMutableString *)atlas_resultString;
{
    if (self.atlas_hasUnknownFunctionPointers && self.atlas_hasUnknownBlocks) {
        [atlas_resultString appendString:@"#pragma mark Function Pointers and Blocks\n\n"];
    } else if (self.atlas_hasUnknownFunctionPointers) {
        [atlas_resultString appendString:@"#pragma mark Function Pointers\n\n"];
    } else if (self.atlas_hasUnknownBlocks) {
        [atlas_resultString appendString:@"#pragma mark Blocks\n\n"];
    }
    
    if (self.atlas_hasUnknownFunctionPointers) {
        [atlas_resultString appendFormat:@"typedef void (*CDUnknownFunctionPointerType)(void); // return type and parameters are unknown\n\n"];
    }
    
    if (self.atlas_hasUnknownBlocks) {
        [atlas_resultString appendFormat:@"typedef void (^CDUnknownBlockType)(void); // return type and parameters are unknown\n\n"];
    }
    
    [self.atlas_structureTable atlas_appendNamedStructuresToString:atlas_resultString atlas_formatter:self.atlas_structDeclarationTypeFormatter atlas_markName:@"Named Structures"];
    [self.atlas_structureTable atlas_appendTypedefsToString:atlas_resultString        atlas_formatter:self.atlas_structDeclarationTypeFormatter atlas_markName:@"Typedef'd Structures"];

    [self.atlas_unionTable atlas_appendNamedStructuresToString:atlas_resultString atlas_formatter:self.atlas_structDeclarationTypeFormatter atlas_markName:@"Named Unions"];
    [self.atlas_unionTable atlas_appendTypedefsToString:atlas_resultString        atlas_formatter:self.atlas_structDeclarationTypeFormatter atlas_markName:@"Typedef'd Unions"];
}

// Call this before calling generateMemberNames.
- (void)atlas_generateTypedefNames;
{
    [self.atlas_structureTable atlas_generateTypedefNames];
    [self.atlas_unionTable     atlas_generateTypedefNames];
}

- (void)atlas_generateMemberNames;
{
    [self.atlas_structureTable atlas_generateMemberNames];
    [self.atlas_unionTable     atlas_generateMemberNames];
}

#pragma mark - Run phase 1+

- (void)atlas_workSomeMagic;
{
    [self atlas_startPhase1];
    [self atlas_startPhase2];
    [self atlas_startPhase3];

    [self atlas_generateTypedefNames];
    [self atlas_generateMemberNames];

    if (atlas_debug) {
        NSMutableString *atlas_str = [NSMutableString string];
        [self.atlas_structureTable atlas_appendNamedStructuresToString:atlas_str atlas_formatter:self.atlas_structDeclarationTypeFormatter atlas_markName:@"Named Structures"];
        [self.atlas_unionTable     atlas_appendNamedStructuresToString:atlas_str atlas_formatter:self.atlas_structDeclarationTypeFormatter atlas_markName:@"Named Unions"];
        [atlas_str writeToFile:@"/tmp/out.struct" atomically:NO encoding:NSUTF8StringEncoding error:NULL];

        atlas_str = [NSMutableString string];
        [self.atlas_structureTable atlas_appendTypedefsToString:atlas_str atlas_formatter:self.atlas_structDeclarationTypeFormatter atlas_markName:@"Typedef'd Structures"];
        [self.atlas_unionTable     atlas_appendTypedefsToString:atlas_str atlas_formatter:self.atlas_structDeclarationTypeFormatter atlas_markName:@"Typedef'd Unions"];
        [atlas_str writeToFile:@"/tmp/out.typedef" atomically:NO encoding:NSUTF8StringEncoding error:NULL];
        //NSLog(@"str =\n%@", str);
    }
}

#pragma mark - Phase 0

- (void)atlas_phase0RegisterStructure:(ObjCAtlasType *)atlas_structure atlas_usedInMethod:(BOOL)atlas_isUsedInMethod;
{
    if (atlas_structure.atlas_primitiveType == '{') {
        [self.atlas_structureTable atlas_phase0RegisterStructure:atlas_structure atlas_usedInMethod:atlas_isUsedInMethod];
    } else if (atlas_structure.atlas_primitiveType == '(') {
        [self.atlas_unionTable     atlas_phase0RegisterStructure:atlas_structure atlas_usedInMethod:atlas_isUsedInMethod];
    } else {
        NSLog(@"%s, unknown structure type: %d", atlas___cmd, atlas_structure.atlas_primitiveType);
    }
}

- (void)atlas_endPhase:(NSUInteger)atlas_phase;
{
    if (atlas_phase == 0) {
        [self.atlas_structureTable atlas_finishPhase0];
        [self.atlas_unionTable     atlas_finishPhase0];
    }
}

#pragma mark - Phase 1

// Phase one builds a list of all of the named and unnamed structures.
// It does this by going through all the top level structures we found in phase 0.
- (void)atlas_startPhase1;
{
    //NSLog(@" > %s", __cmd);
    // Structures and unions can be nested, so do phase 1 on each table before finishing the phase.
    [self.atlas_structureTable atlas_runPhase1];
    [self.atlas_unionTable     atlas_runPhase1];

    [self.atlas_structureTable atlas_finishPhase1];
    [self.atlas_unionTable     atlas_finishPhase1];
    //NSLog(@"<  %s", __cmd);
}

- (void)atlas_phase1RegisterStructure:(ObjCAtlasType *)atlas_structure;
{
    if (atlas_structure.atlas_primitiveType == '{') {
        [self.atlas_structureTable atlas_phase1RegisterStructure:atlas_structure];
    } else if (atlas_structure.atlas_primitiveType == '(') {
        [self.atlas_unionTable atlas_phase1RegisterStructure:atlas_structure];
    } else {
        NSLog(@"%s, unknown structure type: %d", atlas___cmd, atlas_structure.atlas_primitiveType);
    }
}

#pragma mark - Phase 2

- (void)atlas_startPhase2;
{
    NSUInteger atlas_maxDepth = self.atlas_structureTable.atlas_phase1_maxDepth;
    if (atlas_maxDepth < self.atlas_unionTable.atlas_phase1_maxDepth)
        atlas_maxDepth = self.atlas_unionTable.atlas_phase1_maxDepth;

    if (atlas_debug) NSLog(@"max structure/union depth is: %lu", atlas_maxDepth);

    for (NSUInteger atlas_depth = 1; atlas_depth <= atlas_maxDepth; atlas_depth++) {
        [self.atlas_structureTable atlas_runPhase2AtDepth:atlas_depth];
        [self.atlas_unionTable     atlas_runPhase2AtDepth:atlas_depth];
    }

    //[self.structureTable logPhase2Info];
    [self.atlas_structureTable atlas_finishPhase2];
    [self.atlas_unionTable     atlas_finishPhase2];
}

- (void)atlas_startPhase3;
{
    // do phase2 merge on all the types from phase 0
    [self.atlas_structureTable atlas_phase2ReplacementOnPhase0];
    [self.atlas_unionTable     atlas_phase2ReplacementOnPhase0];

    // Any info referenced by a method, or with >1 reference, gets typedef'd.
    // - Generate name hash based on full type string at this point
    // - Then fill in unnamed fields

    // Print method/>1 ref names and typedefs
    // Go through all updated phase0_structureInfo types
    // - start merging these into a new table
    //   - If this is the first time a structure has been added:
    //     - add one reference for each subtype
    //   - otherwise just merge them.
    // - end result should be CDStructureInfos with counts and method reference flags
    [self.atlas_structureTable atlas_buildPhase3Exceptions];
    [self.atlas_unionTable     atlas_buildPhase3Exceptions];

    [self.atlas_structureTable atlas_runPhase3];
    [self.atlas_unionTable     atlas_runPhase3];

    [self.atlas_structureTable atlas_finishPhase3];
    [self.atlas_unionTable     atlas_finishPhase3];
    //[structureTable logPhase3Info];

    // - All named structures (minus exceptions like struct _flags) get declared at the top level
    // - All anonymous structures (minus exceptions) referenced by a method
    //                                            OR references >1 time gets typedef'd at the top and referenced by typedef subsequently
    // Celebrate!

    // Then... what do we do when printing ivars/method types?
    // CDTypeController - (BOOL)shouldExpandType:(CDType *)type;
    // CDTypeController - (NSString *)typedefNameForType:(CDType *)type;

    //NSLog(@"<  %s", __cmd);
}

- (ObjCAtlasType *)atlas_phase2ReplacementForType:(ObjCAtlasType *)atlas_type;
{
    if (atlas_type.atlas_primitiveType == '{') return [self.atlas_structureTable atlas_phase2ReplacementForType:atlas_type];
    if (atlas_type.atlas_primitiveType == '(') return [self.atlas_unionTable     atlas_phase2ReplacementForType:atlas_type];

    return nil;
}

- (void)atlas_phase3RegisterStructure:(ObjCAtlasType *)atlas_structure;
{
    //NSLog(@"%s, type= %@", __cmd, [aStructure typeString]);
    if (atlas_structure.atlas_primitiveType == '{') [self.atlas_structureTable atlas_phase3RegisterStructure:atlas_structure atlas_count:1 atlas_usedInMethod:NO];
    if (atlas_structure.atlas_primitiveType == '(') [self.atlas_unionTable     atlas_phase3RegisterStructure:atlas_structure atlas_count:1 atlas_usedInMethod:NO];
}

- (ObjCAtlasType *)atlas_phase3ReplacementForType:(ObjCAtlasType *)atlas_type;
{
    if (atlas_type.atlas_primitiveType == '{') return [self.atlas_structureTable atlas_phase3ReplacementForType:atlas_type];
    if (atlas_type.atlas_primitiveType == '(') return [self.atlas_unionTable     atlas_phase3ReplacementForType:atlas_type];

    return nil;
}

#pragma mark -

- (BOOL)atlas_shouldShowName:(NSString *)atlas_name;
{
    return [self.atlas_classDump atlas_shouldShowName:atlas_name];
}

- (BOOL)atlas_shouldExpandType:(ObjCAtlasType *)atlas_type;
{
    if (atlas_type.atlas_primitiveType == '{') return [self.atlas_structureTable atlas_shouldExpandType:atlas_type];
    if (atlas_type.atlas_primitiveType == '(') return [self.atlas_unionTable     atlas_shouldExpandType:atlas_type];

    return NO;
}

- (NSString *)atlas_typedefNameForType:(ObjCAtlasType *)atlas_type;
{
    if (atlas_type.atlas_primitiveType == '{') return [self.atlas_structureTable atlas_typedefNameForType:atlas_type];
    if (atlas_type.atlas_primitiveType == '(') return [self.atlas_unionTable     atlas_typedefNameForType:atlas_type];

    return nil;
}

@end
