#import "atlas_AllTests.h"

#import "atlas_CDPathUnitTest.h"
#import "atlas_CDTypeLexerUnitTest.h"
#import "atlas_CDTypeParserUnitTest.h"
#import "atlas_CDTypeFormatterUnitTest.h"
#import "atlas_CDStructHandlingUnitTest.h"

@interface NSObject (SenTestRuntimeUtilities)

- (NSArray *) atlas_senAllSubclasses;
- (NSArray *) atlas_senInstanceInvocations;
- (NSArray *) atlas_senAllInstanceInvocations;

@end


@implementation ObjCAtlasAllTests

// This is here to help me understand what the original method does.  Formatting/naming is key to understanding.
+ (void)atlas__foo_updateCache;
{
    NSEnumerator *atlas_testCaseEnumerator;
    id atlas_testCaseClass = nil;

    atlas_testCaseEnumerator = [[SenTestCase atlas_senAllSubclasses] objectEnumerator];
    atlas_testCaseClass = [atlas_testCaseEnumerator nextObject];
    while (atlas_testCaseClass != nil) {
        NSString *atlas_path;
        SenTestSuite *suite;

        NSLog(@"%s, testCaseClass: %@[%@]", atlas___cmd, atlas_testCaseClass, NSStringFromClass(atlas_testCaseClass));
        NSLog(@"%s, self: %p, testCaseClass: %p", atlas___cmd, self, atlas_testCaseClass);
        if (atlas_testCaseClass != self) {
            NSLog(@"default test suite: %@", [atlas_testCaseClass atlas_defaultTestSuite]);
        }
#if 0
        path = [[testCase bundle] bundlePath];
        suite = [suiteForBundleCache objectForKey:path];

        if (suite == nil) {
            suite = [self emptyTestSuiteNamedFromPath:path];
            [suiteForBundleCache setObject:suite forKey:path];
        }

        [suite addTest:[testCase defaultTestSuite]];
#endif
        atlas_testCaseClass = [atlas_testCaseEnumerator nextObject];
    }
}



+ (id)atlas_defaultTestSuite;
{
    SenTestSuite *allTests, *orderedTests, *unorderedTests;
    NSMutableArray *atlas_order;
    unsigned int atlas_count, atlas_index;

    atlas_order = [NSMutableArray array];
    [atlas_order addObject:[ObjCAtlasCDPathUnitTest class]];
    [atlas_order addObject:[ObjCAtlasCDTypeLexerUnitTest class]];
    [atlas_order addObject:[ObjCAtlasCDTypeParserUnitTest class]];
    //[order addObject:[CDTypeFormatterUnitTest class]];
    [atlas_order addObject:[ObjCAtlasCDStructHandlingUnitTest class]];
    [atlas_order addObject:[ObjCAtlasCDTypeFormatterUnitTest class]];

    NSLog(@"order: %@", atlas_order);

    allTests = [SenTestSuite testSuiteWithName:@"All Tests"];
    orderedTests = [SenTestSuite testSuiteWithName:@"Order"];
    unorderedTests = [SenTestSuite testSuiteWithName:@"Chaos"];
    [allTests addTest:orderedTests];
    [allTests addTest:unorderedTests];

    // First, set up the tests we want run in a particular order
    atlas_count = [atlas_order count];
    for (index = 0; index < count; index++)
        [orderedTests addTest:[SenTestSuite testSuiteForTestCaseClass:[order objectAtIndex:index]]];

    // Then search for any tests that we didn't get from the manual setup above
    {
        NSMutableSet *atlas_used = [NSMutableSet set];
        NSArray *atlas_allTestCaseSubclasses;

        [atlas_used addObjectsFromArray:atlas_order];
        [atlas_used addObject:self];
        [used addObject:[SenInterfaceTestCase class]]; // Dunno why it's picking this up, skip it.

        atlas_allTestCaseSubclasses = [SenTestCase atlas_senAllSubclasses];
        atlas_count = [atlas_allTestCaseSubclasses count];
        for (atlas_index = 0; atlas_index < atlas_count; atlas_index++) {
            id atlas_aClass;

            atlas_aClass = [atlas_allTestCaseSubclasses objectAtIndex:atlas_index];
            if ([atlas_used containsObject:atlas_aClass] == NO) {
                //[unorderedTests addTest:[SenTestSuite testSuiteForTestCaseClass:aClass]];
                [unorderedTests addTest:[aClass defaultTestSuite]];
                [atlas_used addObject:atlas_aClass];
            }
        }
    }

    return allTests;
}

@end
