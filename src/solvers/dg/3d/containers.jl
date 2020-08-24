
# Container data structure (structure-of-arrays style) for DG elements
struct ElementContainer3D{V, N} <: AbstractContainer
  u::Array{Float64, 5}                   # [variables, i, j, k, elements]
  u_t::Array{Float64, 5}                 # [variables, i, j, k, elements]
  u_tmp2::Array{Float64, 5}              # [variables, i, j, k, elements]
  u_tmp3::Array{Float64, 5}              # [variables, i, j, k, elements]
  inverse_jacobian::Vector{Float64}      # [elements]
  node_coordinates::Array{Float64, 5}    # [orientation, i, j, k, elements]
  surface_ids::Matrix{Int}               # [direction, elements]
  surface_flux_values::Array{Float64, 5} # [variables, i, j, direction, elements]
  cell_ids::Vector{Int}                  # [elements]
end


function ElementContainer3D{V, N}(capacity::Integer) where {V, N} # V = no. variables, N = polydeg
  # Initialize fields with defaults
  n_nodes = N + 1
  u = fill(NaN, V, n_nodes, n_nodes, n_nodes, capacity)
  u_t = fill(NaN, V, n_nodes, n_nodes, n_nodes, capacity)
  # u_rungakutta is initialized to non-NaN since it is used directly
  u_tmp2 = fill(0.0, V, n_nodes, n_nodes, n_nodes, capacity)
  u_tmp3 = fill(0.0, V, n_nodes, n_nodes, n_nodes, capacity)
  inverse_jacobian = fill(NaN, capacity)
  node_coordinates = fill(NaN, 3, n_nodes, n_nodes, n_nodes, capacity) # 3 = ndims
  surface_ids = fill(typemin(Int), 2 * 3, capacity) # 3 = ndims
  surface_flux_values = fill(NaN, V, n_nodes, n_nodes, 2 * 3, capacity) # 3 = ndims
  cell_ids = fill(typemin(Int), capacity)

  elements = ElementContainer3D{V, N}(u, u_t, u_tmp2, u_tmp3, inverse_jacobian, node_coordinates,
                                    surface_ids, surface_flux_values, cell_ids)

  return elements
end


# Return number of elements
nelements(elements::ElementContainer3D) = length(elements.cell_ids)


# Container data structure (structure-of-arrays style) for DG interfaces
struct InterfaceContainer3D{V, N} <: AbstractContainer
  u::Array{Float64, 5}      # [leftright, variables, i, j, interfaces]
  neighbor_ids::Matrix{Int} # [leftright, interfaces]
  orientations::Vector{Int} # [interfaces]
end


function InterfaceContainer3D{V, N}(capacity::Integer) where {V, N}
  # Initialize fields with defaults
  n_nodes = N + 1
  u = fill(NaN, 2, V, n_nodes, n_nodes, capacity)
  neighbor_ids = fill(typemin(Int), 2, capacity)
  orientations = fill(typemin(Int), capacity)

  interfaces = InterfaceContainer3D{V, N}(u, neighbor_ids, orientations)

  return interfaces
end


# Return number of interfaces
ninterfaces(interfaces::InterfaceContainer3D) = length(interfaces.orientations)


# Container data structure (structure-of-arrays style) for DG boundaries
struct BoundaryContainer3D{V, N} <: AbstractContainer
  u::Array{Float64, 5}                # [leftright, variables, i, j, boundaries]
  neighbor_ids::Vector{Int}           # [boundaries]
  orientations::Vector{Int}           # [boundaries]
  neighbor_sides::Vector{Int}         # [boundaries]
  node_coordinates::Array{Float64, 4} # [orientation, i, j, elements]
end


function BoundaryContainer3D{V, N}(capacity::Integer) where {V, N}
  # Initialize fields with defaults
  n_nodes = N + 1
  u = fill(NaN, 2, V, n_nodes, n_nodes, capacity)
  neighbor_ids = fill(typemin(Int), capacity)
  orientations = fill(typemin(Int), capacity)
  neighbor_sides = fill(typemin(Int), capacity)
  node_coordinates = fill(NaN, 3, n_nodes, n_nodes, capacity) # 3 = ndims

  boundaries = BoundaryContainer3D{V, N}(u, neighbor_ids, orientations, neighbor_sides,
                                       node_coordinates)

  return boundaries
end


# Return number of boundaries
nboundaries(boundaries::BoundaryContainer3D) = length(boundaries.orientations)


# Container data structure (structure-of-arrays style) for DG L2 mortars
# Positions/directions for large_sides = 1, orientations = 1:
#           |    |
# upper = 2 |    |
#           |    |
#                | 3
#           |    |
# lower = 1 |    |
#           |    |
struct L2MortarContainer3D{V, N} <: AbstractContainer
  u_upper::Array{Float64, 4} # [leftright, variables, i, mortars]
  u_lower::Array{Float64, 4} # [leftright, variables, i, mortars]
  neighbor_ids::Matrix{Int}  # [position, mortars]
  # Large sides: left -> 1, right -> 2
  large_sides::Vector{Int}   # [mortars]
  orientations::Vector{Int}  # [mortars]
end


function L2MortarContainer3D{V, N}(capacity::Integer) where {V, N}
  # Initialize fields with defaults
  n_nodes = N + 1
  u_upper = fill(NaN, 2, V, n_nodes, capacity)
  u_lower = fill(NaN, 2, V, n_nodes, capacity)
  neighbor_ids = fill(typemin(Int), 3, capacity)
  large_sides = fill(typemin(Int), capacity)
  orientations = fill(typemin(Int), capacity)

  l2mortars = L2MortarContainer3D{V, N}(u_upper, u_lower, neighbor_ids, large_sides, orientations)

  return l2mortars
end


# Return number of L2 mortars
nmortars(l2mortars::L2MortarContainer3D) = length(l2mortars.orientations)


# Allow printing container contents
function Base.show(io::IO, c::L2MortarContainer3D{V, N}) where {V, N}
  println(io, '*'^20)
  for idx in CartesianIndices(c.u_upper)
    println(io, "c.u_upper[$idx] = $(c.u_upper[idx])")
  end
  for idx in CartesianIndices(c.u_lower)
    println(io, "c.u_lower[$idx] = $(c.u_lower[idx])")
  end
  println(io, "transpose(c.neighbor_ids) = $(transpose(c.neighbor_ids))")
  println(io, "c.large_sides = $(c.large_sides)")
  println(io, "c.orientations = $(c.orientations)")
  println(io, '*'^20)
end


# Container data structure (structure-of-arrays style) for DG Ec mortars
# Positions/directions for large_sides = 1, orientations = 1:
#           |    |
# upper = 2 |    |
#           |    |
#                | 3
#           |    |
# lower = 1 |    |
#           |    |
struct EcMortarContainer3D{V, N} <: AbstractContainer
  u_upper::Array{Float64, 3} # [variables, i, mortars]
  u_lower::Array{Float64, 3} # [variables, i, mortars]
  u_large::Array{Float64, 3} # [variables, i, mortars]
  neighbor_ids::Matrix{Int}  # [position, mortars]
  # Large sides: left -> 1, right -> 2
  large_sides::Vector{Int}   # [mortars]
  orientations::Vector{Int}  # [mortars]
end


function EcMortarContainer3D{V, N}(capacity::Integer) where {V, N}
  # Initialize fields with defaults
  n_nodes = N + 1
  u_upper = fill(NaN, V, n_nodes, capacity)
  u_lower = fill(NaN, V, n_nodes, capacity)
  u_large = fill(NaN, V, n_nodes, capacity)
  neighbor_ids = fill(typemin(Int), 3, capacity)
  large_sides = fill(typemin(Int), capacity)
  orientations = fill(typemin(Int), capacity)

  ecmortars = EcMortarContainer3D{V, N}(u_upper, u_lower, u_large, neighbor_ids,
                                      large_sides, orientations)

  return ecmortars
end


# Return number of EC mortars
nmortars(ecmortars::EcMortarContainer3D) = length(ecmortars.orientations)
