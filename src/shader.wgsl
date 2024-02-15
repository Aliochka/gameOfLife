@group(0) @binding(0) var<uniform> grid: vec2f;
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
    let cell = vec2f(i % grid.x, floor(i / grid.x));
    let state = f32(cellStateIn[input.instance]);

    let cellOffset = cell / grid * 2.0;
    let grid_position = (input.position * state + 1.0 ) / grid - 1.0 + cellOffset;

    output.clip_position = vec4<f32>(grid_position, 0.0, 1.0);
    output.color = cell;
    return output;
}

// Fragment shader
@fragment
fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
    let c = input.color / grid / 2.0;

    return vec4<f32>(c, 1.0 - c.x, 1.0);
}

fn cellIndex(cell: vec2u) -> u32 {
  return (cell.y % u32(grid.y)) * u32(grid.x) +
         (cell.x % u32(grid.x));
}


fn cellActive(x: u32, y: u32) -> u32 {
  return cellStateIn[cellIndex(vec2(x, y))];
}

@compute @workgroup_size(8, 8)
fn compute_main(@builtin(global_invocation_id) cell: vec3u) {

  let activeNeighbors = cellActive(cell.x + 1u, cell.y + 1u)+
                        cellActive(cell.x + 1u, cell.y) +
                        cellActive(cell.x + 1u, cell.y - 1u) +
                        cellActive(cell.x, cell.y - 1u) +
                        cellActive(cell.x - 1u, cell.y - 1u) +
                        cellActive(cell.x - 1u, cell.y) +
                        cellActive(cell.x - 1u, cell.y + 1u) +
                        cellActive(cell.x, cell.y + 1u);


  let i = cellIndex(cell.xy);

  // Conway's game of life rules:
  switch activeNeighbors {
    case 2u: { // Active cells with 2 neighbors stay active.
      cellStateOut[i] = cellStateIn[i];
    }
    case 3u: { // Cells with 3 neighbors become or stay active.
      cellStateOut[i] = 1u;
    }
    default: { // Cells with < 2 or > 3 neighbors become inactive.
      cellStateOut[i] = 0u;
    }
  }
}
