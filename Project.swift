import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Core layer

let designSystem  = Target.module("DesignSystem",   layer: .core)
let domainKit     = Target.module("DomainKit",      layer: .core)
let securityKit   = Target.module("SecurityKit",    layer: .core)
let networkingKit = Target.module("NetworkingKit",  layer: .core)
let persistenceKit = Target.module(
    "PersistenceKit",
    layer: .core,
    dependencies: [.target(name: "DomainKit")]
)
let sharedUI = Target.module(
    "SharedUI",
    layer: .core,
    dependencies: [.target(name: "DesignSystem")]
)

// MARK: - AI layer

let aiKit = Target.module(
    "AIKit",
    layer: .ai,
    dependencies: [.target(name: "DomainKit")]
)
let foundationModelsProvider = Target.module(
    "FoundationModelsProvider",
    layer: .ai,
    dependencies: [.target(name: "AIKit")]
)
let mlxProvider = Target.module(
    "MLXProvider",
    layer: .ai,
    dependencies: [.target(name: "AIKit")]
)
let ollamaProvider = Target.module(
    "OllamaProvider",
    layer: .ai,
    dependencies: [
        .target(name: "AIKit"),
        .target(name: "NetworkingKit")
    ]
)
let deepSeekProvider = Target.module(
    "DeepSeekProvider",
    layer: .ai,
    dependencies: [
        .target(name: "AIKit"),
        .target(name: "NetworkingKit"),
        .target(name: "SecurityKit")
    ]
)

// MARK: - Integration layer

let healthKitBridge = Target.module("HealthKitBridge", layer: .integration)

// MARK: - Feature layer

let featureDependencies: [TargetDependency] = [
    .target(name: "DesignSystem"),
    .target(name: "SharedUI"),
    .target(name: "DomainKit"),
    .target(name: "PersistenceKit"),
    .target(name: "AIKit")
]

let dashboardFeature = Target.module("Dashboard", layer: .feature, dependencies: featureDependencies)
let tasksFeature     = Target.module("Tasks",     layer: .feature, dependencies: featureDependencies)
let notesFeature     = Target.module("Notes",     layer: .feature, dependencies: featureDependencies)
let focusFeature     = Target.module("Focus",     layer: .feature, dependencies: featureDependencies)
let assistantFeature = Target.module("Assistant", layer: .feature, dependencies: featureDependencies)
let financeFeature   = Target.module("Finance",   layer: .feature, dependencies: featureDependencies)
let healthFeature    = Target.module(
    "Health",
    layer: .feature,
    dependencies: featureDependencies + [.target(name: "HealthKitBridge")]
)
let settingsFeature  = Target.module(
    "Settings",
    layer: .feature,
    dependencies: featureDependencies + [.target(name: "SecurityKit")]
)

// MARK: - Widget Extension
//
// DEFERRED — Phase 7c. The code is in `Widgets/LifeOSWidgets/Sources/`
// (TodayTasksWidget, FocusLiveActivity, FocusActivityAttributes) but the
// target isn't wired into the project yet. Reason: it needs App Groups
// entitlement to share the SwiftData store with the app, and configuring
// App Groups on a free Apple ID requires manual setup at
// developer.apple.com that we don't want to lock behind a build error.
//
// To enable later:
// 1. Enable App Groups capability for both targets (paid developer or
//    set up the App Group identifier manually for free)
// 2. Update PersistenceFactory to use the shared container URL
// 3. Uncomment the widgetExtension target and add it to `targets:` below

// MARK: - App target

let appTarget: Target = .target(
    name: "LifeOS",
    destinations: .iOS,
    product: .app,
    bundleId: BundlePrefix.id,
    deploymentTargets: Deployment.iOS,
    infoPlist: .file(path: "App/Resources/Info.plist"),
    sources: ["App/Sources/**"],
    resources: ["App/Resources/Assets.xcassets"],
    entitlements: .file(path: "App/Resources/LifeOS.entitlements"),
    dependencies: [
        // Core
        .target(name: "DesignSystem"),
        .target(name: "SharedUI"),
        .target(name: "DomainKit"),
        .target(name: "PersistenceKit"),
        .target(name: "SecurityKit"),
        .target(name: "NetworkingKit"),

        // AI
        .target(name: "AIKit"),
        .target(name: "FoundationModelsProvider"),
        .target(name: "MLXProvider"),
        .target(name: "OllamaProvider"),
        .target(name: "DeepSeekProvider"),

        // Integration
        .target(name: "HealthKitBridge"),

        // Features
        .target(name: "Dashboard"),
        .target(name: "Tasks"),
        .target(name: "Notes"),
        .target(name: "Focus"),
        .target(name: "Assistant"),
        .target(name: "Finance"),
        .target(name: "Health"),
        .target(name: "Settings")
    ],
    settings: .appSettings()
)

let appTests: Target = .target(
    name: "LifeOSTests",
    destinations: .iOS,
    product: .unitTests,
    bundleId: "\(BundlePrefix.id).Tests",
    deploymentTargets: Deployment.iOS,
    sources: ["App/Tests/**"],
    dependencies: [.target(name: "LifeOS")]
)

// MARK: - Project

let project = Project(
    name: "LifeOS",
    organizationName: BundlePrefix.org,
    options: .options(
        automaticSchemesOptions: .enabled(
            targetSchemesGrouping: .singleScheme,
            codeCoverageEnabled: true,
            testingOptions: []
        ),
        defaultKnownRegions: ["en"],
        developmentRegion: "en"
    ),
    targets: [
        // Core
        designSystem, domainKit, persistenceKit,
        securityKit, networkingKit, sharedUI,

        // AI
        aiKit, foundationModelsProvider, mlxProvider, ollamaProvider, deepSeekProvider,

        // Integration
        healthKitBridge,

        // Features
        dashboardFeature, tasksFeature, notesFeature, focusFeature,
        assistantFeature, financeFeature, healthFeature, settingsFeature,

        // App
        appTarget, appTests
    ]
)
