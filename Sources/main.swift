import AppKit
import ApplicationServices
import Darwin

// Protect simultaneous launches, including direct executable launches.
let lockPath = NSTemporaryDirectory() + "com.fernando.mxjiggler-\(getuid()).lock"
let instanceLock = Darwin.open(lockPath, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
guard instanceLock >= 0, flock(instanceLock, LOCK_EX | LOCK_NB) == 0 else { exit(0) }
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
