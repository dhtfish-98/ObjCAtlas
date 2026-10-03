#!/usr/bin/env python3
"""Pinned-upstream build, CLI corpus and independent static-library consumers."""
import argparse, hashlib, json, os, pathlib, re, shutil, subprocess, tempfile
P=pathlib.Path
ROOT=P(__file__).resolve().parents[1]
PROJECT=json.loads((ROOT/'构建配置.json').read_text())['project'] if (ROOT/'构建配置.json').is_file() else ROOT.name
OLD='class-dump' if PROJECT=='ObjCAtlas' else 'ios-class-guard'
PREFIX='atlas' if PROJECT=='ObjCAtlas' else 'rampart'
MAP=json.loads((ROOT/'RENAME_MAP.json').read_text())
def run(args,**kwargs):
    result=subprocess.run(list(map(str,args)),stdout=subprocess.PIPE,stderr=subprocess.PIPE,**kwargs)
    return result.returncode,result.stdout,result.stderr

def checked(args,**kwargs):
    result=run(args,**kwargs)
    if result[0]:raise RuntimeError(f'{args}: {result[2].decode(errors="replace")}\n{result[1].decode(errors="replace")}')
    return result[1]

def mapped(old):
    if old in MAP.get('selectors',{}):return MAP['selectors'][old]
    components={new.split(':')[index] for selector,new in MAP.get('selectors',{}).items() for index,part in enumerate(selector.split(':')) if part==old}
    if len(components)==1:return next(iter(components))
    matches={entry['new'] for entry in MAP['symbols'].values() if entry['old']==old} if isinstance(MAP['symbols'],dict) else {entry['new'] for entry in MAP['symbols'] if entry['old']==old}
    return next(iter(matches)) if len(matches)==1 else old

def header(source,name,renamed):
    item=MAP['files'].get(name) if renamed else None
    if item is None and renamed:
        item=next((v for k,v in MAP['files'].items() if k.endswith('/'+name)),None)
    if item:return str(source/item)
    return str(next(source.rglob(name)))

def build(source,original,out):
    target=OLD if original else PROJECT
    args=['xcodebuild','-project',source/f'{target}.xcodeproj','-target',target,'-configuration','Release',f'SYMROOT={out}','MACOSX_DEPLOYMENT_TARGET=13.0','CODE_SIGNING_ALLOWED=NO']
    # SDK27 removed PLATFORM_IOSMAC; value6 equals PLATFORM_MACCATALYST. Same addition on both sides.
    if PROJECT=='ObjCAtlas':args.append('OTHER_CFLAGS=$(inherited) -DPLATFORM_IOSMAC=6')
    if PROJECT=='ObjCAtlas':args+=['-target','UnitTests' if original else PROJECT+'Checks']
    checked(args)
    return out/'Release'/target

FIXTURE=r'''#import <Foundation/Foundation.h>
@protocol ContractProtocol <NSObject>
- (int)contractValue;
@end
@interface ContractNode : NSObject <ContractProtocol>
@property(nonatomic) int contractValue;
@property(nonatomic,copy) NSString *caption;
- (int)add:(int)value to:(int)other;
@end
@implementation ContractNode
- (int)add:(int)value to:(int)other {return value+other;}
@end
int main(void) { @autoreleasepool { ContractNode *node=[ContractNode new];return [node add:1 to:2]==3?0:1;} }
'''
BASE_CONSUMER=r'''#import <Foundation/Foundation.h>
IMPORTS
int main(int argc,char **argv) { @autoreleasepool {
 for (NSString *encoding in @[@"i",@"@",@"@\"NSString\"",@"^i",@"[4i]",@"{Point=dd}",@"(Value=if)",@"b7",@"r^v",@"@?",@"{Pair=iq}",@"{Nested={Point=dd}[3i]}",@"?",@"v",@"B",@"q",@"[0i]",@"",@"^",@"{Bad"]) {
 NSError *error=nil;PARSER *parser=[[PARSER alloc] INIT:encoding];TYPE *type=[parser PARSE:&error];
 printf("%s|%s|%ld\n",encoding.UTF8String,type?type.TYPESTRING.UTF8String:"<nil>",(long)error.code);
 }
 EXTRA
 return 0;
} }
'''
RAMPART_EXTRA=r'''
 MAPPER *mapper=[MAPPER new];NSString *result=[mapper CRASH:@"0x123 [Abc xyz:uuu:]\n[Missing unknown]" SYMBOLS:@{@"Abc":@"ContractNode",@"xyz":@"add",@"uuu":@"to"}];puts(result.UTF8String);
 for (NSString *filename in @[@"CustomCellTableViewCell_xib.txt",@"Main_iPhone_storyboard.txt",@"contents"]) {
 NSString *folder=[NSString stringWithUTF8String:argv[1]];NSData *input=[NSData dataWithContentsOfFile:[folder stringByAppendingPathComponent:filename]];
 id parser=[filename isEqualToString:@"contents"]?[MODEL new]:[XIB new];
 NSArray *symbols=[parser READ:input];NSData *json=[NSJSONSerialization dataWithJSONObject:[symbols sortedArrayUsingSelector:@selector(compare:)] options:0 error:nil];puts([[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding].UTF8String);
 NSData *output=[parser XML:input SYM:@{@"CustomCellTableViewCell":@"NewCell",@"aLabel":@"newOutlet",@"buttonTapped":@"newAction",@"outletCollection":@"newCollection",@"XTTableViewController":@"NewController",@"dataSource":@"newData",@"TestEntityA":@"NewEntity",@"TestParentEntity":@"NewParent"}];
 puts([[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding].UTF8String);
 }
'''

def consumer(work,source,out,renamed):
    label='new' if renamed else 'old';items=['CDTypeParser.h','CDType.h']
    if PROJECT=='NameRampart':items+=['CDSymbolMapper.h','CDCoreDataModelParser.h','CDXibStoryboardParser.h']
    imports='\n'.join(f'#import "{header(source,name,renamed)}"' for name in items)
    code=BASE_CONSUMER.replace('IMPORTS',imports).replace('EXTRA',RAMPART_EXTRA if PROJECT=='NameRampart' else '')
    names={'PARSER':'CDTypeParser','TYPE':'CDType','INIT':'initWithString','PARSE':'parseType','TYPESTRING':'typeString','MAPPER':'CDSymbolMapper','CRASH':'processCrashDump','SYMBOLS':'withSymbols','MODEL':'CDCoreDataModelParser','XIB':'CDXibStoryboardParser','READ':'symbolsInData','XML':'obfuscatedXmlData','SYM':'symbols'}
    for token,name in sorted(names.items(),key=lambda x:-len(x[0])):code=re.sub(r'\b'+token+r'\b',mapped(name) if renamed else name,code)
    file=work/f'{label}.m';file.write_text(code);binary=work/f'{label}-consumer'
    sdk=checked(['xcrun','--show-sdk-path']).decode().strip()
    args=['clang','-fobjc-arc','-fblocks','-framework','Foundation','-framework','AppKit','-framework','CoreData','-lxml2','-ObjC','-isysroot',sdk,'-I'+sdk+'/usr/include/libxml2']
    for folder in {p.parent for p in source.rglob('*.h') if not set(p.parts)&{'Pods','build','.git'}}:args+=['-I'+str(folder)]
    args+=['-include',header(source,'MachObjC-Prefix.pch',renamed),file,out/('Release/lib'+PROJECT+'Core.a' if renamed else 'Release/libMachObjC.a'),'-o',binary]
    checked(args)
    resources=work/'resources';resources.mkdir(exist_ok=True)
    if PROJECT=='NameRampart':
        for filename in ['CustomCellTableViewCell_xib.txt','Main_iPhone_storyboard.txt','contents']:
            src=next(source.rglob(filename));shutil.copyfile(src,resources/filename)
    return checked([binary,resources])

def normalized(result):
    def text(blob):
        value=blob.decode(errors='replace').replace(OLD,PROJECT)
        # Build date is emitted by --version and the generated comment banner.
        value=re.sub(r'compiled [A-Z][a-z]{2}\s+\d+ \d{4} \d\d:\d\d:\d\d','compiled <BUILD-TIME>',value)
        value=re.sub(r"^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+ "+re.escape(PROJECT)+r"\[\d+:\d+\] ","<LOG> ",value,flags=re.M)
        return value
    return result[0],text(result[1]),text(result[2])

def formatter_result(result):
    if result[0]<0:
        exception=re.search(rb"uncaught exception '([^']+)', reason: '([^\n]+)'",result[2])
        return result[0],result[1],exception.groups() if exception else result[2]
    stderr=re.sub(rb'^\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+ (?:old|new)-formatType\[\d+:\d+\] ',b'<LOG> ',result[2],flags=re.M)
    return result[0],result[1],stderr

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--upstream',required=True,type=P);parser.add_argument('--output',type=P);parser.add_argument('--original-build',type=P);parser.add_argument('--new-build',type=P);opts=parser.parse_args()
    original=opts.upstream.resolve();report={'project':PROJECT,'checks':[],'open':['The archived SenTestingKit runner is not executed; the current XCTest suite is run. Full real application Xcode/Pods/CoreData/dSYM integration and device runtime remain unverified.']}
    with tempfile.TemporaryDirectory(prefix=PREFIX+'-contract-') as folder:
        work=P(folder);oldout=opts.original_build.resolve() if opts.original_build else work/'old-build';newout=opts.new_build.resolve() if opts.new_build else work/'new-build'
        oldbin=oldout/'Release'/OLD if opts.original_build else build(original,True,oldout)
        newbin=newout/'Release'/PROJECT if opts.new_build else build(ROOT,False,newout)
        fixture=work/'fixture.m';fixture.write_text(FIXTURE);binary=work/'fixture'
        checked(['clang','-fobjc-arc','-framework','Foundation',fixture,'-o',binary])
        broken=work/'malformed';broken.write_bytes(b'not a macho');missing=work/'missing'
        cases=[[],['--version'],['--bad-option'],['--list-arches',str(binary)],['--list-arches',str(broken)],[str(broken)],[str(missing)],['--arch','unsupported',str(binary)]]
        if PROJECT=='ObjCAtlas':
            cases += [[str(binary)],['-t',str(binary)],['-a','-A','-s','-S','-t',str(binary)],['-C','Contract','-t',str(binary)],['-f','add','-t',str(binary)],['--hide','structures,protocols','-t',str(binary)]]
        else:
            sdk=checked(['xcrun','--show-sdk-path']).decode().strip()
            # Find visitor is deterministic and processes real Objective-C metadata.
            cases += [[str(binary)],['--sdk-root',sdk,'-f','add','-t',str(binary)]]
            crash=work/'crash.txt';crash.write_text('frame 0 [Abc xyz:uuu:]\n[Missing unknown]\n');mapping=work/'symbols.json';mapping.write_text(json.dumps({'Abc':'ContractNode','xyz':'add','uuu':'to'}))
            cases += [['-c',str(crash),'-m',str(mapping)],['-c',str(missing)],['-c',str(crash),'-m',str(missing)]]
        for index,case in enumerate(cases):
            old=normalized(run([oldbin]+case));new=normalized(run([newbin]+case))
            if old!=new:raise AssertionError(f'CLI {index} {case}\nold={old}\nnew={new}')
            report['checks'].append({'name':f'cli-{index}','status':'PASS'})
        old=consumer(work,original,oldout,False);new=consumer(work,ROOT,newout,True)
        assert old==new,'Independent linked consumer output differs'
        report['checks'].append({'name':'independent-static-library','status':'PASS','type_encodings':20,'xml_fixtures':3 if PROJECT=='NameRampart' else 0,'output_sha256':hashlib.sha256(new).hexdigest()})
        # Rebuild the two auxiliary source files against the independently built libraries.
        sdk=checked(['xcrun','--show-sdk-path']).decode().strip()
        helpers={}
        for src,renamed,out,label in [(original,False,oldout,'old'),(ROOT,True,newout,'new')]:
            helpers[label]={}
            for name in ['formatType','deprotect']:
                target=work/(label+'-'+name)
                args=['clang','-fobjc-arc','-fblocks','-framework','Foundation','-framework','AppKit','-framework','CoreData','-lxml2','-ObjC','-isysroot',sdk,'-I'+sdk+'/usr/include/libxml2','-DPLATFORM_IOSMAC=6']
                for directory in {p.parent for p in src.rglob('*.h') if not set(p.parts)&{'Pods','build','.git'}}:args+=['-I'+str(directory)]
                args+=['-include',header(src,name+'-Prefix.pch',renamed),header(src,name+'.m',renamed),out/('Release/lib'+PROJECT+'Core.a' if renamed else 'Release/libMachObjC.a'),'-o',target]
                checked(args);helpers[label][name]=target
            report['checks'].append({'name':label+'-auxiliary-builds','status':'PASS','tools':2})
        corpora=sorted(original.glob('UnitTests.old/*.txt'));count=0
        for path in corpora:
            if path.name.endswith('-out.txt'):continue
            mode=['-m'] if path.name.startswith('method-') else ['-b'] if path.name.startswith('shud') else []
            old=run([helpers['old']['formatType']]+mode+[path]);new=run([helpers['new']['formatType']]+mode+[path])
            assert formatter_result(old)==formatter_result(new),f'formatType fixture {path.name} differs: old={old},new={new}'
            count+=1
        report['checks'].append({'name':'formatter-existing-corpus','status':'PASS','files':count,'upstream_known_abort_fixture':'var-004.txt','comparison':'exit/stdout/stderr; on the known upstream abort compare exception class/reason, omit ASLR stack and NSLog PID/time'})
        old=run([helpers['old']['deprotect']]);new=run([helpers['new']['deprotect']]);assert old==new,'deprotect help differs'
        report['checks'].append({'name':'deprotect-cli-help','status':'PASS'})
        if PROJECT=='ObjCAtlas':
            for out,renamed,label in [(oldout,False,'original'),(newout,True,'new')]:
                bundle=out/('Release/'+PROJECT+'Checks.xctest' if renamed else 'Release/UnitTests.xctest')
                result=run(['xcrun','xctest',bundle]);assert result[0]==0,'XCTest failed'
                output=(result[1]+result[2]).decode()
                assert 'Executed 39 tests, with 0 failures' in output,'XCTest result differs'
                report['checks'].append({'name':label+'-xctest','status':'PASS','tests':39})
    report['passed']=len(report['checks']);text=json.dumps(report,ensure_ascii=False,indent=2)+'\n'
    if opts.output:opts.output.write_text(text)
    print(text)
if __name__=='__main__':main()
