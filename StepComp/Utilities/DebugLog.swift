import Foundation

enum DebugLog {
    static var filePath: String {
        (NSTemporaryDirectory() as NSString).appendingPathComponent("stepcomp-debug.log")
    }
}
