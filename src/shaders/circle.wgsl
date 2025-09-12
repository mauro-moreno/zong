// circle.wgsl — solid circle via quad + discard
struct UBO {
  resolution : vec2<f32>;   // pixels
  center     : vec2<f32>;   // center in pixels
  radius     : f32;         // pixels
  _pad0      : f32;
  color      : vec4<f32>;   // RGBA
};
@group(0) @binding(0) var<uniform> u : UBO;

struct VSOut {
  @builtin(position) pos : vec4<f32>;
  @location(0) local : vec2<f32>; // local in [-1,1] for circle math
};

fn to_ndc(px: vec2<f32>) -> vec4<f32> {
  let ndc = vec2<f32>(
    (px.x / u.resolution.x) * 2.0 - 1.0,
    1.0 - (px.y / u.resolution.y) * 2.0
  );
  return vec4<f32>(ndc, 0.0, 1.0);
}

@vertex
fn vs_main(@builtin(vertex_index) vi: u32) -> VSOut {
  // Unit quad in local [-1,1]^2, scaled by radius, then translated to center
  var quad = array<vec2<f32>, 6>(
    vec2<f32>(-1.0, -1.0), vec2<f32>( 1.0, -1.0), vec2<f32>(-1.0,  1.0),
    vec2<f32>( 1.0, -1.0), vec2<f32>( 1.0,  1.0), vec2<f32>(-1.0,  1.0),
  );
  let lp = quad[vi];
  let px = u.center + lp * vec2<f32>(u.radius, u.radius);
  var out: VSOut;
  out.pos = to_ndc(px);
  out.local = lp; // keep for fragment distance test
  return out;
}

@fragment
fn fs_main(in: VSOut) -> @location(0) vec4<f32> {
  // Distance from center in local space
  let d = length(in.local) - 1.0;  // >0 is outside
  if (d > 0.0) { discard; }
  return u.color;
}

