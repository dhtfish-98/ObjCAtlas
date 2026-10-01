// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

@class ObjCAtlasTypeController, ObjCAtlasTypeFormatter, ObjCAtlasTypeName;

@interface ObjCAtlasType : NSObject <NSCopying>

- (id)initAtlasSimpleType:(int)atlas_type;
- (id)initAtlasIDType:(ObjCAtlasTypeName *)atlas_name;
- (id)initAtlasIDType:(ObjCAtlasTypeName *)atlas_name atlas_withProtocols:(NSArray *)atlas_protocols;
- (id)initAtlasIDTypeWithProtocols:(NSArray *)atlas_protocols;
- (id)initAtlasStructType:(ObjCAtlasTypeName *)atlas_name atlas_members:(NSArray *)atlas_members;
- (id)initAtlasUnionType:(ObjCAtlasTypeName *)atlas_name atlas_members:(NSArray *)atlas_members;
- (id)initAtlasBitfieldType:(NSString *)atlas_bitfieldSize;
- (id)initAtlasArrayType:(ObjCAtlasType *)atlas_type atlas_count:(NSString *)atlas_count;
- (id)initAtlasPointerType:(ObjCAtlasType *)atlas_type;
- (id)initAtlasFunctionPointerType;
- (id)initAtlasBlockTypeWithTypes:(NSArray *)atlas_types;
- (id)initAtlasModifier:(int)atlas_modifier atlas_type:(ObjCAtlasType *)atlas_type;

@property (strong) NSString *atlas_variableName;

@property (nonatomic, readonly) int atlas_primitiveType;
@property (nonatomic, readonly) BOOL atlas_isIDType;
@property (nonatomic, readonly) BOOL atlas_isNamedObject;
@property (nonatomic, readonly) BOOL atlas_isTemplateType;

@property (nonatomic, readonly) ObjCAtlasType *atlas_subtype;
@property (nonatomic, readonly) ObjCAtlasTypeName *atlas_typeName;

@property (nonatomic, readonly) NSArray *atlas_members;
@property (nonatomic, readonly) NSArray *atlas_types;

@property (nonatomic, readonly) int atlas_typeIgnoringModifiers;
@property (nonatomic, readonly) NSUInteger atlas_structureDepth;

- (NSString *)atlas_formattedString:(NSString *)atlas_previousName atlas_formatter:(ObjCAtlasTypeFormatter *)atlas_typeFormatter atlas_level:(NSUInteger)atlas_level;

@property (nonatomic, readonly) NSString *atlas_typeString;
@property (nonatomic, readonly) NSString *atlas_bareTypeString;
@property (nonatomic, readonly) NSString *atlas_reallyBareTypeString;
@property (nonatomic, readonly) NSString *atlas_keyTypeString;


- (BOOL)atlas_canMergeWithType:(ObjCAtlasType *)atlas_otherType;
- (void)atlas_mergeWithType:(ObjCAtlasType *)atlas_otherType;

@property (nonatomic, readonly) NSArray *atlas_memberVariableNames;
- (void)atlas_generateMemberNames;

// Phase 0
- (void)atlas_phase:(NSUInteger)atlas_phase atlas_registerTypesWithObject:(ObjCAtlasTypeController *)atlas_typeController atlas_usedInMethod:(BOOL)atlas_isUsedInMethod;
- (void)atlas_phase0RecursivelyFixStructureNames:(BOOL)atlas_flag;

// Phase 1
- (void)atlas_phase1RegisterStructuresWithObject:(ObjCAtlasTypeController *)atlas_typeController;

// Phase 2
- (void)atlas_phase2MergeWithTypeController:(ObjCAtlasTypeController *)atlas_typeController atlas_debug:(BOOL)atlas_phase2Debug;

// Phase 3
- (void)atlas_phase3RegisterMembersWithTypeController:(ObjCAtlasTypeController *)atlas_typeController;
- (void)atlas_phase3MergeWithTypeController:(ObjCAtlasTypeController *)atlas_typeController;

@end
