import ArgumentParser
import Foundation

@main
struct Trasher: ParsableCommand {

    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName: "trasher", version: "0.0.1")
    }

    @Argument(help: "The file or folder you want to delete", transform: URL.init(fileURLWithPath:))
    var file: URL

    @Flag(name: .shortAndLong)
    var recursive = false

    @Flag(name: .shortAndLong)
    var force = false

    func run() throws {
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory) else {
            throw ValidationError("File does not exist at \(file.path)")
        }
        if isDirectory.boolValue && !recursive {
            print("WARNING: Supplied path is a directory. To delete a directory, supply the --recursive or -r flag")
            Darwin.exit(1)
        } else {
            if force {
                try FileManager.default.removeItem(at: file)
            } else {
                moveFileToTrash()
            }
        }
    }

    private func moveFileToTrash() {
        let appleScript = """
        tell application "Finder"
            move POSIX file "\(file.path)" to trash
        end tell
        """
        guard let scriptObject = NSAppleScript(source: appleScript) else {
            print("Could not launch AppleScript")
            Darwin.exit(1)
        }
        var error: NSDictionary?
        _ = scriptObject.executeAndReturnError(&error)
        if let error {
            print("error: \(error)")
            Darwin.exit(1)
        }
    }

}
