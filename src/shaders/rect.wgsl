struct UBO {
  resolution : vec2<f32>;   // e.g., 800,600
  pos        : vec2<f32>;   // top-left in pixels
  size       : vec2<f32>;   // width, height in pixels
  color      : vec4<f32>;   // RGBA (0..1)
};
@group(0) @binding(0) var<uniform> u : UBO;

struct VSOut {
  @builtin(position) pos : vec4<f32>;
};

fn to_ndc(px: vec2<f32>) -> vec4<f32> {
  // pixels -> NDC, origin top-left
  let ndc = vec2<f32>(
    (px.x / u.resolution.x) * 2.0 - 1.0,
    1.0 - (px.y / u.resolution.y) * 2.0
  );
  return vec4<f32>(ndc, 0.0, 1.0);
}

@vertex
fn vs_main(@builtin(vertex_index) vi: u32) -> VSOut {
  // 2 triangles covering [0,1]^2 in local space
  var quad = array<vec2<f32>, 6>(
    vec2<f32>(0.0, 0.0), vec2<f32>(1.0, 0.0), vec2<f32>(0.0, 1.0),
    vec2<f32>(1.0, 0.0), vec2<f32>(1.0, 1.0), vec2<f32>(0.0, 1.0),
  );
  let lp = quad[vi];                    // local [0,1]
  let px = u.pos + lp * u.size;         // to pixels
  var out: VSOut;
  out.pos = to_ndc(px);
  return out;
}

@fragment
fn fs_main(_: VSOut) -> @location(0) vec4<f32> {
  return u.color; // opaque solid color
}

