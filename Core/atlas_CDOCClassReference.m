// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDOCClassReference.h"
#import "atlas_CDOCClass.h"
#import "atlas_CDSymbol.h"

@implementation ObjCAtlasOCClassReference

- (instancetype)initAtlasWithClassSymbol:(ObjCAtlasSymbol *)atlas_symbol;
{
    if ((self = [super init])) {
        _atlas_classSymbol = atlas_symbol;
    }

    return self;
}

- (instancetype)initAtlasWithClassObject:(ObjCAtlasOCClass *)atlas_classObject;
{
    if ((self = [super init])) {
        _atlas_classObject = atlas_classObject;
    }

    return self;
}

- (instancetype)initAtlasWithClassName:(NSString *)atlas_className;
{
    if ((self = [super init])) {
        _className = [atlas_className copy];
    }

    return self;
}

- (NSString *)className;
{
    if (_className != nil)
        return _className;
    else if (_atlas_classObject != nil)
        return [_atlas_classObject name];
    else if (_atlas_classSymbol != nil)
        return [ObjCAtlasSymbol atlas_classNameFromSymbolName:[_atlas_classSymbol name]];
    else
        return nil;
}

- (BOOL)atlas_isExternalClass;
{
    return (!_atlas_classObject && (!_atlas_classSymbol || [_atlas_classSymbol isExternal]));
}

@end
