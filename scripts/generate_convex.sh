#!/bin/bash

exit_if_error()
{
  if [ $? -ne 0 ]
  then
    echo "-- FATAL ERROR: $1"
    exit 1
  fi
}

export robot_name="ur10"
export robot_desc_name="ur_description"
export target_pkg_name="mc_${robot_name}_description"
org_path=$(rospack find ${robot_desc_name}) || exit_if_error "Failed to find ${robot_desc_name} package"
export tmp_path="/tmp/generate_${target_pkg_name}"
export gen_path="/tmp/${target_pkg_name}"
export sample_points=2000                

echo "Running generate_convex.sh script from directory `pwd`"

function generate_convexes()
{
    mapfile -t daefiles < <(find "${org_path}/meshes/${robot_name}/visual/" -type f -name "*.dae")
    mapfile -t stlfiles < <(find "${org_path}/meshes/${robot_name}/collision/" -type f -name "*.stl")
    echo "Found files: ${daefiles[@]} ${stlfiles[@]}"
    for mesh in "${daefiles[@]}" "${stlfiles[@]}"; do 
        mesh_name=$(basename -- "${mesh}")
        mesh_name="${mesh_name%.*}"
        echo "-- Generating convex hull for ${mesh}"
        mkdir -p "${tmp_path}/qc/${robot_name}"
        mkdir -p "${gen_path}/convex/${robot_name}"
        gen_cloud="${tmp_path}/qc/${robot_name}/${mesh_name}.qc"
        gen_convex="${gen_path}/convex/${robot_name}/${mesh_name}-ch.txt"
        mesh_sampling "${mesh}" "${gen_cloud}" --type xyz --samples ${sample_points}
        exit_if_error "Failed to sample pointcloud from mesh ${mesh} to ${gen_cloud}"
        if [ ! -s "${gen_cloud}" ]; then
            echo "-- ERROR: ${gen_cloud} is empty or does not exist!"
            exit 1
        fi
        qconvex TI "${gen_cloud}" TO "${gen_convex}" Qt o f
        exit_if_error "Failed to compute convex hull pointcloud from ${gen_cloud} to ${gen_convex}"
    done
}

generate_convexes
echo "Successfully generated convex hulls from ${robot_desc_name} package in ${gen_path}"
