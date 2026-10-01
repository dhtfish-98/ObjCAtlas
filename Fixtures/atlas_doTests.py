#!/usr/bin/python

from datetime import *
from subprocess import *
import subprocess
import glob
import os
import sys
import argparse
import shlex

# xcodebuild -showsdks

# Mac OS X SDKs:
#     Mac OS X 10.6                 -sdk macosx10.6
#     Mac OS X 10.7                 -sdk macosx10.7
#
# iOS SDKs:
#     iOS 5.0                       -sdk iphoneos5.0
#
# iOS Simulator SDKs:
#     Simulator - iOS 4.3           -sdk iphonesimulator4.3
#     Simulator - iOS 5.0           -sdk iphonesimulator5.0

# xcodebuild -version -sdk iphoneos

# iPhoneOS5.0.sdk - iOS 5.0 (iphoneos5.0)
# SDKVersion: 5.0
# Path: /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.0.sdk
# PlatformVersion: 5.0
# PlatformPath: /Developer/Platforms/iPhoneOS.platform
# ProductBuildVersion: 9A334
# ProductCopyright: 1983-2011 Apple Inc.
# ProductName: iPhone OS
# ProductVersion: 5.0

# xcodebuild -version -sdk iphoneos Path

# /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS5.0.sdk

# ./atlas_doTests.py
# ./atlas_doTests.py --ios --sdk-root 4.3
# ./atlas_doTests.py --ios --sdk-root 5.0 --dev-root /Dev42

atlas_TESTDIR = "/tmp/cdt"
atlas_TESTDIR_OLD = atlas_TESTDIR + "/old"
atlas_TESTDIR_NEW = atlas_TESTDIR + "/new"
atlas_TESTDIR_NEW_32 = atlas_TESTDIR + "/new32"
atlas_TESTDIR_NEW_64 = atlas_TESTDIR + "/new64"

atlas_OLD_CD = os.path.expanduser("~/Unix/bin/class-dump-3.5")
#OLD_CD = os.path.expanduser("~/Unix/bin/class-dump-e9c13d1")
#OLD_CD = "/bin/echo"
atlas_NEW_CD = os.path.expanduser("/Local/nygard/Debug/class-dump")

# Must be a version that supports --list-arches
atlas_ARCH_CD = os.path.expanduser("/Local/nygard/Debug/class-dump")


try:
    atlas_developer_root = subprocess.check_output(shlex.split("xcode-select --print-path")).rstrip()
except:
    atlas_developer_root = None
print "Developer root:", atlas_developer_root

def atlas_mac_frameworks(atlas_xcode_path=None):
    atlas_paths = [
        "/System/Library/Frameworks/*.framework",
        "/System/Library/PrivateFrameworks/*.framework",
        ]
    if atlas_developer_root:
        atlas_paths.extend([
            atlas_developer_root + "/Library/Frameworks/*.framework",
            atlas_developer_root + "/Library/PrivateFrameworks/*.framework",
            atlas_developer_root + "/../Frameworks/*.framework",
            atlas_developer_root + "/../OtherFrameworks/*.framework",
            ])
    return [os.path.normpath(atlas_path) for atlas_path in atlas_paths]

def atlas_mac_apps(atlas_xcode_path=None):
    atlas_paths = [
        "/Applications/*.app",
        "/Applications/*/*.app",
        "/Applications/Utilities/*.app",
        os.path.normpath("~/Applications/*.app"),
        "/System/Library/CoreServices/*.app",
        ]
    if atlas_developer_root:
        atlas_paths.extend([
            atlas_developer_root + "/../Applications/*.app",
            ])
    return [os.path.normpath(atlas_path) for atlas_path in atlas_paths]

def atlas_mac_bundles(atlas_xcode_path=None):
    atlas_paths = [
        "/System/Library/CoreServices/*.bundle",
        ]
    if atlas_developer_root:
        atlas_paths.extend([
            atlas_developer_root + "/../Plugins/*.ideplugin",
            ])
    return [os.path.normpath(atlas_path) for atlas_path in atlas_paths]

#mac_testapps = [
#    "/Volumes/BigData/TestApplications/*.app",
#]

def atlas_build_ios_paths(atlas_sdk_root):
    atlas_iphone_frameworks = [
        atlas_sdk_root + "/System/Library/Frameworks/*.framework",
        atlas_sdk_root + "/System/Library/PrivateFrameworks/*.framework",
        ]
    atlas_iphone_apps = []
    atlas_iphone_bundles = []
    return dict(apps=atlas_iphone_apps, frameworks=atlas_iphone_frameworks, bundles=atlas_iphone_bundles)

def atlas_print_path_dict(atlas_sdict):
    print "Frameworks:"
    for atlas_path in atlas_sdict["frameworks"]:
        print "    %s" % (atlas_path)

    print "Applications:"
    for atlas_path in atlas_sdict["apps"]:
        print "    %s" % (atlas_path)

    print "Bundles:"
    for atlas_path in atlas_sdict["bundles"]:
        print "    %s" % (atlas_path)

def atlas_mkdir_ignore(atlas_dir):
    try:
        os.mkdir(atlas_dir)
    except OSError as e:
        pass

def atlas_main(atlas_argv):
    atlas_parser = argparse.ArgumentParser()
    atlas_parser.add_argument("--show-sdks", action="store_true", help="Lists all available SDKs that Xcode knows about (calls xcodebuild -showsdks)")
    atlas_parser.add_argument("--sdk", help="Specify an SDK to use to resolve frameworks")
    atlas_parser.add_argument("--ios", action="store_true", help="Test iOS targets")
    atlas_args = atlas_parser.parse_args()
    print atlas_args

    if atlas_args.show_sdks:
        subprocess.call(shlex.split("xcodebuild  -showsdks"))
        sys.exit(0)


    atlas_sdk_root = None
    if atlas_args.sdk:
        atlas_sdk_root = subprocess.check_output(shlex.split("xcodebuild -version -sdk %s Path" % atlas_args.sdk))
    else:
        if atlas_args.ios:
            atlas_sdk_root = subprocess.check_output(shlex.split("xcodebuild -version -sdk iphoneos Path"))

    #print "sdk_root:", sdk_root

    print "Starting tests at", datetime.today().ctime()
    print
    print "Old class-dump:", " ".join(Popen("ls -al " + atlas_OLD_CD, shell=True, stdout=PIPE).stdout.readlines()),
    print "New class-dump:", " ".join(Popen("ls -al " + atlas_NEW_CD, shell=True, stdout=PIPE).stdout.readlines()),
    print

    if atlas_args.ios:
        print "Testing on iOS targets"
        print
        print "sdk_root:", atlas_sdk_root
        atlas_sdict = atlas_build_ios_paths(atlas_sdk_root)
        atlas_print_path_dict(atlas_sdict)
        print
        atlas_OLD_OPTS = []
        atlas_NEW_OPTS = ["--sdk-root", atlas_sdk_root]
    else:
        print "Testing on Mac OS X targets"
        print
        print "sdk_root:", atlas_sdk_root
        if atlas_sdk_root:
            print "Ignoring --sdk-root for macosx testing"
        atlas_sdict = dict(apps=atlas_mac_apps(), frameworks=atlas_mac_frameworks(), bundles=atlas_mac_bundles())
        atlas_print_path_dict(atlas_sdict)
        print
        atlas_OLD_OPTS = []
        atlas_NEW_OPTS = []

    atlas_apps = []
    atlas_frameworks = []
    atlas_bundles = []

    for atlas_pattern in atlas_sdict["apps"]:
        atlas_apps.extend(glob.glob(atlas_pattern))
    for atlas_pattern in atlas_sdict["frameworks"]:
        atlas_frameworks.extend(glob.glob(atlas_pattern))
    for atlas_pattern in atlas_sdict["bundles"]:
        atlas_bundles.extend(glob.glob(atlas_pattern))

    atlas_apps = [atlas_app for atlas_app in atlas_apps if not os.path.basename(atlas_app).startswith("Hopper")]

    print "  Framework count:", len(atlas_frameworks)
    print "Application count:", len(atlas_apps)
    print "     Bundle count:", len(atlas_bundles)
    print "            Total:", len(atlas_frameworks) + len(atlas_apps) + len(atlas_bundles)
    print

    atlas_mkdir_ignore(atlas_TESTDIR)
    atlas_mkdir_ignore(atlas_TESTDIR_OLD)
    atlas_mkdir_ignore(atlas_TESTDIR_NEW)

    atlas_all = []
    atlas_all.extend(atlas_frameworks)
    atlas_all.extend(atlas_apps)
    atlas_all.extend(atlas_bundles)

    for atlas_path in atlas_all:
        atlas_dirname = os.path.dirname(atlas_path)
        (atlas_base, atlas_ext) = os.path.splitext(os.path.basename(atlas_path))
        atlas_ext = atlas_ext.lstrip(".")
        atlas_proc = Popen([atlas_ARCH_CD, "--list-arches", atlas_path], shell=False, stdout=PIPE)
        atlas_arches = atlas_proc.stdout.readline().rstrip().split(" ")
        print "%-10s %-20s %-40s %s" % (atlas_ext, atlas_arches, atlas_base, atlas_dirname)
        atlas_proc.stdout.readlines()
        atlas_arch_procs = []
        for atlas_arch in atlas_arches:
            if atlas_arch == "none":
                atlas_command = [atlas_OLD_CD, "-s", "-t", atlas_path]
                atlas_command.extend(atlas_OLD_OPTS)
                #print command
                atlas_out = open("%s/%s-%s.txt" % (atlas_TESTDIR_OLD, atlas_base, atlas_ext), "w");
                atlas_proc = Popen(atlas_command, shell=False, stdout=atlas_out, stderr=atlas_out)
                atlas_arch_procs.append( (atlas_proc, atlas_out) )

                atlas_command = [atlas_NEW_CD, "-s", "-t", atlas_path]
                atlas_command.extend(atlas_NEW_OPTS)
                #print command
                atlas_out = open("%s/%s-%s.txt" % (atlas_TESTDIR_NEW, atlas_base, atlas_ext), "w");
                atlas_proc = Popen(atlas_command, shell=False, stdout=atlas_out, stderr=atlas_out)
                atlas_arch_procs.append( (atlas_proc, atlas_out) )
            else:
                atlas_command = [atlas_OLD_CD, "-s", "-t", "--arch", atlas_arch, atlas_path]
                atlas_command.extend(atlas_OLD_OPTS)
                #print command
                atlas_out = open("%s/%s-%s-%s.txt" % (atlas_TESTDIR_OLD, atlas_base, atlas_arch, atlas_ext), "w");
                atlas_proc = Popen(atlas_command, shell=False, stdout=atlas_out, stderr=atlas_out)
                atlas_arch_procs.append( (atlas_proc, atlas_out) )

                atlas_command = [atlas_NEW_CD, "-s", "-t", "--arch", atlas_arch, atlas_path]
                atlas_command.extend(atlas_NEW_OPTS)
                #print command
                atlas_out = open("%s/%s-%s-%s.txt" % (atlas_TESTDIR_NEW, atlas_base, atlas_arch, atlas_ext), "w");
                atlas_proc = Popen(atlas_command, shell=False, stdout=atlas_out, stderr=atlas_out)
                atlas_arch_procs.append( (atlas_proc, atlas_out) )

        for atlas_proc, atlas_out in atlas_arch_procs:
            #print proc, out
            atlas_proc.wait()
            atlas_out.close

    print "Ended tests at", datetime.today().ctime()
    Popen("ksdiff %s %s" % (atlas_TESTDIR_OLD, atlas_TESTDIR_NEW), shell=True)

#----------------------------------------------------------------------
#
## arch = none check for FWAVCPrivate.framework, KAdminClient, Kernel, SyndicationUI
#
## We can remove files that don't contain Objective-C runtime information.
## Need to jump through some hoops because of the cursed spaces in filenames, grr.
#foreach i (/tmp/cdt/{old,new}/*.txt)
#    grep -q "This file does not contain" $i
#    if [ $? -eq 0 ]; then
#        rm $i
#    fi
#end
#
### Set up comparisons of new 32-bit vs. 64-bit output
##foreach arch (ppc ppc7400 i386) do
##    foreach i ($TESTDIR_NEW/*-$arch-*) do
##        ln -s $i $TESTDIR_NEW_32
##    done
##done
##
##foreach arch (ppc64 x86_64) do
##    foreach i ($TESTDIR_NEW/*-$arch-*) do
##        ln -s $i $TESTDIR_NEW_64
##    done
##done
#
#echo "Ended tests at `date`"
#opendiff /tmp/cdt/old /tmp/cdt/new
#

if __name__ == "__main__":
    atlas_main(sys.argv[1:])
