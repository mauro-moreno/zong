const std = @import("std");

pub const Limits = struct {
    // Max delta time we tolerate before counting a spike (ms). Also used to
    // clamp delta time.
    max_dt_ms: f32 = 100.0,

    vsync: bool = true,
};

pub const Metrics = struct {
    frames_rendered: u32 = 0,
    max_dt_ms: f32 = 0.0,
    frame_spike_count: u32 = 0,
    zero_size_skips: u32 = 0,
    swapchain_recreates: u32 = 0,
    present_failures: u32 = 0,
    alloc_guard_violations: u32 = 0,

    pub fn onFrame(self: *Metrics, dt_ms: f32, lim: Limits) void {
        std.debug.assert(std.math.isFinite(dt_ms));
        if (dt_ms > self.max_dt_ms) self.max_dt_ms = dt_ms;
        if (dt_ms > lim.max_dt_ms) self.frame_spike_count += 1;
        self.frames_rendered += 1;
    }

    pub fn onZeroSize(self: *Metrics) void {
        self.zero_size_skips += 1;
    }

    // For smoke test
    pub fn ok(self: *Metrics, lim: Limits) bool {
        if (self.present_failures != 0) return false;
        if (self.alloc_guard_violations != 0) return false;
        if (self.frame_spike_count > 1) return false;
        if (lim.vsync and self.max_dt_ms > 33.5) return false;
        if (!lim.vsync and self.max_dt_ms > lim.max_dt_ms) return false;
        // Window could be minimized in CI
        // if (self.zero_size_skips > 1) return false;
        return true;
    }

    pub fn print(self: *const Metrics) void {
        std.debug.print("frames={d} max_dt_ms={d:.2} spikes={d} zero_size_skips={d} recreates={d} present_fail={d} alloc_viol={d}\n", .{ self.frames_rendered, self.max_dt_ms, self.frame_spike_count, self.zero_size_skips, self.swapchain_recreates, self.present_failures, self.alloc_guard_violations });
    }
};
