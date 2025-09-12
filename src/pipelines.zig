const std = @import("std");
const mach = @import("mach");
const gpu = mach.gpu;

// Uniforms
pub const RectUBO = struct {
    resolution: [2]f32,
    pos: [2]f32,
    size: [2]f32,
    _pad0: [2]f32,
    color: [4]f32,
};
pub const CircleUBO = struct {
    resolution: [2]f32,
    center: [2]f32,
    radius: f32,
    _pad0: f32,
    _pad1: [2]f32,
    color: [4]f32,
};

fn alignedSize(comptime T: type) usize {
    // Uniform buffers like 16B multiples; our struct alredy are,
    // but align defensively.
    return std.mem.alignForward(usize, @sizeOf(T), 16);
}

fn alignedSize32(comptime T: type) u32 {
    return @intCast(std.mem.alignForward(usize, @sizeOf(T), 32));
}

fn alignedSize64(comptime T: type) u64 {
    return @intCast(std.mem.alignForward(usize, @sizeOf(T), 16));
}

comptime {
    std.debug.assert(@sizeOf(RectUBO) == 48);
    std.debug.assert(@sizeOf(CircleUBO) == 48);
}

// Small containers for GPU objects.
const RectPip = struct {
    module: *gpu.ShaderModule,
    pipeline: *gpu.RenderPipeline,
    ubo: *gpu.Buffer,
    bind: *gpu.BindGroup,
};
const CirclePip = struct {
    module: *gpu.ShaderModule,
    pipeline: *gpu.RenderPipeline,
    ubo: *gpu.Buffer,
    bind: *gpu.BindGroup,
};

pub const Pipelines = struct {
    rect: RectPip,
    circle: CirclePip,

    /// Build both pipelines. Call during init (alloc_allowed=true).
    pub fn init(device: *gpu.Device, framebuffer_format: anytype) !Pipelines {
        // Shared bind group layout: one uniform buffer at binding(0).
        const blg = device.createBindGroupLayout(&gpu.BindGroupLayout.Descriptor.init(.{
            .entries = &[_]gpu.BindGroupLayout.Entry{.{
                .binding = 0,
                .visibility = .{ .fragment = true },
                .buffer = .{ .type = .uniform, .min_binding_size = alignedSize64(RectUBO), .has_dynamic_offset = .false },
            }},
        }));
        defer blg.release();

        const layout = device.createPipelineLayout(&gpu.PipelineLayout.Descriptor.init(.{
            .bind_group_layouts = &[_]*gpu.BindGroupLayout{blg},
        }));
        defer layout.release();

        // Paddles
        const rect_src = @embedFile("shaders/rect.wgsl");
        const rect_mod = device.createShaderModuleWGSL("rect.wgsl", rect_src);

        const rect_color_target = gpu.ColorTargetState{
            .format = framebuffer_format,
            .blend = null,
            .write_mask = .{ .red = true, .green = true, .blue = true, .alpha = true },
        };
        const rect_pipeline = device.createRenderPipeline(&gpu.RenderPipeline.Descriptor{
            .layout = layout,
            .vertex = .{
                .module = rect_mod,
                .entry_point = "vs_main",
            },
            .fragment = &gpu.FragmentState.init(.{
                .module = rect_mod,
                .entry_point = "fs_main",
                .targets = &[_]gpu.ColorTargetState{rect_color_target},
            }),
            .primitive = .{ .topology = .triangle_list },
        });

        const rect_ubo = device.createBuffer(&gpu.Buffer.Descriptor{
            .size = alignedSize64(RectUBO),
            .usage = .{ .copy_dst = true },
        });
        const rect_bind = device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
            .layout = blg,
            .entries = &[_]gpu.BindGroup.Entry{.{
                .binding = 0,
                .buffer = rect_ubo,
                .offset = 0,
                .size = alignedSize64(RectUBO),
            }},
        }));

        // Circle
        const circle_src = @embedFile("shaders/circle.wgsl");
        const circle_mod = device.createShaderModuleWGSL("circle.wgsl", circle_src);

        const circle_color_target = gpu.ColorTargetState{
            .format = framebuffer_format,
            .blend = null,
            .write_mask = .{ .red = true, .green = true, .blue = true, .alpha = true },
        };
        const circle_pipeline = device.createRenderPipeline(&gpu.RenderPipeline.Descriptor{
            .layout = layout,
            .vertex = .{
                .module = circle_mod,
                .entry_point = "vs_main",
            },
            .fragment = &gpu.FragmentState.init(.{
                .module = circle_mod,
                .entry_point = "fs_main",
                .targets = &[_]gpu.ColorTargetState{circle_color_target},
            }),
            .primitive = .{ .topology = .triangle_list },
        });

        const circle_ubo = device.createBuffer(&gpu.Buffer.Descriptor{
            .size = alignedSize64(CircleUBO),
            .usage = .{ .copy_dst = true },
        });
        const circle_bind = device.createBindGroup(&gpu.BindGroup.Descriptor.init(.{
            .layout = blg,
            .entries = &[_]gpu.BindGroup.Entry{.{
                .binding = 0,
                .buffer = circle_ubo,
                .offset = 0,
                .size = alignedSize64(CircleUBO),
            }},
        }));

        return .{
            .rect = .{ .module = rect_mod, .pipeline = rect_pipeline, .ubo = rect_ubo, .bind = rect_bind },
            .circle = .{ .module = circle_mod, .pipeline = circle_pipeline, .ubo = circle_ubo, .bind = circle_bind },
        };
    }

    pub fn deinit(self: *Pipelines) void {
        // Release in safe order.
        self.rect.bind.release();
        self.rect.ubo.release();
        self.rect.pipeline.release();
        self.rect.module.release();

        self.circle.bind.release();
        self.circle.ubo.release();
        self.circle.pipeline.release();
        self.circle.module.release();
    }

    /// Update UBO + draw a rectangle (paddle)
    pub fn drawRect(self: *Pipelines, rp: *gpu.RenderPassEncoder, queue: *gpu.Queue, u: RectUBO) void {
        std.debug.assert(std.math.isFinite(u.pos[0]) and std.math.isFinite(u.pos[1]));
        std.debug.assert(u.size[0] > 0 and u.size[1] > 1);
        std.debug.assert(u.color[0] >= 0 and u.color[0] <= 1);
        std.debug.assert(u.color[1] >= 0 and u.color[1] <= 1);
        std.debug.assert(u.color[2] >= 0 and u.color[2] <= 1);
        std.debug.assert(u.color[3] >= 0 and u.color[3] <= 1);

        queue.writeBuffer(self.rect.ubo, 0, std.mem.asBytes(&u));
        rp.setPipeline(self.rect.pipeline);
        rp.setBindGroup(0, self.rect.bind, &.{});
        rp.draw(6, 1, 0, 0);
    }

    /// Update UBO + draw a circle (ball)
    pub fn drawCircle(self: *Pipelines, rp: *gpu.RenderPassEncoder, queue: *gpu.Queue, u: CircleUBO) void {
        std.debug.assert(std.math.isFinite(u.center[0]) and std.math.isFinite(u.center[1]));
        std.debug.assert(u.radius > 0);
        std.debug.assert(u.color[0] >= 0 and u.color[0] <= 1);
        std.debug.assert(u.color[1] >= 0 and u.color[1] <= 1);
        std.debug.assert(u.color[2] >= 0 and u.color[2] <= 1);
        std.debug.assert(u.color[3] >= 0 and u.color[3] <= 1);

        queue.writeBuffer(self.circle.ubo, 0, std.mem.asBytes(&u));
        rp.setPipeline(self.circle.pipeline);
        rp.setBindGroup(0, self.circle.bind, &.{});
        rp.draw(6, 1, 0, 0);
    }
};
