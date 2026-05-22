import ProjectDescription

public enum BundlePrefix {
    public static let id = "com.juancanul.LifeOS"
    public static let org = "com.juancanul"
}

public enum Deployment {
    public static let iOS: DeploymentTargets = .iOS("26.0")
}

public enum ModuleLayer: String {
    case core         = "Modules/Core"
    case ai           = "Modules/AI"
    case feature      = "Modules/Features"
    case integration  = "Modules/Integrations"
}

public extension Target {
    /// Framework target for a feature/core/ai module.
    /// Every module is its own framework so the compiler enforces the dependency graph.
    static func module(
        _ name: String,
        layer: ModuleLayer,
        dependencies: [TargetDependency] = [],
        hasResources: Bool = false
    ) -> Target {
        let path = "\(layer.rawValue)/\(name)"
        var resources: ResourceFileElements? = nil
        if hasResources {
            resources = ["\(path)/Resources/**"]
        }
        return .target(
            name: name,
            destinations: .iOS,
            product: .framework,
            bundleId: "\(BundlePrefix.id).\(name)",
            deploymentTargets: Deployment.iOS,
            sources: ["\(path)/Sources/**"],
            resources: resources,
            dependencies: dependencies,
            settings: .moduleSettings()
        )
    }
}

public extension Settings {
    /// Shared build settings. Strict concurrency on, warnings → errors in release.
    static func moduleSettings() -> Settings {
        .settings(
            base: [
                "SWIFT_VERSION": "6.0",
                "SWIFT_STRICT_CONCURRENCY": "complete",
                "SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY": "YES",
                "SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT": "NO",
                "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
                "GENERATE_INFOPLIST_FILE": "YES",
                "MARKETING_VERSION": "0.3.0",
                "CURRENT_PROJECT_VERSION": "1"
            ],
            configurations: [
                .debug(name: "Debug",   settings: ["SWIFT_OPTIMIZATION_LEVEL": "-Onone"]),
                .release(name: "Release", settings: ["SWIFT_OPTIMIZATION_LEVEL": "-O", "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES"])
            ],
            defaultSettings: .recommended
        )
    }

    static func appSettings() -> Settings {
        // `INFOPLIST_FILE`, `CODE_SIGN_ENTITLEMENTS`, and `GENERATE_INFOPLIST_FILE`
        // are intentionally NOT set here — Tuist writes them automatically from
        // the target's `infoPlist:` and `entitlements:` parameters. Setting them
        // here too would cause the entitlements/plist to be both linked AND
        // copied into the bundle as a resource.
        .settings(
            base: [
                "SWIFT_VERSION": "6.0",
                "SWIFT_STRICT_CONCURRENCY": "complete",
                "SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY": "YES",
                "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
                "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
                "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
                "MARKETING_VERSION": "0.3.0",
                "CURRENT_PROJECT_VERSION": "1",
                "DEVELOPMENT_TEAM": "",
                "CODE_SIGN_STYLE": "Automatic",
                "TARGETED_DEVICE_FAMILY": "1,2",
                "SUPPORTS_MACCATALYST": "NO",
                "ENABLE_PREVIEWS": "YES"
            ],
            configurations: [
                .debug(name: "Debug",   settings: ["SWIFT_OPTIMIZATION_LEVEL": "-Onone"]),
                .release(name: "Release", settings: ["SWIFT_OPTIMIZATION_LEVEL": "-O"])
            ],
            defaultSettings: .recommended
        )
    }
}
