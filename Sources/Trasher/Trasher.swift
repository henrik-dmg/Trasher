import ArgumentParser
import Foundation

@main
struct Trasher: ParsableCommand {

    @Argument(help: "The file URL we want.", transform: URL.init(fileURLWithPath:))
    var file: URL

    mutating func validate() throws {
        // Verify the file actually exists.
        guard FileManager.default.fileExists(atPath: file.path) else {
            throw ValidationError("File does not exist at \(file.path)")
        }
    }

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
            print("Supplied path is a directory. To delete a directory, supply the --recursive or -r flag")
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
        let myAppleScript = """
        tell application "Finder"
            move POSIX file "\(file.path)" to trash
        end tell
        """
        guard let scriptObject = NSAppleScript(source: myAppleScript) else {
            print("Could not launch AppleScript")
            Darwin.exit(1)
        }
        var error: NSDictionary?
        _ = scriptObject.executeAndReturnError(&error)
        if let error {
            print("error: \(error)")
        }
    }

}
