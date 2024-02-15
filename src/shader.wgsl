@group(0) @binding(0) var<uniform> grid: vec2f;
@group(0) @binding(1) var<storage> cellState: array<u32>;
@group(0) @binding(1) var<storage> cellStateIn: array<u32>;
@group(0) @binding(2) var<storage, read_write> cellStateOut: array<u32>;

// Vertex shader
struct VertexInput {
    @location(0) position: vec2<f32>,
    @builtin(instance_index) instance: u32,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) color: vec2<f32>,
};

@vertex
fn vs_main(
    input: VertexInput
) -> VertexOutput {
    var output: VertexOutput;

    let i = f32(input.instance);
    let cell = vec2f(i % grid.x, floor(i/ grid.x));
    let state = f32(cellState[input.instance]);

    let cellOffset = cell / grid * 2.0;
    let grid_position = (input.position * state + 1.0 ) / grid - 1.0 + cellOffset;

    output.clip_position = vec4<f32>(grid_position, 0.0, 1.0);
    output.color = cell;
    return output;
}

// Fragment shader

@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
    let c = input.color / grid;

    return vec4<f32>(c, 1.0 - c.x, 1.0);
}


fn cellIndex(cell: vec2u) -> u32 {
  return cell.y * u32(grid.x) + cell.x;
}

@compute @workgroup_size(8, 8)
fn computeMain(@builtin(global_invocation_id) cell: vec3u) {
  // New lines. Flip the cell state every step.
  if (cellStateIn[cellIndex(cell.xy)] == u32(1)) {
    cellStateOut[cellIndex(cell.xy)] = u32(0);
  } else {
    cellStateOut[cellIndex(cell.xy)] = u32(1);
  }
}
