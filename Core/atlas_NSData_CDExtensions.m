// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_NSData_CDExtensions.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSData (CDExtensions)

- (NSString *)atlas_hexString;
{
    NSMutableString *atlas_str = [NSMutableString string];
    const uint8_t *atlas_ptr = [self bytes];
    for (NSUInteger atlas_index = 0; atlas_index < [self length]; atlas_index++) {
        [atlas_str appendFormat:@"%02x", *atlas_ptr++];
    }
    
    return atlas_str;
}

- (NSData *)atlas_SHA1Digest;
{
    NSParameterAssert([self length] <= UINT32_MAX);
    
    unsigned char atlas_digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1([self bytes], (CC_LONG)[self length], atlas_digest);
    
    return [NSData dataWithBytes:atlas_digest length:CC_SHA1_DIGEST_LENGTH];
}

@end
