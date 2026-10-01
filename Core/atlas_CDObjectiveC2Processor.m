// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDObjectiveC2Processor.h"

#import "atlas_CDMachOFile.h"
#import "atlas_CDSection.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDMachOFileDataCursor.h"
#import "atlas_CDOCClass.h"
#import "atlas_CDOCMethod.h"
#import "atlas_CDOCInstanceVariable.h"
#import "atlas_CDLCSymbolTable.h"
#import "atlas_CDOCCategory.h"
#import "atlas_CDClassDump.h"
#import "atlas_CDSymbol.h"
#import "atlas_CDOCProperty.h"
#import "atlas_cd_objc2.h"
#import "atlas_CDProtocolUniquer.h"
#import "atlas_CDOCClassReference.h"

@implementation ObjCAtlasObjectiveC2Processor
{
}

- (void)atlas_loadProtocols;
{
    ObjCAtlasSection *atlas_section = [[self.atlas_machOFile atlas_dataConstSegment] atlas_sectionWithName:@"__objc_protolist"];
    
    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithSection:atlas_section];
    while ([atlas_cursor isAtEnd] == NO)
        [self atlas_protocolAtAddress:[atlas_cursor atlas_readPtr]];
}

- (void)atlas_loadClasses;
{
    ObjCAtlasSection *atlas_section = [[self.atlas_machOFile atlas_dataConstSegment] atlas_sectionWithName:@"__objc_classlist"];
    
    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithSection:atlas_section];
    while ([atlas_cursor isAtEnd] == NO) {
        uint64_t atlas_val = [atlas_cursor atlas_readPtr];
        ObjCAtlasOCClass *atlas_aClass = [self atlas_loadClassAtAddress:atlas_val];
        if (atlas_aClass != nil) {
            [self atlas_addClass:atlas_aClass atlas_withAddress:atlas_val];
        }
    }
}

- (void)atlas_loadCategories;
{
    ObjCAtlasSection *atlas_section = [[self.atlas_machOFile atlas_dataConstSegment] atlas_sectionWithName:@"__objc_catlist"];
    
    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithSection:atlas_section];
    while ([atlas_cursor isAtEnd] == NO) {
        ObjCAtlasOCCategory *atlas_category = [self atlas_loadCategoryAtAddress:[atlas_cursor atlas_readPtr]];
        [self atlas_addCategory:atlas_category];
    }
}

- (ObjCAtlasOCProtocol *)atlas_protocolAtAddress:(uint64_t)atlas_address;
{
    if (atlas_address == 0)
        return nil;
    
    ObjCAtlasOCProtocol *atlas_protocol = [self.atlas_protocolUniquer atlas_protocolWithAddress:atlas_address];
    if (atlas_protocol == nil) {
        atlas_protocol = [[ObjCAtlasOCProtocol alloc] init];
        [self.atlas_protocolUniquer atlas_setProtocol:atlas_protocol atlas_withAddress:atlas_address];
        
        ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
        NSParameterAssert([atlas_cursor atlas_offset] != 0);
        
        struct atlas_cd_objc2_protocol atlas_objc2Protocol;
        atlas_objc2Protocol.atlas_isa                     = [atlas_cursor atlas_readPtr];
        atlas_objc2Protocol.atlas_name                    = [atlas_cursor atlas_readPtr];
        atlas_objc2Protocol.atlas_protocols               = [atlas_cursor atlas_readPtr];
        atlas_objc2Protocol.atlas_instanceMethods         = [atlas_cursor atlas_readPtr];
        atlas_objc2Protocol.atlas_classMethods            = [atlas_cursor atlas_readPtr];
        atlas_objc2Protocol.atlas_optionalInstanceMethods = [atlas_cursor atlas_readPtr];
        atlas_objc2Protocol.atlas_optionalClassMethods    = [atlas_cursor atlas_readPtr];
        atlas_objc2Protocol.atlas_instanceProperties      = [atlas_cursor atlas_readPtr];
        atlas_objc2Protocol.atlas_size                    = [atlas_cursor atlas_readInt32];
        atlas_objc2Protocol.atlas_flags                   = [atlas_cursor atlas_readInt32];
        atlas_objc2Protocol.atlas_extendedMethodTypes     = 0;
        
        ObjCAtlasMachOFileDataCursor *atlas_extendedMethodTypesCursor = nil;
        BOOL atlas_hasExtendedMethodTypesField = atlas_objc2Protocol.atlas_size > 8 * [self.atlas_machOFile atlas_ptrSize] + 2 * sizeof(uint32_t);
        if (atlas_hasExtendedMethodTypesField) {
            atlas_objc2Protocol.atlas_extendedMethodTypes = [atlas_cursor atlas_readPtr];
            if (atlas_objc2Protocol.atlas_extendedMethodTypes != 0) {
                atlas_extendedMethodTypesCursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_objc2Protocol.atlas_extendedMethodTypes];
                NSParameterAssert([atlas_extendedMethodTypesCursor atlas_offset] != 0);
            }
        }
        
        //NSLog(@"----------------------------------------");
        //NSLog(@"%016lx %016lx %016lx %016lx", objc2Protocol.isa, objc2Protocol.name, objc2Protocol.protocols, objc2Protocol.instanceMethods);
        //NSLog(@"%016lx %016lx %016lx %016lx", objc2Protocol.classMethods, objc2Protocol.optionalInstanceMethods, objc2Protocol.optionalClassMethods, objc2Protocol.instanceProperties);
        
        NSString *atlas_str = [self.atlas_machOFile atlas_stringAtAddress:atlas_objc2Protocol.atlas_name];
        [atlas_protocol setName:atlas_str];
        
        if (atlas_objc2Protocol.atlas_protocols != 0) {
            [atlas_cursor atlas_setAddress:atlas_objc2Protocol.atlas_protocols];
            uint64_t atlas_count = [atlas_cursor atlas_readPtr];
            for (uint64_t atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
                uint64_t atlas_val = [atlas_cursor atlas_readPtr];
                ObjCAtlasOCProtocol *atlas_anotherProtocol = [self atlas_protocolAtAddress:atlas_val];
                if (atlas_anotherProtocol != nil) {
                    [atlas_protocol atlas_addProtocol:atlas_anotherProtocol];
                } else {
                    NSLog(@"Note: another protocol was nil.");
                }
            }
        }
        
        for (ObjCAtlasOCMethod *atlas_method in [self atlas_loadMethodsAtAddress:atlas_objc2Protocol.atlas_instanceMethods atlas_extendedMethodTypesCursor:atlas_extendedMethodTypesCursor])
            [atlas_protocol atlas_addInstanceMethod:atlas_method];
        
        for (ObjCAtlasOCMethod *atlas_method in [self atlas_loadMethodsAtAddress:atlas_objc2Protocol.atlas_classMethods atlas_extendedMethodTypesCursor:atlas_extendedMethodTypesCursor])
            [atlas_protocol atlas_addClassMethod:atlas_method];
        
        for (ObjCAtlasOCMethod *atlas_method in [self atlas_loadMethodsAtAddress:atlas_objc2Protocol.atlas_optionalInstanceMethods atlas_extendedMethodTypesCursor:atlas_extendedMethodTypesCursor])
            [atlas_protocol atlas_addOptionalInstanceMethod:atlas_method];
        
        for (ObjCAtlasOCMethod *atlas_method in [self atlas_loadMethodsAtAddress:atlas_objc2Protocol.atlas_optionalClassMethods atlas_extendedMethodTypesCursor:atlas_extendedMethodTypesCursor])
            [atlas_protocol atlas_addOptionalClassMethod:atlas_method];
        
        for (ObjCAtlasOCProperty *atlas_property in [self atlas_loadPropertiesAtAddress:atlas_objc2Protocol.atlas_instanceProperties])
            [atlas_protocol atlas_addProperty:atlas_property];
    }
    
    return atlas_protocol;
}

- (ObjCAtlasOCCategory *)atlas_loadCategoryAtAddress:(uint64_t)atlas_address;
{
    if (atlas_address == 0)
        return nil;
    
    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
    NSParameterAssert([atlas_cursor atlas_offset] != 0);
    
    struct atlas_cd_objc2_category atlas_objc2Category;
    atlas_objc2Category.atlas_name               = [atlas_cursor atlas_readPtr];
    atlas_objc2Category.atlas_class              = [atlas_cursor atlas_readPtr];
    atlas_objc2Category.atlas_instanceMethods    = [atlas_cursor atlas_readPtr];
    atlas_objc2Category.atlas_classMethods       = [atlas_cursor atlas_readPtr];
    atlas_objc2Category.atlas_protocols          = [atlas_cursor atlas_readPtr];
    atlas_objc2Category.atlas_instanceProperties = [atlas_cursor atlas_readPtr];
    atlas_objc2Category.atlas_v7                 = [atlas_cursor atlas_readPtr];
    atlas_objc2Category.atlas_v8                 = [atlas_cursor atlas_readPtr];
    //NSLog(@"----------------------------------------");
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Category.name, objc2Category.class, objc2Category.instanceMethods, objc2Category.classMethods);
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Category.protocols, objc2Category.instanceProperties, objc2Category.v7, objc2Category.v8);
    
    ObjCAtlasOCCategory *atlas_category = [[ObjCAtlasOCCategory alloc] init];
    NSString *atlas_str = [self.atlas_machOFile atlas_stringAtAddress:atlas_objc2Category.atlas_name];
    [atlas_category setName:atlas_str];
    
    for (ObjCAtlasOCMethod *atlas_method in [self atlas_loadMethodsAtAddress:atlas_objc2Category.atlas_instanceMethods])
        [atlas_category atlas_addInstanceMethod:atlas_method];
    
    for (ObjCAtlasOCMethod *atlas_method in [self atlas_loadMethodsAtAddress:atlas_objc2Category.atlas_classMethods])
        [atlas_category atlas_addClassMethod:atlas_method];

    for (ObjCAtlasOCProtocol *atlas_protocol in [self.atlas_protocolUniquer atlas_uniqueProtocolsAtAddresses:[self atlas_protocolAddressListAtAddress:atlas_objc2Category.atlas_protocols]])
        [atlas_category atlas_addProtocol:atlas_protocol];
    
    for (ObjCAtlasOCProperty *atlas_property in [self atlas_loadPropertiesAtAddress:atlas_objc2Category.atlas_instanceProperties])
        [atlas_category atlas_addProperty:atlas_property];
    
    {
        uint64_t atlas_classNameAddress = atlas_address + [self.atlas_machOFile atlas_ptrSize];
        
        NSString *atlas_externalClassName = nil;
        if ([self.atlas_machOFile atlas_hasRelocationEntryForAddress2:atlas_classNameAddress]) {
            atlas_externalClassName = [self.atlas_machOFile atlas_externalClassNameForAddress2:atlas_classNameAddress];
            //NSLog(@"category: got external class name (2): %@", [category className]);
        } else if ([self.atlas_machOFile atlas_hasRelocationEntryForAddress:atlas_classNameAddress]) {
            atlas_externalClassName = [self.atlas_machOFile atlas_externalClassNameForAddress:atlas_classNameAddress];
            //NSLog(@"category: got external class name (1): %@", [aClass className]);
        } else if (atlas_objc2Category.atlas_class != 0) {
            ObjCAtlasOCClass *atlas_aClass = [self atlas_classWithAddress:atlas_objc2Category.atlas_class];
            atlas_category.atlas_classRef = [[ObjCAtlasOCClassReference alloc] initAtlasWithClassObject:atlas_aClass];
        }
        
        if (atlas_externalClassName != nil) {
            ObjCAtlasSymbol *atlas_classSymbol = [[self.atlas_machOFile atlas_symbolTable] atlas_symbolForExternalClassName:atlas_externalClassName];
            if (atlas_classSymbol != nil)
                atlas_category.atlas_classRef = [[ObjCAtlasOCClassReference alloc] initAtlasWithClassSymbol:atlas_classSymbol];
            else
                atlas_category.atlas_classRef = [[ObjCAtlasOCClassReference alloc] initAtlasWithClassName:atlas_externalClassName];
        }
    }
    
    return atlas_category;
}

- (ObjCAtlasOCClass *)atlas_loadClassAtAddress:(uint64_t)atlas_address;
{
    if (atlas_address == 0)
        return nil;
    
    ObjCAtlasOCClass *atlas_class = [self atlas_classWithAddress:atlas_address];
    if (atlas_class)
        return atlas_class;
    
    //NSLog(@"%s, address=%016lx", __cmd, address);
    
    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
    NSParameterAssert([atlas_cursor atlas_offset] != 0);
    
    struct atlas_cd_objc2_class atlas_objc2Class;
    atlas_objc2Class.atlas_isa        = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_superclass = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_cache      = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_vtable     = [atlas_cursor atlas_readPtr];

    uint64_t atlas_value        = [atlas_cursor atlas_readPtr];
    atlas_class.atlas_isSwiftClass    = (atlas_value & 0x1) != 0;
    atlas_objc2Class.atlas_data       = atlas_value & ~7;

    atlas_objc2Class.atlas_reserved1  = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_reserved2  = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_reserved3  = [atlas_cursor atlas_readPtr];
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.isa, objc2Class.superclass, objc2Class.cache, objc2Class.vtable);
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.data, objc2Class.reserved1, objc2Class.reserved2, objc2Class.reserved3);
    
    NSParameterAssert(atlas_objc2Class.atlas_data != 0);
    [atlas_cursor atlas_setAddress:atlas_objc2Class.atlas_data];

    struct atlas_cd_objc2_class_ro_t atlas_objc2ClassData;
    atlas_objc2ClassData.atlas_flags         = [atlas_cursor atlas_readInt32];
    atlas_objc2ClassData.atlas_instanceStart = [atlas_cursor atlas_readInt32];
    atlas_objc2ClassData.atlas_instanceSize  = [atlas_cursor atlas_readInt32];
    if ([self.atlas_machOFile atlas_uses64BitABI])
        atlas_objc2ClassData.atlas_reserved  = [atlas_cursor atlas_readInt32];
    else
        atlas_objc2ClassData.atlas_reserved = 0;
    
    atlas_objc2ClassData.atlas_ivarLayout     = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_name           = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_baseMethods    = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_baseProtocols  = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_ivars          = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_weakIvarLayout = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_baseProperties = [atlas_cursor atlas_readPtr];
    
    //NSLog(@"%08x %08x %08x %08x", objc2ClassData.flags, objc2ClassData.instanceStart, objc2ClassData.instanceSize, objc2ClassData.reserved);
    
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2ClassData.ivarLayout, objc2ClassData.name, objc2ClassData.baseMethods, objc2ClassData.baseProtocols);
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2ClassData.ivars, objc2ClassData.weakIvarLayout, objc2ClassData.baseProperties);
    NSString *atlas_str = [self.atlas_machOFile atlas_stringAtAddress:atlas_objc2ClassData.atlas_name];
    //NSLog(@"name = %@", str);
    
    ObjCAtlasOCClass *atlas_aClass = [[ObjCAtlasOCClass alloc] init];
    [atlas_aClass setName:atlas_str];
    
    for (ObjCAtlasOCMethod *atlas_method in [self atlas_loadMethodsAtAddress:atlas_objc2ClassData.atlas_baseMethods])
        [atlas_aClass atlas_addInstanceMethod:atlas_method];
    
    atlas_aClass.atlas_instanceVariables = [self atlas_loadIvarsAtAddress:atlas_objc2ClassData.atlas_ivars];
    
    {
        ObjCAtlasSymbol *atlas_classSymbol = [[self.atlas_machOFile atlas_symbolTable] atlas_symbolForClassName:atlas_str];
        
        if (atlas_classSymbol != nil)
            atlas_aClass.atlas_isExported = [atlas_classSymbol isExternal];
    }
    
    {
        uint64_t atlas_classNameAddress = atlas_address + [self.atlas_machOFile atlas_ptrSize];
        
        NSString *atlas_superClassName = nil;
        if ([self.atlas_machOFile atlas_hasRelocationEntryForAddress2:atlas_classNameAddress]) {
            atlas_superClassName = [self.atlas_machOFile atlas_externalClassNameForAddress2:atlas_classNameAddress];
            //NSLog(@"class: got external class name (2): %@", [aClass superClassName]);
        } else if ([self.atlas_machOFile atlas_hasRelocationEntryForAddress:atlas_classNameAddress]) {
            atlas_superClassName = [self.atlas_machOFile atlas_externalClassNameForAddress:atlas_classNameAddress];
            //NSLog(@"class: got external class name (1): %@", [aClass superClassName]);
        } else if (atlas_objc2Class.atlas_superclass != 0) {
            ObjCAtlasOCClass *atlas_sc = [self atlas_loadClassAtAddress:atlas_objc2Class.atlas_superclass];
            atlas_aClass.atlas_superClassRef = [[ObjCAtlasOCClassReference alloc] initAtlasWithClassObject:atlas_sc];
        }
        
        if (atlas_superClassName) {
            ObjCAtlasSymbol *atlas_superClassSymbol = [[self.atlas_machOFile atlas_symbolTable] atlas_symbolForExternalClassName:atlas_superClassName];
            if (atlas_superClassSymbol)
                atlas_aClass.atlas_superClassRef = [[ObjCAtlasOCClassReference alloc] initAtlasWithClassSymbol:atlas_superClassSymbol];
            else
                atlas_aClass.atlas_superClassRef = [[ObjCAtlasOCClassReference alloc] initAtlasWithClassName:atlas_superClassName];
        }
    }
    
    for (ObjCAtlasOCMethod *atlas_method in [self atlas_loadMethodsOfMetaClassAtAddress:atlas_objc2Class.atlas_isa])
        [atlas_aClass atlas_addClassMethod:atlas_method];
    
    // Process protocols
    for (ObjCAtlasOCProtocol *atlas_protocol in [self.atlas_protocolUniquer atlas_uniqueProtocolsAtAddresses:[self atlas_protocolAddressListAtAddress:atlas_objc2ClassData.atlas_baseProtocols]])
        [atlas_aClass atlas_addProtocol:atlas_protocol];
    
    for (ObjCAtlasOCProperty *atlas_property in [self atlas_loadPropertiesAtAddress:atlas_objc2ClassData.atlas_baseProperties])
        [atlas_aClass atlas_addProperty:atlas_property];
    
    return atlas_aClass;
}

- (NSArray *)atlas_loadPropertiesAtAddress:(uint64_t)atlas_address;
{
    NSMutableArray *atlas_properties = [NSMutableArray array];
    if (atlas_address != 0) {
        struct atlas_cd_objc2_list_header atlas_listHeader;
        
        ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
        NSParameterAssert([atlas_cursor atlas_offset] != 0);
        //NSLog(@"property list data offset: %lu", [cursor offset]);
        
        atlas_listHeader.atlas_entsize = [atlas_cursor atlas_readInt32];
        atlas_listHeader.atlas_count = [atlas_cursor atlas_readInt32];
        NSParameterAssert(atlas_listHeader.atlas_entsize == 2 * [self.atlas_machOFile atlas_ptrSize]);
        
        for (uint32_t atlas_index = 0; atlas_index < atlas_listHeader.atlas_count; atlas_index++) {
            struct atlas_cd_objc2_property atlas_objc2Property;
            
            atlas_objc2Property.atlas_name = [atlas_cursor atlas_readPtr];
            atlas_objc2Property.atlas_attributes = [atlas_cursor atlas_readPtr];
            NSString *atlas_name = [self.atlas_machOFile atlas_stringAtAddress:atlas_objc2Property.atlas_name];
            NSString *atlas_attributes = [self.atlas_machOFile atlas_stringAtAddress:atlas_objc2Property.atlas_attributes];
            
            ObjCAtlasOCProperty *atlas_property = [[ObjCAtlasOCProperty alloc] initAtlasWithName:atlas_name atlas_attributes:atlas_attributes];
            [atlas_properties addObject:atlas_property];
        }
    }
    
    return atlas_properties;
}

// This just gets the methods.
- (NSArray *)atlas_loadMethodsOfMetaClassAtAddress:(uint64_t)atlas_address;
{
    if (atlas_address == 0)
        return nil;
    
    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
    NSParameterAssert([atlas_cursor atlas_offset] != 0);
    
    struct atlas_cd_objc2_class atlas_objc2Class;
    atlas_objc2Class.atlas_isa        = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_superclass = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_cache      = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_vtable     = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_data       = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_reserved1  = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_reserved2  = [atlas_cursor atlas_readPtr];
    atlas_objc2Class.atlas_reserved3  = [atlas_cursor atlas_readPtr];
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.isa, objc2Class.superclass, objc2Class.cache, objc2Class.vtable);
    //NSLog(@"%016lx %016lx %016lx %016lx", objc2Class.data, objc2Class.reserved1, objc2Class.reserved2, objc2Class.reserved3);
    
    NSParameterAssert(atlas_objc2Class.atlas_data != 0);
    [atlas_cursor atlas_setAddress:atlas_objc2Class.atlas_data];

    struct atlas_cd_objc2_class_ro_t atlas_objc2ClassData;
    atlas_objc2ClassData.atlas_flags         = [atlas_cursor atlas_readInt32];
    atlas_objc2ClassData.atlas_instanceStart = [atlas_cursor atlas_readInt32];
    atlas_objc2ClassData.atlas_instanceSize  = [atlas_cursor atlas_readInt32];
    if ([self.atlas_machOFile atlas_uses64BitABI])
        atlas_objc2ClassData.atlas_reserved  = [atlas_cursor atlas_readInt32];
    else
        atlas_objc2ClassData.atlas_reserved = 0;
    
    atlas_objc2ClassData.atlas_ivarLayout     = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_name           = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_baseMethods    = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_baseProtocols  = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_ivars          = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_weakIvarLayout = [atlas_cursor atlas_readPtr];
    atlas_objc2ClassData.atlas_baseProperties = [atlas_cursor atlas_readPtr];
    
    return [self atlas_loadMethodsAtAddress:atlas_objc2ClassData.atlas_baseMethods];
}

- (NSArray *)atlas_loadMethodsAtAddress:(uint64_t)atlas_address;
{
    return [self atlas_loadMethodsAtAddress:atlas_address atlas_extendedMethodTypesCursor:nil];
}

- (NSArray *)atlas_loadMethodsAtAddress:(uint64_t)atlas_address atlas_extendedMethodTypesCursor:(ObjCAtlasMachOFileDataCursor *)atlas_extendedMethodTypesCursor;
{
    NSMutableArray *atlas_methods = [NSMutableArray array];
    
    if (atlas_address != 0) {
        ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
        NSParameterAssert([atlas_cursor atlas_offset] != 0);
        //NSLog(@"method list data offset: %lu", [cursor offset]);
        
        struct atlas_cd_objc2_list_header atlas_listHeader;
        
        // See getEntsize() from http://www.opensource.apple.com/source/objc4/objc4-532.2/runtime/objc-runtime-new.h
        atlas_listHeader.atlas_entsize = [atlas_cursor atlas_readInt32] & ~(uint32_t)3;
        atlas_listHeader.atlas_count   = [atlas_cursor atlas_readInt32];
        NSParameterAssert(atlas_listHeader.atlas_entsize == 3 * [self.atlas_machOFile atlas_ptrSize]);
        
        for (uint32_t atlas_index = 0; atlas_index < atlas_listHeader.atlas_count; atlas_index++) {
            struct atlas_cd_objc2_method atlas_objc2Method;
            
            atlas_objc2Method.atlas_name  = [atlas_cursor atlas_readPtr];
            atlas_objc2Method.atlas_types = [atlas_cursor atlas_readPtr];
            atlas_objc2Method.atlas_imp   = [atlas_cursor atlas_readPtr];
            NSString *atlas_name    = [self.atlas_machOFile atlas_stringAtAddress:atlas_objc2Method.atlas_name];
            NSString *atlas_types   = [self.atlas_machOFile atlas_stringAtAddress:atlas_objc2Method.atlas_types];
            
            if (atlas_extendedMethodTypesCursor) {
                uint64_t atlas_extendedMethodTypes = [atlas_extendedMethodTypesCursor atlas_readPtr];
                atlas_types = [self.atlas_machOFile atlas_stringAtAddress:atlas_extendedMethodTypes];
            }
            
            //NSLog(@"%3u: %016lx %016lx %016lx", index, objc2Method.name, objc2Method.types, objc2Method.imp);
            //NSLog(@"name: %@", name);
            //NSLog(@"types: %@", types);
            
            ObjCAtlasOCMethod *atlas_method = [[ObjCAtlasOCMethod alloc] initAtlasWithName:atlas_name atlas_typeString:atlas_types atlas_address:atlas_objc2Method.atlas_imp];
            [atlas_methods addObject:atlas_method];
        }
    }
    
    return [atlas_methods atlas_reversedArray];
}

- (NSArray *)atlas_loadIvarsAtAddress:(uint64_t)atlas_address;
{
    NSMutableArray *atlas_ivars = [NSMutableArray array];
    
    if (atlas_address != 0) {
        ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
        NSParameterAssert([atlas_cursor atlas_offset] != 0);
        //NSLog(@"ivar list data offset: %lu", [cursor offset]);
        
        struct atlas_cd_objc2_list_header atlas_listHeader;
        
        atlas_listHeader.atlas_entsize = [atlas_cursor atlas_readInt32];
        atlas_listHeader.atlas_count = [atlas_cursor atlas_readInt32];
        NSParameterAssert(atlas_listHeader.atlas_entsize == 3 * [self.atlas_machOFile atlas_ptrSize] + 2 * sizeof(uint32_t));
        
        for (uint32_t atlas_index = 0; atlas_index < atlas_listHeader.atlas_count; atlas_index++) {
            struct atlas_cd_objc2_ivar atlas_objc2Ivar;
            
            atlas_objc2Ivar.atlas_offset    = [atlas_cursor atlas_readPtr];
            atlas_objc2Ivar.atlas_name      = [atlas_cursor atlas_readPtr];
            atlas_objc2Ivar.atlas_type      = [atlas_cursor atlas_readPtr];
            atlas_objc2Ivar.atlas_alignment = [atlas_cursor atlas_readInt32];
            atlas_objc2Ivar.atlas_size      = [atlas_cursor atlas_readInt32];
            
            if (atlas_objc2Ivar.atlas_name != 0) {
                NSString *atlas_name       = [self.atlas_machOFile atlas_stringAtAddress:atlas_objc2Ivar.atlas_name];
                NSString *atlas_typeString = [self.atlas_machOFile atlas_stringAtAddress:atlas_objc2Ivar.atlas_type];
                ObjCAtlasMachOFileDataCursor *atlas_offsetCursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_objc2Ivar.atlas_offset];
                NSUInteger atlas_offset = (uint32_t)[atlas_offsetCursor atlas_readPtr]; // objc-runtime-new.h: "offset is 64-bit by accident" => restrict to 32-bit
                
                ObjCAtlasOCInstanceVariable *atlas_ivar = [[ObjCAtlasOCInstanceVariable alloc] initAtlasWithName:atlas_name atlas_typeString:atlas_typeString atlas_offset:atlas_offset];
                [atlas_ivars addObject:atlas_ivar];
            } else {
                //NSLog(@"%016lx %016lx %016lx  %08x %08x", objc2Ivar.offset, objc2Ivar.name, objc2Ivar.type, objc2Ivar.alignment, objc2Ivar.size);
            }
        }
    }
    
    return atlas_ivars;
}

// Returns list of NSNumber containing the protocol addresses
- (NSArray *)atlas_protocolAddressListAtAddress:(uint64_t)atlas_address;
{
    NSMutableArray *atlas_addresses = [[NSMutableArray alloc] init];;
    
    if (atlas_address != 0) {
        ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
        
        uint64_t atlas_count = [atlas_cursor atlas_readPtr];
        for (uint64_t atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
            uint64_t atlas_val = [atlas_cursor atlas_readPtr];
            if (atlas_val == 0) {
                NSLog(@"Warning: protocol address in protocol list was 0.");
            } else {
                [atlas_addresses addObject:[NSNumber numberWithUnsignedLongLong:atlas_val]];
            }
        }
    }
    
    return [atlas_addresses copy];
}

- (ObjCAtlasSection *)atlas_objcImageInfoSection;
{
    return [[self.atlas_machOFile atlas_dataConstSegment] atlas_sectionWithName:@"__objc_imageinfo"];
}

@end
