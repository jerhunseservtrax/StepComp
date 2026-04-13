import Foundation

#if canImport(Sentry)
import Sentry
#endif

enum CrashReportingService {
    static func configure() {
        #if canImport(Sentry)
        guard let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String,
              !dsn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
            options.enableMetricKit = true
            options.enableAutoPerformanceTracing = true
            options.attachScreenshot = false
            options.attachViewHierarchy = false
        }
        #endif
    }

    static func capture(error: Error, context: String? = nil) {
        #if canImport(Sentry)
        SentrySDK.capture(error: error) { scope in
            if let context {
                scope.setTag(value: context, key: "context")
            }
        }
        #endif
    }
}
