const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;

const App = @This();

// Max Delta Time in milliseconds.
const MaxDtMs: f32 = 100.0;

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

pub fn init(core: *mach.Core, app: *App, app_mod: mach.Mod(App)) !void {
    core.on_tick = app_mod.id.tick;
    core.on_exit = app_mod.id.deinit;

    const win = try core.windows.new(.{
        .title = "Zong",
    });

    app.* = .{
        .window = win,
        .prev_ns = std.time.nanoTimestamp(),
    };
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
    var dt_ms = @as(f32, @floatFromInt(now_ns - app.prev_ns)) / 1_000_000.0;
    app.prev_ns = now_ns;
    if (!std.math.isFinite(dt_ms)) dt_ms = 0;
    if (dt_ms > MaxDtMs) dt_ms = MaxDtMs;

    // Render: clear-only pass.
    var window = core.windows.getValue(app.window);
    defer core.windows.setValueRaw(app.window, window);

    // Safe on zero-size/minimized.
    const texture_view = window.swap_chain.getCurrentTextureView();
    if (texture_view == null) {
        // If zero-sized surface (e.g. minimized) skip this frame.
        std.time.sleep(5 * std.time.ms_per_s);
        return;
    }
    const back_buffer_view = texture_view.?;
    defer back_buffer_view.release();

    // Command encoder
    const label = @tagName(mach_module) ++ ".tick";
    const encoder = window.device.createCommandEncoder(&.{ .label = label });
    defer encoder.release();

    const background_color = gpu.Color{ .r = 0.133, .g = 0.133, .b = 0.204, .a = 1.0 };
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
}

pub fn deinit(app: *App) void {
    _ = app;
}
