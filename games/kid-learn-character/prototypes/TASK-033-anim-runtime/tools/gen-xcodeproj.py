# PROTOTYPE - NOT FOR PRODUCTION (TASK-033 spike)
# Writes Spike.xcodeproj (no xcodegen on the machine). Two app targets share the Spike/ folder:
#   Spike        SpriteKit + Rive (RiveRuntime 6.30.1 via SPM)
#   SpikeNoRive  SpriteKit only (NORIVE), for the app-size delta
# Both: iPadOS 26 + macOS 26 (one multiplatform target each), MorphCore as a local package.
#   python3 tools/gen-xcodeproj.py
import hashlib, os

ROOT = os.path.join(os.path.dirname(__file__), "..")
def oid(name):  # deterministic 24-hex object ids
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()

objs = []
def add(name, body):
    objs.append((oid(name), name, body))
    return oid(name)

proj = oid("project")
main_group = oid("group.main")
products_group = oid("group.products")
spike_sync = add("sync.Spike", '{isa = PBXFileSystemSynchronizedRootGroup; path = Spike; sourceTree = "<group>"; }')
fixtures_ref = add("ref.fixtures", '{isa = PBXFileReference; lastKnownFileType = folder; path = fixtures; sourceTree = "<group>"; }')
riv_ref = add("ref.rivassets", '{isa = PBXFileReference; lastKnownFileType = folder; path = rivassets; sourceTree = "<group>"; }')
pkg_local = add("pkg.MorphCore", '{isa = XCLocalSwiftPackageReference; relativePath = MorphCore; }')
pkg_rive = add("pkg.rive", '{isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/rive-app/rive-ios"; requirement = {kind = exactVersion; version = 6.30.1; }; }')

def base_settings(name, bundle, extra):
    s = {
        "PRODUCT_NAME": "\"$(TARGET_NAME)\"",
        "PRODUCT_BUNDLE_IDENTIFIER": bundle,
        "SDKROOT": "auto",
        "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator macosx"',
        "SUPPORTS_MACCATALYST": "NO",
        "TARGETED_DEVICE_FAMILY": "2",
        "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
        "MACOSX_DEPLOYMENT_TARGET": "26.0",
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": '"UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"',
        "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
        "INFOPLIST_KEY_CFBundleDisplayName": name,
        "MARKETING_VERSION": "0.1",
        "CURRENT_PROJECT_VERSION": "1",
        "SWIFT_VERSION": "5.0",
        "CODE_SIGN_STYLE": "Automatic",
        '"CODE_SIGN_IDENTITY[sdk=macosx*]"': '"-"',
        '"CODE_SIGN_ENTITLEMENTS[sdk=macosx*]"': "Spike-macOS.entitlements",
        "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
        "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/Frameworks"',
        '"LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]"': '"$(inherited) @executable_path/../Frameworks"',
    }
    s.update(extra)
    return s

def config_list(tag, settings):
    ids = []
    for cfg in ("Debug", "Release"):
        st = dict(settings)
        if cfg == "Debug":
            st["SWIFT_OPTIMIZATION_LEVEL"] = '"-Onone"'
            st["DEBUG_INFORMATION_FORMAT"] = "dwarf"
        else:
            st["SWIFT_OPTIMIZATION_LEVEL"] = '"-O"'
            st["SWIFT_COMPILATION_MODE"] = "wholemodule"
            st["DEBUG_INFORMATION_FORMAT"] = '"dwarf-with-dsym"'
        body = "{isa = XCBuildConfiguration; buildSettings = {" + "".join(f"{k} = {v}; " for k, v in st.items()) + f"}}; name = {cfg}; }}"
        ids.append(add(f"cfg.{tag}.{cfg}", body))
    return add(f"cfglist.{tag}", "{isa = XCConfigurationList; buildConfigurations = (" + ", ".join(ids) + "); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }")

targets = []
product_refs = []
for name, rive in (("Spike", True), ("SpikeNoRive", False)):
    prod = add(f"prod.{name}", f'{{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {name}.app; sourceTree = BUILT_PRODUCTS_DIR; }}')
    product_refs.append(prod)
    dep_core = add(f"dep.{name}.MorphCore", f'{{isa = XCSwiftPackageProductDependency; package = {pkg_local}; productName = MorphCore; }}')
    deps = [dep_core]
    if rive:
        deps.append(add(f"dep.{name}.Rive", f'{{isa = XCSwiftPackageProductDependency; package = {pkg_rive}; productName = RiveRuntime; }}'))
    fw_files = [add(f"bf.{name}.{d}", f'{{isa = PBXBuildFile; productRef = {d}; }}') for d in deps]
    res_files = [add(f"bf.{name}.fixtures", f'{{isa = PBXBuildFile; fileRef = {fixtures_ref}; }}')]
    if rive:
        res_files.append(add(f"bf.{name}.riv", f'{{isa = PBXBuildFile; fileRef = {riv_ref}; }}'))
    src = add(f"phase.{name}.src", "{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }")
    fw = add(f"phase.{name}.fw", "{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (" + ", ".join(fw_files) + "); runOnlyForDeploymentPostprocessing = 0; }")
    res = add(f"phase.{name}.res", "{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (" + ", ".join(res_files) + "); runOnlyForDeploymentPostprocessing = 0; }")
    extra = {} if rive else {"SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"NORIVE $(inherited)"'}
    cl = config_list(name, base_settings(name, f"com.galaxyandsun.spike033{'' if rive else '.norive'}", extra))
    t = add(f"target.{name}", "{isa = PBXNativeTarget; buildConfigurationList = " + cl + "; buildPhases = (" + f"{src}, {fw}, {res}" +
            "); buildRules = (); dependencies = (); fileSystemSynchronizedGroups = (" + spike_sync + f"); name = {name}; packageProductDependencies = (" +
            ", ".join(deps) + f"); productName = {name}; productReference = {prod}; productType = \"com.apple.product-type.application\"; }}")
    targets.append(t)

add("group.products", "{isa = PBXGroup; children = (" + ", ".join(product_refs) + '); name = Products; sourceTree = "<group>"; }')
add("group.main", "{isa = PBXGroup; children = (" + f"{spike_sync}, {fixtures_ref}, {riv_ref}, {products_group}" + '); sourceTree = "<group>"; }')
proj_cfg = config_list("project", {"ALWAYS_SEARCH_USER_PATHS": "NO", "CLANG_ENABLE_MODULES": "YES", "ENABLE_STRICT_OBJC_MSGSEND": "YES"})
add("project", "{isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2700; LastUpgradeCheck = 2700; }; buildConfigurationList = " +
    proj_cfg + '; compatibilityVersion = "Xcode 15.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = ' + main_group +
    "; minimizedProjectReferenceProxies = 1; packageReferences = (" + f"{pkg_local}, {pkg_rive}" + "); preferredProjectObjectVersion = 77; productRefGroup = " +
    products_group + '; projectDirPath = ""; projectRoot = ""; targets = (' + ", ".join(targets) + "); }")

out = "// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 77;\n\tobjects = {\n"
for i, n, b in sorted(objs, key=lambda o: o[0]):
    out += f"\t\t{i} /* {n} */ = {b};\n"
out += f"\t}};\n\trootObject = {proj};\n}}\n"
os.makedirs(os.path.join(ROOT, "Spike.xcodeproj"), exist_ok=True)
open(os.path.join(ROOT, "Spike.xcodeproj", "project.pbxproj"), "w").write(out)
open(os.path.join(ROOT, "Spike-macOS.entitlements"), "w").write(
    '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
    '<!-- PROTOTYPE - NOT FOR PRODUCTION (TASK-033). Sandboxed WITHOUT com.apple.security.network.client: any network attempt is denied and logged. -->\n'
    '<plist version="1.0">\n<dict>\n\t<key>com.apple.security.app-sandbox</key>\n\t<true/>\n</dict>\n</plist>\n')
print("wrote Spike.xcodeproj/project.pbxproj and Spike-macOS.entitlements")
