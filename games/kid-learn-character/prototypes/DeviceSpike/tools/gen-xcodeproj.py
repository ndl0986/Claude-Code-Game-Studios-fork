# PROTOTYPE - NOT FOR PRODUCTION (TASK-078 DeviceSpike)
# Writes DeviceSpike.xcodeproj (no xcodegen on the machine), adapted from TASK-033's generator:
# one multiplatform app target (iPadOS 26 + macOS 26), SpriteKit only, NO remote package (no Rive),
# local packages SpikeKit and TASK-033's MorphCore, resources: TASK-033 fixtures and, once TASK-077 is merged, art/.
#   python3 tools/gen-xcodeproj.py
import hashlib, os

ROOT = os.path.join(os.path.dirname(__file__), "..")
def oid(name): return hashlib.md5(("ds." + name).encode()).hexdigest()[:24].upper()
objs = []
def add(name, body): objs.append((oid(name), name, body)); return oid(name)

proj, main_group, products_group = oid("project"), oid("group.main"), oid("group.products")
src_sync = add("sync.DeviceSpike", '{isa = PBXFileSystemSynchronizedRootGroup; path = DeviceSpike; sourceTree = "<group>"; }')
fixtures_ref = add("ref.fixtures", '{isa = PBXFileReference; lastKnownFileType = folder; name = fixtures; path = ../TASK-033-anim-runtime/fixtures; sourceTree = "<group>"; }')
has_art = os.path.isdir(os.path.join(ROOT, "art"))
art_ref = add("ref.art", '{isa = PBXFileReference; lastKnownFileType = folder; path = art; sourceTree = "<group>"; }') if has_art else None
pkg_kit = add("pkg.SpikeKit", '{isa = XCLocalSwiftPackageReference; relativePath = SpikeKit; }')
pkg_core = add("pkg.MorphCore", '{isa = XCLocalSwiftPackageReference; relativePath = ../TASK-033-anim-runtime/MorphCore; }')

settings = {
    "PRODUCT_NAME": "\"$(TARGET_NAME)\"", "PRODUCT_BUNDLE_IDENTIFIER": "com.galaxyandsun.spike.devicespike",
    "SDKROOT": "auto", "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator macosx"', "SUPPORTS_MACCATALYST": "NO",
    "TARGETED_DEVICE_FAMILY": "2", "IPHONEOS_DEPLOYMENT_TARGET": "26.0", "MACOSX_DEPLOYMENT_TARGET": "26.0",
    "GENERATE_INFOPLIST_FILE": "YES", "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": '"UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown"',
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES", "INFOPLIST_KEY_CFBundleDisplayName": "DeviceSpike",
    "MARKETING_VERSION": "0.1", "CURRENT_PROJECT_VERSION": "1", "SWIFT_VERSION": "5.0", "CODE_SIGN_STYLE": "Automatic",
    '"CODE_SIGN_IDENTITY[sdk=macosx*]"': '"-"', '"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]"': "DeviceSpike-macOS.entitlements",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES", "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/Frameworks"',
    '"LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]"': '"$(inherited) @executable_path/../Frameworks"',
}
def config_list(tag, st0):
    ids = []
    for cfg in ("Debug", "Release"):
        st = dict(st0)
        st.update({"SWIFT_OPTIMIZATION_LEVEL": '"-Onone"', "DEBUG_INFORMATION_FORMAT": "dwarf"} if cfg == "Debug"
                  else {"SWIFT_OPTIMIZATION_LEVEL": '"-O"', "SWIFT_COMPILATION_MODE": "wholemodule", "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"'})
        body = "{isa = XCBuildConfiguration; buildSettings = {" + "".join(f"{k} = {v}; " for k, v in st.items()) + f"}}; name = {cfg}; }}"
        ids.append(add(f"cfg.{tag}.{cfg}", body))
    return add(f"cfglist.{tag}", "{isa = XCConfigurationList; buildConfigurations = (" + ", ".join(ids) + "); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }")

prod = add("prod.app", '{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = DeviceSpike.app; sourceTree = BUILT_PRODUCTS_DIR; }')
deps = [add("dep.SpikeKit", f'{{isa = XCSwiftPackageProductDependency; package = {pkg_kit}; productName = SpikeKit; }}'),
        add("dep.MorphCore", f'{{isa = XCSwiftPackageProductDependency; package = {pkg_core}; productName = MorphCore; }}')]
fw_files = [add(f"bf.{d}", f'{{isa = PBXBuildFile; productRef = {d}; }}') for d in deps]
res_files = [add("bf.fixtures", f'{{isa = PBXBuildFile; fileRef = {fixtures_ref}; }}')] + ([add("bf.art", f'{{isa = PBXBuildFile; fileRef = {art_ref}; }}')] if has_art else [])
src = add("phase.src", "{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }")
fw = add("phase.fw", "{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (" + ", ".join(fw_files) + "); runOnlyForDeploymentPostprocessing = 0; }")
res = add("phase.res", "{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (" + ", ".join(res_files) + "); runOnlyForDeploymentPostprocessing = 0; }")
target = add("target.app", "{isa = PBXNativeTarget; buildConfigurationList = " + config_list("app", settings) + f"; buildPhases = ({src}, {fw}, {res}); buildRules = (); dependencies = (); fileSystemSynchronizedGroups = ({src_sync}); name = DeviceSpike; packageProductDependencies = (" + ", ".join(deps) + f"); productName = DeviceSpike; productReference = {prod}; productType = \"com.apple.product-type.application\"; }}")
add("group.products", "{isa = PBXGroup; children = (" + prod + '); name = Products; sourceTree = "<group>"; }')
add("group.main", "{isa = PBXGroup; children = (" + ", ".join([src_sync, fixtures_ref] + ([art_ref] if has_art else []) + [products_group]) + '); sourceTree = "<group>"; }')
proj_cfg = config_list("project", {"ALWAYS_SEARCH_USER_PATHS": "NO", "CLANG_ENABLE_MODULES": "YES", "ENABLE_STRICT_OBJC_MSGSEND": "YES"})
add("project", "{isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2700; LastUpgradeCheck = 2700; }; buildConfigurationList = " + proj_cfg +
    '; compatibilityVersion = "Xcode 15.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = ' + main_group +
    f"; minimizedProjectReferenceProxies = 1; packageReferences = ({pkg_kit}, {pkg_core}); preferredProjectObjectVersion = 77; productRefGroup = " + products_group +
    f'; projectDirPath = ""; projectRoot = ""; targets = ({target}); }}')
out = "// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 77;\n\tobjects = {\n"
for i, n, b in sorted(objs, key=lambda o: o[0]): out += f"\t\t{i} /* {n} */ = {b};\n"
out += f"\t}};\n\trootObject = {proj};\n}}\n"
os.makedirs(os.path.join(ROOT, "DeviceSpike.xcodeproj"), exist_ok=True)
open(os.path.join(ROOT, "DeviceSpike.xcodeproj", "project.pbxproj"), "w").write(out)
open(os.path.join(ROOT, "DeviceSpike-macOS.entitlements"), "w").write(
    '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
    '<!-- PROTOTYPE - NOT FOR PRODUCTION (TASK-078). Sandboxed, no network, no device or location entitlement. -->\n'
    '<plist version="1.0">\n<dict>\n\t<key>com.apple.security.app-sandbox</key>\n\t<true/>\n</dict>\n</plist>\n')
print("wrote DeviceSpike.xcodeproj/project.pbxproj (art: %s)" % ("yes" if has_art else "no, TASK-077 not merged"))
