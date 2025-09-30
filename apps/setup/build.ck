/*++

Copyright (c) 2013 Minoca Corp.

Licensed under the GNU General Public License v3. Alternative licensing terms are available.
Contact info@minocacorp.com for details. See LICENSE file at project root.

Module Name:
    msetup

Abstract:
    This executable implements the setup (OS installer).

Author:
    Evan Green 10-Apr-2014

Environment:
    User

--*/

from menv import application, copy, mconfig;

function build() {
    var app, buildApp, buildConfig;
    var buildIncludes, buildLibs, buildSources;
    var commonSources, minocaSources, uosSources, win32Sources;
    var targetIncludes, targetSources, targetLibs, targetDynlibs;
    var entries, setupTool, imagePool;
    var buildOs = mconfig.build_os;

    //
    // Common sources for all platforms
    //
    commonSources = [
        "cache.c", "config.c", "disk.c", "fatdev.c", "fileio.c",
        "partio.c", "plat.c", "setup.c", "steps.c", "util.c"
    ];

    //
    // Platform-specific sources
    //
    minocaSources = ["minoca/io.c", "minoca/misc.c", "minoca/part.c"];
    uosSources    = ["uos/io.c", "uos/misc.c", "uos/part.c"];
    win32Sources  = [
        "win32/io.c", "win32/misc.c", "win32/msetuprc.rc",
        "win32/part.c", "win32/win32sup.c"
    ];

    //
    // Libraries (target & build-time)
    //
    targetLibs = [
        "lib/partlib:partlib", "lib/fatlib:fat",
        "lib/bconflib:bconf", "lib/rtl/base:basertl",
        "lib/rtl/urtl:urtl", "apps/ck/lib:libchalk_static",
        "lib/yy:yy"
    ];

    buildLibs = [
        "lib/partlib:build_partlib", "lib/fatlib:build_fat",
        "lib/bconflib:build_bconf", "lib/rtl/base:build_basertl",
        "lib/rtl/urtl:build_rtlc", "apps/ck/lib:build_libchalk_static",
        "lib/yy:build_yy"
    ];

    targetDynlibs = ["apps/osbase:libminocaos"];

    //
    // Includes
    //
    buildIncludes  = [];
    targetIncludes = ["$S/apps/libc/include"];

    //
    // Sources for target build
    //
    targetSources = commonSources + minocaSources + targetLibs + targetDynlibs;

    //
    // Build configuration (per-OS)
    //
    buildConfig = {};
    if (buildOs == "Windows") {
        buildSources = commonSources + win32Sources;
        buildConfig["DYNLIBS"] = ["-lsetupapi"];

    } else if (buildOs == "Minoca") {
        buildSources  = commonSources + minocaSources + targetDynlibs;
        buildIncludes = targetIncludes;

    } else {
        buildSources = commonSources + uosSources;
        if (buildOs != "Darwin" && buildOs != "FreeBSD") {
            buildConfig["DYNLIBS"] = ["-ldl"];
        }
    }

    //
    // Target application
    //
    app = {
        "label": "msetup",
        "inputs": targetSources,
        "includes": targetIncludes
    };

    entries = application(app);

    //
    // Build-time application
    //
    buildApp = {
        "label": "build_msetup",
        "output": "msetup",
        "inputs": buildSources + buildLibs,
        "implicit": [":install.ck"],
        "includes": buildIncludes,
        "config": buildConfig,
        "build": true,
        "prefix": "build",
        "binplace": "tools/bin"
    };

    entries += application(buildApp);

    //
    // Tool definition for image creation
    //
    setupTool = {
        "type": "tool",
        "name": "msetup_image",
        "command": "$O/apps/setup/build/msetup $MSETUP_FLAGS -d $OUT",
        "description": "Building Image - $OUT",
        "pool": "image"
    };

    imagePool = {
        "type": "pool",
        "name": "image",
        "depth": 1
    };

    entries += [setupTool, imagePool];

    //
    // Copy install.ck into bin root
    //
    entries += copy("install.ck",
                    mconfig.binroot + "/install.ck",
                    "install.ck",
                    null,
                    null);

    return entries;
}
