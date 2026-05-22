import ProjectDescription

let config = Config(
    compatibleXcodeVersions: .upToNextMajor("26.0"),
    swiftVersion: "6.0",
    generationOptions: .options(
        resolveDependenciesWithSystemScm: false,
        disablePackageVersionLocking: false
    )
)
