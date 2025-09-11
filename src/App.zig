const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;

const Metrics = @import("metrics.zig").Metrics;
const Limits = @import("metrics.zig").Limits;

const App = @This();

// Mach module wiring.
pub const mach_module = .app;
pub const Modules = mach.Modules(.{ mach.Core, App });
pub const mach_systems = .{ .main, .init, .tick, .deinit };
pub const main = mach.schedule(.{
    .{ mach.Core, .init },
    .{ App, .init },
    .{ mach.Core, .main },
});

// State
window: mach.ObjectID,
prev_ns: i128,

// Metrics + Limits + smoke test controls
metrics: Metrics,
limits: Limits = .{ .max_dt_ms = 100.0, .vsync = true },
smoke_mode: bool = false,
smoke_frames_left: u32 = 0,
log_accum_ns: i128 = 0,

pub fn init(core: *mach.Core, app: *App, app_mod: mach.Mod(App)) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    // Parse flags
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    var smoke_frames: ?u32 = null;
    var lim = app.limits;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const a = args[i];
        if (std.mem.eql(u8, a, "--smoke-frames") and i + 1 < args.len) {
            smoke_frames = try std.fmt.parseInt(u32, args[i + 1], 10);
            i += 1;
        } else if (std.mem.eql(u8, a, "--max-dt-ms") and i + 1 < args.len) {
            lim.max_dt_ms = try std.fmt.parseFloat(f32, args[i + 1]);
            i += 1;
        } else if (std.mem.eql(u8, a, "--no-vsync")) {
            lim.vsync = false;
        }
    }

    const win = try core.windows.new(.{
        .title = "Zong",
    });

    app.* = .{
        .window = win,
        .prev_ns = std.time.nanoTimestamp(),
        .metrics = .{},
        .limits = lim,
        .smoke_mode = smoke_frames != null,
        .smoke_frames_left = smoke_frames orelse 0,
        .log_accum_ns = 0,
    };

    // Startup log
    std.debug.print("Zong init: max_dt_ms={d:.2} vsync={}\n", .{ app.limits.max_dt_ms, app.limits.vsync });
}

pub fn tick(app: *App, core: *mach.Core) void {
    // Events
    while (core.nextEvent()) |ev| {
        switch (ev) {
            .close => core.exit(),
            else => {},
        }
    }

    // Time is monotonic
    const now_ns = std.time.nanoTimestamp();
    std.debug.assert(now_ns >= app.prev_ns);
    const raw_dt_ns: i128 = now_ns - app.prev_ns;
    app.prev_ns = now_ns;

    var dt_ms = @as(f32, @floatFromInt(now_ns - app.prev_ns)) / 1_000_000.0;
    if (!std.math.isFinite(dt_ms)) dt_ms = 0;
    if (dt_ms > app.limits.max_dt_ms) dt_ms = app.limits.max_dt_ms;

    // Count/log every frame (even if skipped rendering)
    app.metrics.onFrame(dt_ms, app.limits);

    // Heartbeat
    app.log_accum_ns += raw_dt_ns;
    if (app.log_accum_ns >= 1_000_000_000) {
        app.log_accum_ns = 0;
        app.metrics.print();
    }

    // Render: clear-only pass.
    var window = core.windows.getValue(app.window);
    defer core.windows.setValueRaw(app.window, window);

    // Safe on zero-size/minimized.
    const texture_view = window.swap_chain.getCurrentTextureView();
    if (texture_view == null) {
        // If zero-sized surface (e.g. minimized) skip this frame.
        app.metrics.onZeroSize();
        std.time.sleep(5 * std.time.ns_per_ms);
        return app.finishSmokeIfNeeded();
    }
    const back_buffer_view = texture_view.?;
    defer back_buffer_view.release();

    // Command encoder
    const label = @tagName(mach_module) ++ ".tick";
    const encoder = window.device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    const background_color = gpu.Color{ .r = 0.3, .g = 0.3, .b = 0.46, .a = 1.0 };
    std.debug.assert(std.math.isFinite(background_color.r) and background_color.r >= 0 and background_color.r <= 1);
    std.debug.assert(std.math.isFinite(background_color.g) and background_color.g >= 0 and background_color.g <= 1);
    std.debug.assert(std.math.isFinite(background_color.b) and background_color.b >= 0 and background_color.b <= 1);
    std.debug.assert(std.math.isFinite(background_color.a) and background_color.a >= 0 and background_color.a <= 1);
    const color_attachments = [_]gpu.RenderPassColorAttachment{.{
        .view = back_buffer_view,
        .clear_value = background_color,
        .load_op = .clear,
        .store_op = .store,
    }};

    const render_pass = encoder.beginRenderPass(&gpu.RenderPassDescriptor.init(.{
        .label = label,
        .color_attachments = &color_attachments,
    }));

    render_pass.end();
    render_pass.release();

    // Submit our commands to the queue
    var cmd = encoder.finish(&.{ .label = label });
    defer cmd.release();
    window.queue.submit(&[_]*gpu.CommandBuffer{cmd});
    
    return app.finishSmokeIfNeeded();
}

fn finishSmokeIfNeeded(app: *App) void {
    if (!app.smoke_mode) return;

    if (app.smoke_frames_left > 0) app.smoke_frames_left -= 1;

    if (app.smoke_frames_left == 0) {
        app.metrics.print();
        if (!app.metrics.ok(app.limits)) {
            std.debug.print("SMOKE FAIL\n", .{});
            std.process.exit(1);
        } else {
            std.debug.print("SMOKE PASS\n", .{});
            std.process.exit(0);
        }
    }
}

pub fn deinit(app: *App) void {
    _ = app;
}
