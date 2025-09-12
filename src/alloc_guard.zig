const std = @import("std");

/// Wraps an allocator and forbids alloc/resize/free when `allowed` is false.
/// On violations: increments `*violations` and panics.
pub const GuardedAllocator = struct {
    inner: std.mem.Allocator,
    allowed: *bool,
    violations: *u32,

    pub fn init(inner: std.mem.Allocator, allowed: *bool, violations: *u32) GuardedAllocator {
        return .{ .inner = inner, .allowed = allowed, .violations = violations };
    }

    pub fn allocator(self: *GuardedAllocator) std.mem.Allocator {
        return .{ .ptr = self, .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .free = free,
        } };
    }

    fn trip(self: *GuardedAllocator, op: []const u8) void {
        if (!self.allowed.*) {
            self.violations.* += 1;
            std.debug.panic("alloc guard: disallowed {s} during guarded zone", .{op});
        }
    }

    fn alloc(ctx: *anyopaque, n: usize, log2_align: u8, ra: usize) ?[*]u8 {
        const self: *GuardedAllocator = @ptrCast(@alignCast(ctx));
        self.trip("alloc");
        return self.inner.vtable.alloc(self.inner.ptr, n, log2_align, ra);
    }

    fn resize(ctx: *anyopaque, buf: []u8, log2_align: u8, new_n: usize, ra: usize) bool {
        const self: *GuardedAllocator = @ptrCast(@alignCast(ctx));
        self.trip("resize");
        return self.inner.vtable.resize(self.inner.ptr, buf, log2_align, new_n, ra);
    }

    fn free(ctx: *anyopaque, buf: []u8, log2_align: u8, ra: usize) void {
        const self: *GuardedAllocator = @ptrCast(@alignCast(ctx));
        self.trip("free");
        self.inner.vtable.free(self.inner.ptr, buf, log2_align, ra);
    }
};
