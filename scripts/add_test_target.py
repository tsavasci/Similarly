import sys

with open('Similarly.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# 1. PBXFileReference section
file_ref = '\t\tF208C6912E9D4000000551CD /* SimilarlyTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = SimilarlyTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };\n'
content = content.replace('/* Begin PBXFileReference section */\n', '/* Begin PBXFileReference section */\n' + file_ref)

# 2. PBXFileSystemSynchronizedRootGroup section
sync_snippet = '''\t\tF208C6932E9D4000000551CD /* SimilarlyTests */ = {
\t\t\tisa = PBXFileSystemSynchronizedRootGroup;
\t\t\tpath = SimilarlyTests;
\t\t\tsourceTree = "<group>";
\t\t};\n'''
content = content.replace('/* Begin PBXFileSystemSynchronizedRootGroup section */\n', '/* Begin PBXFileSystemSynchronizedRootGroup section */\n' + sync_snippet)

# 3. PBXFrameworksBuildPhase section
frameworks_snippet = '''\t\tF208C69E2E9D4000000551CE /* Frameworks */ = {
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};\n'''
content = content.replace('/* Begin PBXFrameworksBuildPhase section */\n', '/* Begin PBXFrameworksBuildPhase section */\n' + frameworks_snippet)

# 4. PBXResourcesBuildPhase section
resources_snippet = '''\t\tF208C69F2E9D4000000551CF /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};\n'''
content = content.replace('/* Begin PBXResourcesBuildPhase section */\n', '/* Begin PBXResourcesBuildPhase section */\n' + resources_snippet)

# 5. PBXSourcesBuildPhase section
sources_snippet = '''\t\tF208C69D2E9D4000000551CD /* Sources */ = {
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t};\n'''
content = content.replace('/* Begin PBXSourcesBuildPhase section */\n', '/* Begin PBXSourcesBuildPhase section */\n' + sources_snippet)

# 6. Main Group & Products
content = content.replace('children = (\n\t\t\t\tF208C6432E9D2A3F000551CD /* Similarly */,\n', 'children = (\n\t\t\t\tF208C6432E9D2A3F000551CD /* Similarly */,\n\t\t\t\tF208C6932E9D4000000551CD /* SimilarlyTests */,\n')
content = content.replace('F208C6412E9D2A3F000551CD /* Similarly.app */,\n', 'F208C6412E9D2A3F000551CD /* Similarly.app */,\n\t\t\t\tF208C6912E9D4000000551CD /* SimilarlyTests.xctest */,\n')

# 7. ContainerItemProxy & TargetDependency
dep_snippet = '''/* Begin PBXContainerItemProxy section */
\t\tF208C6942E9D4000000551CD /* PBXContainerItemProxy */ = {
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = F208C6392E9D2A3F000551CD /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = F208C6402E9D2A3F000551CD;
\t\t\tremoteInfo = Similarly;
\t\t};
/* End PBXContainerItemProxy section */

/* Begin PBXTargetDependency section */
\t\tF208C6922E9D4000000551CD /* PBXTargetDependency */ = {
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = F208C6402E9D2A3F000551CD /* Similarly */;
\t\t\ttargetProxy = F208C6942E9D4000000551CD /* PBXContainerItemProxy */;
\t\t};
/* End PBXTargetDependency section */\n\n'''
content = content.replace('/* Begin PBXNativeTarget section */', dep_snippet + '/* Begin PBXNativeTarget section */')

# 8. PBXNativeTarget
native_target_snippet = '''\t\tF208C6902E9D4000000551CD /* SimilarlyTests */ = {
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = F208C69E2E9D4000000551CD /* Build configuration list for PBXNativeTarget "SimilarlyTests" */;
\t\t\tbuildPhases = (
\t\t\t\tF208C69D2E9D4000000551CD /* Sources */,
\t\t\t\tF208C69E2E9D4000000551CE /* Frameworks */,
\t\t\t\tF208C69F2E9D4000000551CF /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\tF208C6922E9D4000000551CD /* PBXTargetDependency */,
\t\t\t);
\t\t\tfileSystemSynchronizedGroups = (
\t\t\t\tF208C6932E9D4000000551CD /* SimilarlyTests */,
\t\t\t);
\t\t\tname = SimilarlyTests;
\t\t\tpackageProductDependencies = (
\t\t\t);
\t\t\tproductName = SimilarlyTests;
\t\t\tproductReference = F208C6912E9D4000000551CD /* SimilarlyTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t};\n'''
content = content.replace('targets = (\n\t\t\t\tF208C6402E9D2A3F000551CD /* Similarly */,\n', 'targets = (\n\t\t\t\tF208C6402E9D2A3F000551CD /* Similarly */,\n\t\t\t\tF208C6902E9D4000000551CD /* SimilarlyTests */,\n')
content = content.replace('/* Begin PBXNativeTarget section */\n', '/* Begin PBXNativeTarget section */\n' + native_target_snippet)

# 9. TargetAttributes
target_attr_snippet = '''\t\t\t\t\tF208C6902E9D4000000551CD = {
\t\t\t\t\t\tCreatedOnToolsVersion = 26.0.1;
\t\t\t\t\t\tTestTargetID = F208C6402E9D2A3F000551CD;
\t\t\t\t\t};\n'''
content = content.replace('TargetAttributes = {\n', 'TargetAttributes = {\n' + target_attr_snippet)

# 10. XCBuildConfiguration
test_configs = '''\t\tF208C69F2E9D4000000551CD /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = T54PTGTNBU;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.6;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = tsavasci.SimilarlyTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_APPROACHABLE_CONCURRENCY = YES;
\t\t\t\tSWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Similarly.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Similarly";
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\tF208C6A02E9D4000000551CD /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = T54PTGTNBU;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 18.6;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = tsavasci.SimilarlyTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_APPROACHABLE_CONCURRENCY = YES;
\t\t\t\tSWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Similarly.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Similarly";
\t\t\t};
\t\t\tname = Release;
\t\t};\n'''
content = content.replace('/* Begin XCBuildConfiguration section */\n', '/* Begin XCBuildConfiguration section */\n' + test_configs)

# 11. XCConfigurationList
test_config_list = '''\t\tF208C69E2E9D4000000551CD /* Build configuration list for PBXNativeTarget "SimilarlyTests" */ = {
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\tF208C69F2E9D4000000551CD /* Debug */,
\t\t\t\tF208C6A02E9D4000000551CD /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t};\n'''
content = content.replace('/* Begin XCConfigurationList section */\n', '/* Begin XCConfigurationList section */\n' + test_config_list)

with open('Similarly.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Successfully injected SimilarlyTests target into project.pbxproj")
