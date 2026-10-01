// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDObjectiveCProcessor.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDMachOFile.h"
#import "atlas_CDVisitor.h"
#import "atlas_CDLCSegment.h"
#import "atlas_CDLCDynamicSymbolTable.h"
#import "atlas_CDLCSymbolTable.h"
#import "atlas_CDOCProtocol.h"
#import "atlas_CDTypeController.h"
#import "atlas_CDOCClass.h"
#import "atlas_CDOCCategory.h"
#import "atlas_CDSection.h"
#import "atlas_CDProtocolUniquer.h"

// Note: sizeof(long long) == 8 on both 32-bit and 64-bit.  sizeof(uint64_t) == 8.  So use [NSNumber numberWithUnsignedLongLong:].

@implementation ObjCAtlasObjectiveCProcessor
{
    ObjCAtlasMachOFile *atlas__machOFile;
    
    NSMutableArray *atlas__classes;
    NSMutableDictionary *atlas__classesByAddress;
    
    NSMutableArray *atlas__categories;
    
    ObjCAtlasProtocolUniquer *atlas__protocolUniquer;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_machOFile = atlas__machOFile;
@synthesize atlas_protocolUniquer = atlas__protocolUniquer;

- (id)initAtlasWithMachOFile:(ObjCAtlasMachOFile *)atlas_machOFile;
{
    if ((self = [super init])) {
        atlas__machOFile = atlas_machOFile;
        atlas__classes = [[NSMutableArray alloc] init];
        atlas__classesByAddress = [[NSMutableDictionary alloc] init];
        atlas__categories = [[NSMutableArray alloc] init];
        
        atlas__protocolUniquer = [[ObjCAtlasProtocolUniquer alloc] init];
    }

    return self;
}

#pragma mark - Debugging

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@:%p> machOFile: %@",
            NSStringFromClass([self class]), self,
            self.atlas_machOFile.filename];
}

#pragma mark -

- (BOOL)atlas_hasObjectiveCData;
{
    return self.atlas_machOFile.atlas_hasObjectiveC1Data || self.atlas_machOFile.atlas_hasObjectiveC2Data;
}

- (ObjCAtlasSection *)atlas_objcImageInfoSection;
{
    // Implement in subclasses.
    return nil;
}

- (NSString *)atlas_garbageCollectionStatus;
{
    if (self.atlas_objcImageInfoSection != nil) {
        // The SDK frameworks (i.e. within Xcode, not in /System) have empty sections.
        if (self.atlas_objcImageInfoSection.atlas_size < 8)
            return @"Unknown";

        ObjCAtlasMachOFileDataCursor *atlas_cursor = [[ObjCAtlasMachOFileDataCursor alloc] initAtlasWithSection:self.atlas_objcImageInfoSection];
        
        [atlas_cursor atlas_readInt32];
        uint32_t atlas_v2 = [atlas_cursor atlas_readInt32];
        //NSLog(@"%s: %08x %08x", __cmd, v1, v2);
        // v2 == 0 -> Objective-C Garbage Collection: Unsupported
        // v2 == 2 -> Supported
        // v2 == 6 -> Required
        //NSParameterAssert(v2 == 0 || v2 == 2 || v2 == 6);
        
        // See markgc.c in the objc4 project
        switch (atlas_v2 & 0x06) {
            case 0: return @"Unsupported";
            case 2: return @"Supported";
            case 6: return @"Required";
        }
        
        return [NSString stringWithFormat:@"Unknown (0x%08x)", atlas_v2];
    }
    
    return nil;
}

#pragma mark -

- (void)atlas_addClass:(ObjCAtlasOCClass *)atlas_aClass atlas_withAddress:(uint64_t)atlas_address;
{
    [atlas__classes addObject:atlas_aClass];
    [atlas__classesByAddress setObject:atlas_aClass forKey:[NSNumber numberWithUnsignedLongLong:atlas_address]];
}

- (ObjCAtlasOCClass *)atlas_classWithAddress:(uint64_t)atlas_address;
{
    return [atlas__classesByAddress objectForKey:[NSNumber numberWithUnsignedLongLong:atlas_address]];
}

- (void)atlas_addClassesFromArray:(NSArray *)atlas_array;
{
    if (atlas_array != nil)
        [atlas__classes addObjectsFromArray:atlas_array];
}

- (void)atlas_addCategoriesFromArray:(NSArray *)atlas_array;
{
    if (atlas_array != nil)
        [atlas__categories addObjectsFromArray:atlas_array];
}

- (void)atlas_addCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    if (atlas_category != nil)
        [atlas__categories addObject:atlas_category];
}

#pragma mark - Processing

- (void)atlas_process;
{
    if (self.atlas_machOFile.atlas_isEncrypted == NO && self.atlas_machOFile.atlas_canDecryptAllSegments) {
        [self.atlas_machOFile.atlas_symbolTable atlas_loadSymbols];
        [self.atlas_machOFile.atlas_dynamicSymbolTable atlas_loadSymbols];

        [self atlas_loadProtocols];
        [self.atlas_protocolUniquer atlas_createUniquedProtocols];

        // Load classes before categories, so we can get a dictionary of classes by address.
        [self atlas_loadClasses];
        [self atlas_loadCategories];
    }
}

- (void)atlas_loadProtocols;
{
    // Implement in subclasses.
}

- (void)atlas_loadClasses;
{
    // Implement in subclasses.
}

- (void)atlas_loadCategories;
{
    // Implement in subclasses.
}


- (void)atlas_registerTypesWithObject:(ObjCAtlasTypeController *)atlas_typeController atlas_phase:(NSUInteger)atlas_phase;
{
    for (ObjCAtlasOCClass *atlas_aClass in atlas__classes)
        [atlas_aClass atlas_registerTypesWithObject:atlas_typeController atlas_phase:atlas_phase];

    for (ObjCAtlasOCCategory *atlas_category in atlas__categories)
        [atlas_category atlas_registerTypesWithObject:atlas_typeController atlas_phase:atlas_phase];

    for (ObjCAtlasOCProtocol *atlas_protocol in [self.atlas_protocolUniquer atlas_uniqueProtocolsSortedByName])
        [atlas_protocol atlas_registerTypesWithObject:atlas_typeController atlas_phase:atlas_phase];
}

- (void)atlas_recursivelyVisit:(ObjCAtlasVisitor *)atlas_visitor;
{
    NSMutableArray *atlas_classesAndCategories = [[NSMutableArray alloc] init];
    [atlas_classesAndCategories addObjectsFromArray:atlas__classes];
    [atlas_classesAndCategories addObjectsFromArray:atlas__categories];

    [atlas_visitor atlas_willVisitObjectiveCProcessor:self];
    [atlas_visitor atlas_visitObjectiveCProcessor:self];
    
    // TODO: Sort protocols by dependency
    // TODO: (2004-01-30) It looks like protocols might be defined in more than one file.  i.e. NSObject.
    // TODO: (2004-02-02) Looks like we need to record the order the protocols were encountered, or just always sort protocols
    for (ObjCAtlasOCProtocol *atlas_protocol in [self.atlas_protocolUniquer atlas_uniqueProtocolsSortedByName])
        [atlas_protocol atlas_recursivelyVisit:atlas_visitor];

    if ([[atlas_visitor atlas_classDump] atlas_shouldSortClassesByInheritance]) {
        [atlas_classesAndCategories atlas_sortTopologically];
    } else if ([[atlas_visitor atlas_classDump] atlas_shouldSortClasses])
        [atlas_classesAndCategories sortUsingSelector:@selector(ascendingCompareByName:)];

    for (id atlas_aClassOrCategory in atlas_classesAndCategories)
        [atlas_aClassOrCategory atlas_recursivelyVisit:atlas_visitor];

    [atlas_visitor atlas_didVisitObjectiveCProcessor:self];
}

// Returns list of NSNumber containing the protocol addresses
- (NSArray *)atlas_protocolAddressListAtAddress:(uint64_t)atlas_address;
{
    // Implement in subclasses
    return nil;
}

@end
