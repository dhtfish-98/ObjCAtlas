// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDProtocolUniquer.h"

#import "atlas_CDOCProtocol.h"
#import "atlas_CDOCMethod.h"

@implementation ObjCAtlasProtocolUniquer
{
    NSMutableDictionary *atlas__protocolsByAddress; // non-uniqued
    NSMutableDictionary *atlas__uniqueProtocolsByName;
    NSMutableDictionary *atlas__uniqueProtocolsByAddress;
}

- (id)init;
{
    if ((self = [super init])) {
        atlas__protocolsByAddress       = [[NSMutableDictionary alloc] init];
        atlas__uniqueProtocolsByName    = [[NSMutableDictionary alloc] init];
        atlas__uniqueProtocolsByAddress = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark - Gather

- (ObjCAtlasOCProtocol *)atlas_protocolWithAddress:(uint64_t)atlas_address;
{
    NSNumber *atlas_key = [NSNumber numberWithUnsignedLongLong:atlas_address];
    return atlas__protocolsByAddress[atlas_key];
}

- (void)atlas_setProtocol:(ObjCAtlasOCProtocol *)atlas_protocol atlas_withAddress:(uint64_t)atlas_address;
{
    NSNumber *atlas_key = [NSNumber numberWithUnsignedLongLong:atlas_address];
    atlas__protocolsByAddress[atlas_key] = atlas_protocol;
}

#pragma mark - Process

- (void)atlas_createUniquedProtocols;
{
    [atlas__uniqueProtocolsByName removeAllObjects];
    [atlas__uniqueProtocolsByAddress removeAllObjects];

    // Now unique the protocols by name and store in protocolsByName
    
    for (NSNumber *atlas_key in [[atlas__protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        ObjCAtlasOCProtocol *atlas_p1 = atlas__protocolsByAddress[atlas_key];
        ObjCAtlasOCProtocol *atlas_uniqueProtocol = atlas__uniqueProtocolsByName[atlas_p1.name];
        if (atlas_uniqueProtocol == nil) {
            atlas_uniqueProtocol = [[ObjCAtlasOCProtocol alloc] init];
            [atlas_uniqueProtocol setName:[atlas_p1 name]];
            atlas__uniqueProtocolsByName[atlas_uniqueProtocol.name] = atlas_uniqueProtocol;
            // adopted protocols still not set, will want uniqued instances
        } else {
        }
        atlas__uniqueProtocolsByAddress[atlas_key] = atlas_uniqueProtocol;
    }
    
    //NSLog(@"uniqued protocol names: %@", [[[protocolsByName allKeys] sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@", "]);
    
    // And finally fill in adopted protocols, instance and class methods.  And properties.
    for (NSNumber *atlas_key in [[atlas__protocolsByAddress allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        ObjCAtlasOCProtocol *atlas_p1 = atlas__protocolsByAddress[atlas_key];
        ObjCAtlasOCProtocol *atlas_uniqueProtocol = atlas__uniqueProtocolsByName[atlas_p1.name];
        
        // Add the uniqued adopted protocols
        for (ObjCAtlasOCProtocol *atlas_p2 in [atlas_p1 atlas_protocols])
            [atlas_uniqueProtocol atlas_addProtocol:atlas__uniqueProtocolsByName[atlas_p2.name]];
        
        [atlas_uniqueProtocol atlas_mergeMethodsFromProtocol:atlas_p1];
        [atlas_uniqueProtocol atlas_mergePropertiesFromProtocol:atlas_p1];
    }
    
    //NSLog(@"protocolsByName: %@", protocolsByName);
}

#pragma mark - Results

// These are useful after the call to -createUniqueProtocols

- (NSArray *)atlas_uniqueProtocolsAtAddresses:(NSArray *)atlas_addresses;
{
    NSMutableArray *atlas_protocols = [NSMutableArray array];

    for (NSNumber *atlas_protocolAddress in atlas_addresses) {
        ObjCAtlasOCProtocol *atlas_uniqueProtocol = atlas__uniqueProtocolsByAddress[atlas_protocolAddress];
        if (atlas_uniqueProtocol != nil)
            [atlas_protocols addObject:atlas_uniqueProtocol];
    }

    return [atlas_protocols copy];
}

- (NSArray *)atlas_uniqueProtocolsSortedByName;
{
    return [[atlas__uniqueProtocolsByName allValues] sortedArrayUsingSelector:@selector(ascendingCompareByName:)];
}

@end
