// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDObjectiveC1Processor.h"

#include <mach-o/arch.h>

#import "atlas_CDClassDump.h"
#import "atlas_CDLCDylib.h"
#import "atlas_CDMachOFile.h"
#import "atlas_CDOCCategory.h"
#import "atlas_CDOCClass.h"
#import "atlas_CDOCInstanceVariable.h"
#import "atlas_CDOCMethod.h"
#import "atlas_CDOCModule.h"
#import "atlas_CDOCProtocol.h"
#import "atlas_CDOCSymtab.h"
#import "atlas_CDVisitor.h"
#import "atlas_CDProtocolUniquer.h"
#import "atlas_CDOCClassReference.h"

#import "atlas_CDSection.h"
#import "atlas_CDLCSegment.h"

// Section: __module_info
struct atlas_cd_objc_module {
    uint32_t atlas_version;
    uint32_t atlas_size;
    uint32_t atlas_name;
    uint32_t atlas_symtab;
};

// Section: __symbols
struct atlas_cd_objc_symtab
{
    uint32_t atlas_sel_ref_cnt;
    uint32_t atlas_refs; // not used until runtime?
    uint16_t atlas_cls_def_count;
    uint16_t atlas_cat_def_count;
    //long class_pointer;
};

// Section: __class
struct atlas_cd_objc_class
{
    uint32_t atlas_isa;
    uint32_t atlas_super_class;
    uint32_t atlas_name;
    uint32_t atlas_version;
    uint32_t atlas_info;
    uint32_t atlas_instance_size;
    uint32_t atlas_ivars;
    uint32_t atlas_methods;
    uint32_t atlas_cache;
    uint32_t atlas_protocols;
};

// Section: ??
struct atlas_cd_objc_category
{
    uint32_t atlas_category_name;
    uint32_t atlas_class_name;
    uint32_t atlas_methods;
    uint32_t atlas_class_methods;
    uint32_t atlas_protocols;
};

// Section: __instance_vars
struct atlas_cd_objc_ivar_list
{
    uint32_t atlas_ivar_count;
    // Followed by ivars
};

// Section: __instance_vars
struct atlas_cd_objc_ivar
{
    uint32_t atlas_name;
    uint32_t atlas_type;
    uint32_t atlas_offset;
};

// Section: __inst_meth
struct atlas_cd_objc_method_list
{
    uint32_t atlas__obsolete;
    uint32_t atlas_method_count;
    // Followed by methods
};

// Section: __inst_meth
struct atlas_cd_objc_method
{
    uint32_t atlas_name;
    uint32_t atlas_types;
    uint32_t atlas_imp;
};


struct atlas_cd_objc_protocol_list
{
    uint32_t atlas_next;
    uint32_t atlas_count;
    //uint32_t list;
};

struct atlas_cd_objc_protocol
{
    uint32_t atlas_isa;
    uint32_t atlas_protocol_name;
    uint32_t atlas_protocol_list;
    uint32_t atlas_instance_methods;
    uint32_t atlas_class_methods;
};

struct atlas_cd_objc_protocol_method_list
{
    uint32_t atlas_method_count;
    // Followed by methods
};

struct atlas_cd_objc_protocol_method
{
    uint32_t atlas_name;
    uint32_t atlas_types;
};

static BOOL atlas_debug = NO;

@implementation ObjCAtlasObjectiveC1Processor
{
    NSMutableArray *atlas__modules;
}

- (id)initAtlasWithMachOFile:(ObjCAtlasMachOFile *)atlas_machOFile;
{
    if ((self = [super initAtlasWithMachOFile:atlas_machOFile])) {
        atlas__modules = [[NSMutableArray alloc] init];
    }

    return self;
}

#pragma mark -

- (void)atlas_process;
{
    if ([self.atlas_machOFile atlas_isEncrypted] == NO && [self.atlas_machOFile atlas_canDecryptAllSegments]) {
        [super atlas_process];

        [self atlas_processModules];
    }
}

#pragma mark - Formerly private

- (void)atlas_processModules;
{
    ObjCAtlasSection *atlas_moduleSection = [[self.atlas_machOFile atlas_segmentWithName:@"__OBJC"] atlas_sectionWithName:@"__module_info"];

    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithSection:atlas_moduleSection];
    while ([atlas_cursor isAtEnd] == NO) {
        struct atlas_cd_objc_module atlas_objcModule;

        atlas_objcModule.atlas_version = [atlas_cursor atlas_readInt32];
        atlas_objcModule.atlas_size    = [atlas_cursor atlas_readInt32];
        atlas_objcModule.atlas_name    = [atlas_cursor atlas_readInt32];
        atlas_objcModule.atlas_symtab  = [atlas_cursor atlas_readInt32];

        //NSLog(@"objcModule.size: %u", objcModule.size);
        //NSLog(@"sizeof(struct cd_objc_module): %u", sizeof(struct cd_objc_module));
        assert(atlas_objcModule.atlas_size == sizeof(struct atlas_cd_objc_module)); // Because this is what we're assuming.

        NSString *atlas_name = [self.atlas_machOFile atlas_stringAtAddress:atlas_objcModule.atlas_name];
        if (atlas_name != nil && [atlas_name length] > 0 && atlas_debug)
            NSLog(@"Note: a module name is set: %@", atlas_name);

        //NSLog(@"%08x %08x %08x %08x - '%@'", objcModule.version, objcModule.size, objcModule.name, objcModule.symtab, name);
        //NSLog(@"\tsect: %@", [[machOFile segmentContainingAddress:objcModule.name] sectionContainingAddress:objcModule.name]);
        //NSLog(@"symtab: %08x", objcModule.symtab);

        ObjCAtlasOCModule *atlas_module = [[ObjCAtlasOCModule alloc] init];
        atlas_module.version = atlas_objcModule.atlas_version;
        atlas_module.name    = [self.atlas_machOFile atlas_stringAtAddress:atlas_objcModule.atlas_name];
        atlas_module.atlas_symtab  = [self atlas_processSymtabAtAddress:atlas_objcModule.atlas_symtab];
        [atlas__modules addObject:atlas_module];

        [self atlas_addClassesFromArray:[[atlas_module atlas_symtab] atlas_classes]];
        [self atlas_addCategoriesFromArray:[[atlas_module atlas_symtab] atlas_categories]];
    }
}

- (ObjCAtlasOCSymtab *)atlas_processSymtabAtAddress:(uint32_t)atlas_address;
{
    ObjCAtlasLCSegment *atlas_segment = [self.atlas_machOFile atlas_segmentContainingAddress:atlas_address];
    ObjCAtlasSection *atlas_section = [atlas_segment atlas_sectionContainingAddress:atlas_address];
    if (![[atlas_section atlas_segmentName] isEqualToString:@"__OBJC"])
        return nil; // This can happen with the symtab in a module. In one case, the symtab is in __DATA, __bss, in the zero filled area.

    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];

    struct atlas_cd_objc_symtab atlas_objcSymtab;
    atlas_objcSymtab.atlas_sel_ref_cnt   = [atlas_cursor atlas_readInt32];
    atlas_objcSymtab.atlas_refs          = [atlas_cursor atlas_readInt32];
    atlas_objcSymtab.atlas_cls_def_count = [atlas_cursor atlas_readInt16];
    atlas_objcSymtab.atlas_cat_def_count = [atlas_cursor atlas_readInt16];
    //NSLog(@"[@ %08x]: %08x %08x %04x %04x", address, objcSymtab.sel_ref_cnt, objcSymtab.refs, objcSymtab.cls_def_count, objcSymtab.cat_def_count);

    ObjCAtlasOCSymtab *atlas_symtab = [[ObjCAtlasOCSymtab alloc] init];
    
    for (unsigned int atlas_index = 0; atlas_index < atlas_objcSymtab.atlas_cls_def_count; atlas_index++) {
        uint32_t atlas_val = [atlas_cursor atlas_readInt32];
        //NSLog(@"%4d: %08x", index, val);

        ObjCAtlasOCClass *atlas_aClass = [self atlas_processClassDefinitionAtAddress:atlas_val];
        if (atlas_aClass != nil)
            [atlas_symtab atlas_addClass:atlas_aClass];
    }

    for (unsigned int atlas_index = 0; atlas_index < atlas_objcSymtab.atlas_cat_def_count; atlas_index++) {
        uint32_t atlas_val = [atlas_cursor atlas_readInt32];
        //NSLog(@"%4d: %08x", index, val);

        ObjCAtlasOCCategory *atlas_category = [self atlas_processCategoryDefinitionAtAddress:atlas_val];
        if (atlas_category != nil)
            [atlas_symtab atlas_addCategory:atlas_category];
    }

    return atlas_symtab;
}

- (ObjCAtlasOCClass *)atlas_processClassDefinitionAtAddress:(uint32_t)atlas_address;
{
    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];

    struct atlas_cd_objc_class atlas_objcClass;

    atlas_objcClass.atlas_isa           = [atlas_cursor atlas_readInt32];
    atlas_objcClass.atlas_super_class   = [atlas_cursor atlas_readInt32];
    atlas_objcClass.atlas_name          = [atlas_cursor atlas_readInt32];
    atlas_objcClass.atlas_version       = [atlas_cursor atlas_readInt32];
    atlas_objcClass.atlas_info          = [atlas_cursor atlas_readInt32];
    atlas_objcClass.atlas_instance_size = [atlas_cursor atlas_readInt32];
    atlas_objcClass.atlas_ivars         = [atlas_cursor atlas_readInt32];
    atlas_objcClass.atlas_methods       = [atlas_cursor atlas_readInt32];
    atlas_objcClass.atlas_cache         = [atlas_cursor atlas_readInt32];
    atlas_objcClass.atlas_protocols     = [atlas_cursor atlas_readInt32];

    NSString *atlas_className = [self.atlas_machOFile atlas_stringAtAddress:atlas_objcClass.atlas_name];
    //NSLog(@"name: %08x", objcClass.name);
    //NSLog(@"className = %@", className);
    if (atlas_className == nil) {
        NSLog(@"Note: objcClass.name was %08x, returning nil.", atlas_objcClass.atlas_name);
        return nil;
    }

    ObjCAtlasOCClass *atlas_aClass = [[ObjCAtlasOCClass alloc] init];
    atlas_aClass.name           = atlas_className;
    
    // TODO: can we extract more than just the string from here?
    atlas_aClass.atlas_superClassRef  = [[ObjCAtlasOCClassReference alloc] initAtlasWithClassName:[self.atlas_machOFile atlas_stringAtAddress:atlas_objcClass.atlas_super_class]];

    // Process ivars
    if (atlas_objcClass.atlas_ivars != 0) {
        [atlas_cursor atlas_setAddress:atlas_objcClass.atlas_ivars];
        NSParameterAssert([atlas_cursor atlas_offset] != 0);

        uint32_t atlas_count = [atlas_cursor atlas_readInt32];
        NSMutableArray *atlas_instanceVariables = [[NSMutableArray alloc] init];
        for (uint32_t atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
            struct atlas_cd_objc_ivar atlas_objcIvar;

            atlas_objcIvar.atlas_name   = [atlas_cursor atlas_readInt32];
            atlas_objcIvar.atlas_type   = [atlas_cursor atlas_readInt32];
            atlas_objcIvar.atlas_offset = [atlas_cursor atlas_readInt32];

            NSString *atlas_name       = [self.atlas_machOFile atlas_stringAtAddress:atlas_objcIvar.atlas_name];
            NSString *atlas_typeString = [self.atlas_machOFile atlas_stringAtAddress:atlas_objcIvar.atlas_type];

            // bitfields don't need names.
            // NSIconRefBitmapImageRep in AppKit on 10.5 has a single-bit bitfield, plus an unnamed 31-bit field.
            if (atlas_typeString != nil) {
                ObjCAtlasOCInstanceVariable *atlas_instanceVariable = [[ObjCAtlasOCInstanceVariable alloc] initAtlasWithName:atlas_name atlas_typeString:atlas_typeString atlas_offset:atlas_objcIvar.atlas_offset];
                [atlas_instanceVariables addObject:atlas_instanceVariable];
            }
        }

        atlas_aClass.atlas_instanceVariables = [NSArray arrayWithArray:atlas_instanceVariables];
    }

    // Process instance methods
    for (ObjCAtlasOCMethod *atlas_method in [self atlas_processMethodsAtAddress:atlas_objcClass.atlas_methods])
        [atlas_aClass atlas_addInstanceMethod:atlas_method];

    // Process meta class
    {
        NSParameterAssert(atlas_objcClass.atlas_isa != 0);
        //NSLog(@"meta class, isa = %08x", objcClass.isa);

        [atlas_cursor atlas_setAddress:atlas_objcClass.atlas_isa];

        struct atlas_cd_objc_class atlas_metaClass;
        
        atlas_metaClass.atlas_isa           = [atlas_cursor atlas_readInt32];
        atlas_metaClass.atlas_super_class   = [atlas_cursor atlas_readInt32];
        atlas_metaClass.atlas_name          = [atlas_cursor atlas_readInt32];
        atlas_metaClass.atlas_version       = [atlas_cursor atlas_readInt32];
        atlas_metaClass.atlas_info          = [atlas_cursor atlas_readInt32];
        atlas_metaClass.atlas_instance_size = [atlas_cursor atlas_readInt32];
        atlas_metaClass.atlas_ivars         = [atlas_cursor atlas_readInt32];
        atlas_metaClass.atlas_methods       = [atlas_cursor atlas_readInt32];
        atlas_metaClass.atlas_cache         = [atlas_cursor atlas_readInt32];
        atlas_metaClass.atlas_protocols     = [atlas_cursor atlas_readInt32];

#if 0
        // TODO: (2009-06-23) See if there's anything else interesting here.
        NSLog(@"metaclass= isa:%08x super:%08x  name:%08x ver:%08x  info:%08x isize:%08x  ivar:%08x meth:%08x  cache:%08x proto:%08x",
              metaClass.isa, metaClass.super_class, metaClass.name, metaClass.version, metaClass.info, metaClass.instance_size,
              metaClass.ivars, metaClass.methods, metaClass.cache, metaClass.protocols);
#endif
        // Process class methods
        for (ObjCAtlasOCMethod *atlas_method in [self atlas_processMethodsAtAddress:atlas_metaClass.atlas_methods])
            [atlas_aClass atlas_addClassMethod:atlas_method];
    }

    // Process protocols
    for (ObjCAtlasOCProtocol *atlas_protocol in [self.atlas_protocolUniquer atlas_uniqueProtocolsAtAddresses:[self atlas_protocolAddressListAtAddress:atlas_objcClass.atlas_protocols]])
        [atlas_aClass atlas_addProtocol:atlas_protocol];

    return atlas_aClass;
}

// Returns list of NSNumber containing the protocol addresses
- (NSArray *)atlas_protocolAddressListAtAddress:(uint64_t)atlas_address;
{
    NSMutableArray *atlas_addresses = [[NSMutableArray alloc] init];;
    
    if (atlas_address != 0) {
        ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
        
        struct atlas_cd_objc_protocol_list atlas_protocolList;
        atlas_protocolList.atlas_next  = [atlas_cursor atlas_readInt32];
        atlas_protocolList.atlas_count = [atlas_cursor atlas_readInt32];
        
        for (uint32_t atlas_index = 0; atlas_index < atlas_protocolList.atlas_count; atlas_index++) {
            uint32_t atlas_val = [atlas_cursor atlas_readInt32];
            [atlas_addresses addObject:[NSNumber numberWithUnsignedLongLong:atlas_val]];
        }
    }
    
    return [atlas_addresses copy];
}

- (NSArray *)atlas_processMethodsAtAddress:(uint32_t)atlas_address;
{
    return [self atlas_processMethodsAtAddress:atlas_address atlas_isFromProtocolDefinition:NO];
}

- (NSArray *)atlas_processMethodsAtAddress:(uint32_t)atlas_address atlas_isFromProtocolDefinition:(BOOL)atlas_isFromProtocolDefinition;
{
    if (atlas_address == 0)
        return @[];

    NSMutableArray *atlas_methods = [NSMutableArray array];

    ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];
    if ([atlas_cursor atlas_offset] != 0) {
        struct atlas_cd_objc_method_list atlas_methodList;

        if (atlas_isFromProtocolDefinition)
            atlas_methodList.atlas__obsolete = 0;
        else
            atlas_methodList.atlas__obsolete = [atlas_cursor atlas_readInt32];
        atlas_methodList.atlas_method_count = [atlas_cursor atlas_readInt32];

        for (uint32_t atlas_index = 0; atlas_index < atlas_methodList.atlas_method_count; atlas_index++) {
            struct atlas_cd_objc_method atlas_objcMethod;

            atlas_objcMethod.atlas_name  = [atlas_cursor atlas_readInt32];
            atlas_objcMethod.atlas_types = [atlas_cursor atlas_readInt32];
            if (atlas_isFromProtocolDefinition)
                atlas_objcMethod.atlas_imp = 0;
            else
                atlas_objcMethod.atlas_imp = [atlas_cursor atlas_readInt32];

            NSString *atlas_name = [self.atlas_machOFile atlas_stringAtAddress:atlas_objcMethod.atlas_name];
            NSString *atlas_type = [self.atlas_machOFile atlas_stringAtAddress:atlas_objcMethod.atlas_types];
            if (atlas_name != nil && atlas_type != nil) {
                ObjCAtlasOCMethod *atlas_method = [[ObjCAtlasOCMethod alloc] initAtlasWithName:atlas_name atlas_typeString:atlas_type atlas_address:atlas_objcMethod.atlas_imp];
                [atlas_methods addObject:atlas_method];
            } else {
                if (atlas_name == nil) NSLog(@"Note: Method name was nil (%08x, %p)", atlas_objcMethod.atlas_name, atlas_name);
                if (atlas_type == nil) NSLog(@"Note: Method type was nil (%08x, %p)", atlas_objcMethod.atlas_types, atlas_type);
            }
        }
    }

    return [atlas_methods atlas_reversedArray];
}

- (ObjCAtlasOCCategory *)atlas_processCategoryDefinitionAtAddress:(uint32_t)atlas_address;
{
    ObjCAtlasOCCategory *atlas_category = nil;

    if (atlas_address != 0) {
        ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];

        struct atlas_cd_objc_category atlas_objcCategory;
        atlas_objcCategory.atlas_category_name = [atlas_cursor atlas_readInt32];
        atlas_objcCategory.atlas_class_name    = [atlas_cursor atlas_readInt32];
        atlas_objcCategory.atlas_methods       = [atlas_cursor atlas_readInt32];
        atlas_objcCategory.atlas_class_methods = [atlas_cursor atlas_readInt32];
        atlas_objcCategory.atlas_protocols     = [atlas_cursor atlas_readInt32];

        NSString *atlas_name = [self.atlas_machOFile atlas_stringAtAddress:atlas_objcCategory.atlas_category_name];
        if (atlas_name == nil) {
            NSLog(@"Note: objcCategory.category_name was %08x, returning nil.", atlas_objcCategory.atlas_category_name);
            return nil;
        }

        atlas_category = [[ObjCAtlasOCCategory alloc] init];
        atlas_category.name = atlas_name;
        
        // TODO: can we extract more than just the string from here?
        atlas_category.atlas_classRef = [[ObjCAtlasOCClassReference alloc] initAtlasWithClassName:[self.atlas_machOFile atlas_stringAtAddress:atlas_objcCategory.atlas_class_name]];

        for (ObjCAtlasOCMethod *atlas_method in [self atlas_processMethodsAtAddress:atlas_objcCategory.atlas_methods])
            [atlas_category atlas_addInstanceMethod:atlas_method];

        for (ObjCAtlasOCMethod *atlas_method in [self atlas_processMethodsAtAddress:atlas_objcCategory.atlas_class_methods])
            [atlas_category atlas_addClassMethod:atlas_method];

        for (ObjCAtlasOCProtocol *atlas_protocol in [self.atlas_protocolUniquer atlas_uniqueProtocolsAtAddresses:[self atlas_protocolAddressListAtAddress:atlas_objcCategory.atlas_protocols]])
            [atlas_category atlas_addProtocol:atlas_protocol];
    }

    return atlas_category;
}

- (ObjCAtlasOCProtocol *)atlas_protocolAtAddress:(uint32_t)atlas_address;
{
    ObjCAtlasOCProtocol *atlas_protocol = [self.atlas_protocolUniquer atlas_protocolWithAddress:atlas_address];
    if (atlas_protocol == nil) {
        //NSLog(@"Creating new protocol from address: 0x%08x", address);
        atlas_protocol = [[ObjCAtlasOCProtocol alloc] init];
        [self.atlas_protocolUniquer atlas_setProtocol:atlas_protocol atlas_withAddress:atlas_address];

        ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithFile:self.atlas_machOFile atlas_address:atlas_address];

        /*uint32_t v1 =*/ [atlas_cursor atlas_readInt32];
        uint32_t atlas_v2 = [atlas_cursor atlas_readInt32];
        uint32_t atlas_v3 = [atlas_cursor atlas_readInt32];
        uint32_t atlas_v4 = [atlas_cursor atlas_readInt32];
        uint32_t atlas_v5 = [atlas_cursor atlas_readInt32];
        NSString *atlas_name = [self.atlas_machOFile atlas_stringAtAddress:atlas_v2];
        atlas_protocol.name = atlas_name; // Need to set name before adding to another protocol
        //NSLog(@"data offset for %08x: %08x", v2, [machOFile dataOffsetForAddress:v2]);
        //NSLog(@"[@ %08x] v1-5: 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x (%@)", address, v1, v2, v3, v4, v5, name);

        {
            // Protocols
            if (atlas_v3 != 0) {
                [atlas_cursor atlas_setAddress:atlas_v3];
                uint32_t atlas_val = [atlas_cursor atlas_readInt32];
                NSParameterAssert(atlas_val == 0); // next pointer, let me know if it's ever not zero
                //NSLog(@"val: 0x%08x", val);
                uint32_t atlas_count = [atlas_cursor atlas_readInt32];
                //NSLog(@"protocol count: %08x", count);
                for (uint32_t atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
                    atlas_val = [atlas_cursor atlas_readInt32];
                    //NSLog(@"val[%2d]: 0x%08x", index, val);
                    ObjCAtlasOCProtocol *atlas_anotherProtocol = [self atlas_protocolAtAddress:atlas_val];
                    if (atlas_anotherProtocol != nil) {
                        [atlas_protocol atlas_addProtocol:atlas_anotherProtocol];
                    } else {
                        NSLog(@"Note: another protocol was nil.");
                    }
                }
            }

            // Instance methods
            for (ObjCAtlasOCMethod *atlas_method in [self atlas_processMethodsAtAddress:atlas_v4 atlas_isFromProtocolDefinition:YES])
                [atlas_protocol atlas_addInstanceMethod:atlas_method];

            // Class methods
            for (ObjCAtlasOCMethod *atlas_method in [self atlas_processMethodsAtAddress:atlas_v5 atlas_isFromProtocolDefinition:YES])
                [atlas_protocol atlas_addClassMethod:atlas_method];
        }
    } else {
        //NSLog(@"Found existing protocol at address: 0x%08x", address);
    }

    return atlas_protocol;
}

// Protocols can reference other protocols, so we can't try to create them
// in order.  Instead we create them lazily and just make sure we reference
// all available protocols.

// Many of the protocol structures share the same name, but have differnt method lists.  Create them all, then merge/unique by name after.
// Perhaps a bit more work than necessary, but at least I can see exactly what is happening.
- (void)atlas_loadProtocols;
{
    ObjCAtlasSection *atlas_protocolSection = [[self.atlas_machOFile atlas_segmentWithName:@"__OBJC"] atlas_sectionWithName:@"__protocol"];
    uint32_t atlas_addr = (uint32_t)[atlas_protocolSection atlas_addr];

    NSUInteger atlas_count = [atlas_protocolSection atlas_size] / sizeof(struct atlas_cd_objc_protocol);
    for (NSUInteger atlas_index = 0; atlas_index < atlas_count; atlas_index++, atlas_addr += (uint32_t)sizeof(struct atlas_cd_objc_protocol))
        [self atlas_protocolAtAddress:atlas_addr]; // Forces them to be loaded
}

- (ObjCAtlasSection *)atlas_objcImageInfoSection;
{
    return [[self.atlas_machOFile atlas_segmentWithName:@"__OBJC"] atlas_sectionWithName:@"__image_info"];
}

@end
