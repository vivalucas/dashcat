import Darwin
import Foundation

typealias MonitorInfo = (value: Double, description: String)

final class SystemMonitor {
    static let `default` = MonitorInfo(0.0, "0% ")

    // MARK: - CPU

    private let hostPort = mach_host_self()
    private let cpuInfoCount: mach_msg_type_number_t
    private var previousLoad = host_cpu_load_info()

    // MARK: - Memory

    private let pageSize: Double
    private let totalMemory: Double

    deinit {
        mach_port_deallocate(mach_task_self_, hostPort)
    }

    init() {
        cpuInfoCount = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        pageSize = Double(vm_kernel_page_size)
        var memsize: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &memsize, &size, nil, 0)
        totalMemory = memsize > 0 ? Double(memsize) : Double(ProcessInfo.processInfo.physicalMemory)

        // Sample once to set baseline, avoiding inaccurate first reading
        var info = host_cpu_load_info()
        var count = cpuInfoCount
        withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                _ = host_statistics(hostPort, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        previousLoad = info
    }

    // MARK: - CPU Usage

    func cpuUsage() -> MonitorInfo {
        var info = host_cpu_load_info()
        var count = cpuInfoCount
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(hostPort, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return Self.default }

        let prev = previousLoad.cpu_ticks
        let curr = info.cpu_ticks
        previousLoad = info
        let user = curr.0 >= prev.0 ? Double(curr.0 - prev.0) : 0
        let sys  = curr.1 >= prev.1 ? Double(curr.1 - prev.1) : 0
        let idle = curr.2 >= prev.2 ? Double(curr.2 - prev.2) : 0
        let nice = curr.3 >= prev.3 ? Double(curr.3 - prev.3) : 0

        let total = user + sys + idle + nice
        guard total > 0 else { return Self.default }
        let value = min(99.9, (1000.0 * (user + sys + nice) / total).rounded() / 10.0)
        return MonitorInfo(value, String(format: "%.0f%% ",value))
    }

    // MARK: - Memory Usage

    func memoryUsage() -> MonitorInfo {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let ok = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        guard ok == KERN_SUCCESS else { return Self.default }

        return Self.memoryUsage(active: Double(stats.active_count) * pageSize,
            inactive: Double(stats.inactive_count) * pageSize, wired: Double(stats.wire_count) * pageSize,
            compressed: Double(stats.compressor_page_count) * pageSize,
            purgeable: Double(stats.purgeable_count) * pageSize, fileBacked: Double(stats.external_page_count) * pageSize,
            total: totalMemory)
    }

    static func memoryUsage(active: Double, inactive: Double, wired: Double, compressed: Double,
                            purgeable: Double, fileBacked: Double, total: Double) -> MonitorInfo {
        guard total > 0 else { return Self.default }
        // Physical resident app/system pages plus compressor storage, excluding
        // purgeable pages and reclaimable file-backed cache. Swap is disk space.
        let used = max(0, active + inactive + wired + compressed - purgeable - fileBacked)
        let value = min(100, used / total * 100)
        return MonitorInfo(value, String(format: "%.0f%% ", value))
    }
}
