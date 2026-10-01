// -*- mode: ObjC -*-

//  This file is part of class-dump, a utility for examining the Objective-C segment of Mach-O files.
//  Copyright (C) 1997-2019 Steve Nygard.

#import "atlas_CDMultiFileVisitor.h"

#import "atlas_CDClassDump.h"
#import "atlas_CDClassFrameworkVisitor.h"
#import "atlas_CDOCCategory.h"
#import "atlas_CDOCClass.h"
#import "atlas_CDOCProtocol.h"
#import "atlas_CDOCInstanceVariable.h"
#import "atlas_CDTypeController.h"

@interface ObjCAtlasMultiFileVisitor ()

// NSString (class name) -> NSString (framework name)
@property (strong) NSDictionary *atlas_frameworkNamesByClassName;

// NSString (protocol name) -> NSString (framework name)
@property (strong) NSDictionary *atlas_frameworkNamesByProtocolName;

// Location in output string to insert the protocol imports and forward class declarations.
// We don't know what classes and protocols will be referenced until the rest of the output is generated.
@property (assign) NSUInteger atlas_referenceLocation;

// Class and protocol references
@property (readonly) NSMutableSet *atlas_referencedClassNames;
@property (readonly) NSMutableSet *atlas_referencedProtocolNames;
@property (readonly) NSMutableSet *atlas_weaklyReferencedProtocolNames; // Protocols that can be forward-declared instead of imported

@property (nonatomic, readonly) NSArray *atlas_referencedClassNamesSortedByName;
@property (nonatomic, readonly) NSArray *atlas_referencedProtocolNamesSortedByName;
@property (nonatomic, readonly) NSArray *atlas_weaklyReferencedProtocolNamesSortedByName;

@property (nonatomic, readonly) NSString *atlas_referenceString;

@end

#pragma mark -

@implementation ObjCAtlasMultiFileVisitor
{
    NSString *atlas__outputPath;
    
    NSDictionary *atlas__frameworkNamesByClassName;
    NSMutableSet *atlas__referencedClassNames;
    NSMutableSet *atlas__referencedProtocolNames;
    NSUInteger atlas__referenceLocation;
}

// Preserve the original explicit property storage after renaming.
@synthesize atlas_outputPath = atlas__outputPath;
@synthesize atlas_frameworkNamesByClassName = atlas__frameworkNamesByClassName;
@synthesize atlas_referenceLocation = atlas__referenceLocation;
@synthesize atlas_referencedClassNames = atlas__referencedClassNames;
@synthesize atlas_referencedProtocolNames = atlas__referencedProtocolNames;

- (id)init;
{
    if ((self = [super init])) {
        atlas__referencedClassNames = [[NSMutableSet alloc] init];
        atlas__referencedProtocolNames = [[NSMutableSet alloc] init];
        _atlas_weaklyReferencedProtocolNames = [[NSMutableSet alloc] init];
    }
    
    return self;
}

#pragma mark -

- (void)atlas_willBeginVisiting;
{
    [super atlas_willBeginVisiting];

    [self.atlas_classDump atlas_appendHeaderToString:self.atlas_resultString];

    if (self.atlas_classDump.atlas_hasObjectiveCRuntimeInfo) {
        [self atlas_buildClassFrameworks];
        [self atlas_createOutputPathIfNecessary];
        [self atlas_generateStructureHeader];
    } else {
        // TODO: (2007-06-14) Make sure this generates no output files in this case.
        NSLog(@"Warning: This file does not contain any Objective-C runtime information.");
    }
}

- (void)atlas_willVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    // First, we set up some context...
    [self.atlas_resultString setString:@""];
    [self.atlas_classDump atlas_appendHeaderToString:self.atlas_resultString];

    [self atlas_removeAllClassNameProtocolNameReferences];
    NSString *atlas_str = [self atlas_importStringForClassName:atlas_aClass.atlas_superClassName];
    if (atlas_str != nil) {
        [self.atlas_resultString appendString:atlas_str];
        [self.atlas_resultString appendString:@"\n"];
    }

    self.atlas_referenceLocation = [self.atlas_resultString length];

    // And then generate the regular output
    [super atlas_willVisitClass:atlas_aClass];
    
    [self atlas_addReferencesToProtocolNamesInArray:atlas_aClass.atlas_protocolNames];
}

- (void)atlas_didVisitClass:(ObjCAtlasOCClass *)atlas_aClass;
{
    // Generate the regular output
    [super atlas_didVisitClass:atlas_aClass];

    // Then insert the imports and write the file.
    [self atlas_removeReferenceToClassName:atlas_aClass.name];
    [self atlas_removeReferenceToClassName:atlas_aClass.atlas_superClassName];
    NSString *atlas_referenceString = self.atlas_referenceString;
    if (atlas_referenceString != nil)
        [self.atlas_resultString insertString:atlas_referenceString atIndex:self.atlas_referenceLocation];

    NSString *atlas_filename = [NSString stringWithFormat:@"%@.h", atlas_aClass.name];
    if (self.atlas_outputPath != nil)
        atlas_filename = [self.atlas_outputPath stringByAppendingPathComponent:atlas_filename];

    [[self.atlas_resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:atlas_filename atomically:YES];
}

- (void)atlas_willVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    // First, we set up some context...
    [self.atlas_resultString setString:@""];
    [self.atlas_classDump atlas_appendHeaderToString:self.atlas_resultString];

    [self atlas_removeAllClassNameProtocolNameReferences];
    NSString *atlas_str = [self atlas_importStringForClassName:atlas_category.className];
    if (atlas_str != nil) {
        [self.atlas_resultString appendString:atlas_str];
        [self.atlas_resultString appendString:@"\n"];
    }
    self.atlas_referenceLocation = [self.atlas_resultString length];

    // And then generate the regular output
    [super atlas_willVisitCategory:atlas_category];

    [self atlas_addReferencesToProtocolNamesInArray:atlas_category.atlas_protocolNames];
}

- (void)atlas_didVisitCategory:(ObjCAtlasOCCategory *)atlas_category;
{
    // Generate the regular output
    [super atlas_didVisitCategory:atlas_category];

    // Then insert the imports and write the file.
    [self atlas_removeReferenceToClassName:atlas_category.className];
    NSString *atlas_referenceString = self.atlas_referenceString;
    if (atlas_referenceString != nil)
        [self.atlas_resultString insertString:atlas_referenceString atIndex:self.atlas_referenceLocation];

    NSString *atlas_filename = [NSString stringWithFormat:@"%@-%@.h", atlas_category.className, atlas_category.name];
    if (self.atlas_outputPath != nil)
        atlas_filename = [self.atlas_outputPath stringByAppendingPathComponent:atlas_filename];

    [[self.atlas_resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:atlas_filename atomically:YES];
}

- (void)atlas_willVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    [self.atlas_resultString setString:@""];
    [self.atlas_classDump atlas_appendHeaderToString:self.atlas_resultString];

    [self atlas_removeAllClassNameProtocolNameReferences];
    self.atlas_referenceLocation = [self.atlas_resultString length];

    // And then generate the regular output
    [super atlas_willVisitProtocol:atlas_protocol];

    [self atlas_addReferencesToProtocolNamesInArray:atlas_protocol.atlas_protocolNames];
}

- (void)atlas_didVisitProtocol:(ObjCAtlasOCProtocol *)atlas_protocol;
{
    // Generate the regular output
    [super atlas_didVisitProtocol:atlas_protocol];

    // Then insert the imports and write the file.
    NSString *atlas_referenceString = self.atlas_referenceString;
    if (atlas_referenceString != nil)
        [self.atlas_resultString insertString:atlas_referenceString atIndex:self.atlas_referenceLocation];

    NSString *atlas_filename = [NSString stringWithFormat:@"%@-Protocol.h", atlas_protocol.name];
    if (self.atlas_outputPath != nil)
        atlas_filename = [self.atlas_outputPath stringByAppendingPathComponent:atlas_filename];

    [[self.atlas_resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:atlas_filename atomically:YES];
}

#pragma mark - CDTypeControllerDelegate

- (void)atlas_typeController:(ObjCAtlasTypeController *)atlas_typeController atlas_didReferenceClassName:(NSString *)atlas_name;
{
    [self atlas_addReferenceToClassName:atlas_name];
}

- (void)atlas_typeController:(ObjCAtlasTypeController *)atlas_typeController atlas_didReferenceProtocolNames:(NSArray *)atlas_names;
{
    [self atlas_addWeakReferencesToProtocolNamesInArray:atlas_names];
}

#pragma mark -

- (NSString *)atlas_frameworkForClassName:(NSString *)atlas_name;
{
    NSString *atlas_framework = self.atlas_frameworkNamesByClassName[atlas_name];
    
    // Map public CoreFoundation classes to Foundation, because that is where the headers are exposed
    if ([atlas_framework isEqualToString:@"CoreFoundation"] && [atlas_name hasPrefix:@"NS"]) {
        atlas_framework = @"Foundation";
    }
    
    return atlas_framework;
}

- (NSString *)atlas_frameworkForProtocolName:(NSString *)atlas_name;
{
    return self.atlas_frameworkNamesByProtocolName[atlas_name];
}

- (NSString *)atlas_importStringForClassName:(NSString *)atlas_name;
{
    if (atlas_name != nil) {
        NSString *atlas_framework = [self atlas_frameworkForClassName:atlas_name];
        if (atlas_framework == nil)
            return [NSString stringWithFormat:@"#import \"%@.h\"\n", atlas_name];
        else
            return [NSString stringWithFormat:@"#import <%@/%@.h>\n", atlas_framework, atlas_name];
    }
    
    return nil;
}

- (NSString *)atlas_importStringForProtocolName:(NSString *)atlas_name;
{
    if (atlas_name != nil) {
        NSString *atlas_framework = [self atlas_frameworkForProtocolName:atlas_name];
        NSString *atlas_headerName = [atlas_name stringByAppendingString:@"-Protocol.h"];
        if (atlas_framework == nil)
            return [NSString stringWithFormat:@"#import \"%@\"\n", atlas_headerName];
        else
            return [NSString stringWithFormat:@"#import <%@/%@>\n", atlas_framework, atlas_headerName];
    }
    
    return nil;
}

#pragma mark - Class and Protocol name tracking

- (NSArray *)atlas_referencedClassNamesSortedByName;
{
    return [[self.atlas_referencedClassNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)atlas_referencedProtocolNamesSortedByName;
{
    return [[self.atlas_referencedProtocolNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (NSArray *)atlas_weaklyReferencedProtocolNamesSortedByName;
{
    return [[self.atlas_weaklyReferencedProtocolNames allObjects] sortedArrayUsingSelector:@selector(compare:)];
}

- (void)atlas_addReferenceToClassName:(NSString *)atlas_className;
{
    [self.atlas_referencedClassNames addObject:atlas_className];
}

- (void)atlas_removeReferenceToClassName:(NSString *)atlas_className;
{
    if (atlas_className != nil)
        [self.atlas_referencedClassNames removeObject:atlas_className];
}

- (void)atlas_addReferencesToProtocolNamesInArray:(NSArray *)atlas_protocolNames;
{
    [self.atlas_referencedProtocolNames addObjectsFromArray:atlas_protocolNames];
}

- (void)atlas_addWeakReferencesToProtocolNamesInArray:(NSArray *)atlas_protocolNames;
{
    [self.atlas_weaklyReferencedProtocolNames addObjectsFromArray:atlas_protocolNames];
}

- (void)atlas_removeAllClassNameProtocolNameReferences;
{
    [self.atlas_referencedClassNames removeAllObjects];
    [self.atlas_referencedProtocolNames removeAllObjects];
    [self.atlas_weaklyReferencedProtocolNames removeAllObjects];
}

#pragma mark -

- (void)atlas_createOutputPathIfNecessary;
{
    if (self.atlas_outputPath != nil) {
        BOOL atlas_isDirectory;
        
        NSFileManager *atlas_fileManager = [NSFileManager defaultManager];
        if ([atlas_fileManager fileExistsAtPath:self.atlas_outputPath isDirectory:&atlas_isDirectory] == NO) {
            NSError *atlas_error = nil;
            BOOL atlas_result = [atlas_fileManager createDirectoryAtPath:self.atlas_outputPath withIntermediateDirectories:YES attributes:nil error:&atlas_error];
            if (atlas_result == NO) {
                NSLog(@"Error: Couldn't create output directory: %@", self.atlas_outputPath);
                NSLog(@"error: %@", atlas_error); // TODO: Test this
                return;
            }
        } else if (atlas_isDirectory == NO) {
            NSLog(@"Error: File exists at output path: %@", self.atlas_outputPath);
            return;
        }
    }
}

#pragma mark -

// - imports for each referenced protocol
// - forward declarations for each referenced class

- (NSString *)atlas_referenceString;
{
    NSMutableString *atlas_referenceString = [[NSMutableString alloc] init];

    if ([self.atlas_referencedProtocolNames count] > 0) {
        for (NSString *atlas_name in self.atlas_referencedProtocolNamesSortedByName) {
            NSString *atlas_str = [self atlas_importStringForProtocolName:atlas_name];
            if (atlas_str != nil)
                [atlas_referenceString appendString:atlas_str];
        }

        [atlas_referenceString appendString:@"\n"];
    }
    
    BOOL atlas_addNewline = NO;
    if ([self.atlas_referencedClassNames count] > 0) {
        [atlas_referenceString appendFormat:@"@class %@;\n", [self.atlas_referencedClassNamesSortedByName componentsJoinedByString:@", "]];
        atlas_addNewline = YES;
    }

    if ([self.atlas_weaklyReferencedProtocolNames count] > 0) {
        [atlas_referenceString appendFormat:@"@protocol %@;\n", [self.atlas_weaklyReferencedProtocolNamesSortedByName componentsJoinedByString:@", "]];
        atlas_addNewline = YES;
    }
    
    if (atlas_addNewline)
        [atlas_referenceString appendString:@"\n"];
    
    if ([atlas_referenceString length] == 0)
        return nil;
    
    return [atlas_referenceString copy];
}

#pragma mark -

- (void)atlas_buildClassFrameworks;
{
    ObjCAtlasClassFrameworkVisitor *atlas_visitor = [[ObjCAtlasClassFrameworkVisitor alloc] init];
    atlas_visitor.atlas_classDump = self.atlas_classDump;
    
    [self.atlas_classDump atlas_recursivelyVisit:atlas_visitor];
    self.atlas_frameworkNamesByClassName = atlas_visitor.atlas_frameworkNamesByClassName;
    self.atlas_frameworkNamesByProtocolName = atlas_visitor.atlas_frameworkNamesByProtocolName;
}

- (void)atlas_generateStructureHeader;
{
    [self.atlas_resultString setString:@""];
    [self.atlas_classDump atlas_appendHeaderToString:self.atlas_resultString];
    
    [self atlas_removeAllClassNameProtocolNameReferences];
    self.atlas_referenceLocation = [self.atlas_resultString length];
    
    [[self.atlas_classDump atlas_typeController] atlas_appendStructuresToString:self.atlas_resultString];
    
    NSString *atlas_referenceString = [self atlas_referenceString];
    if (atlas_referenceString != nil)
        [self.atlas_resultString insertString:atlas_referenceString atIndex:self.atlas_referenceLocation];
    
    NSString *atlas_filename = @"CDStructures.h";
    if (self.atlas_outputPath != nil)
        atlas_filename = [self.atlas_outputPath stringByAppendingPathComponent:atlas_filename];
    
    [[self.atlas_resultString dataUsingEncoding:NSUTF8StringEncoding] writeToFile:atlas_filename atomically:YES];
}

@end
