// Asset-authoring helper for CHAR-BASE-B Meshy GLBs.
// Build: clang++ -std=c++17 tools/smooth_meshy_b_normals.cpp \
//          $(pkg-config --cflags --libs assimp) -o /tmp/smooth_meshy_b_normals
// Run:   /tmp/smooth_meshy_b_normals input.glb output.glb

#include <assimp/Exporter.hpp>
#include <assimp/Importer.hpp>
#include <assimp/postprocess.h>
#include <assimp/scene.h>

#include <cmath>
#include <iostream>

namespace {

void repair_central_back_normals(aiScene *scene) {
    // Meshy's single-view mouth cavity leaves a small normal seam on the unseen
    // rear pole. Reproject only that shading patch onto the body's ellipsoid;
    // positions, topology, silhouette, and the authored front face stay untouched.
    constexpr float patch_radius = 0.13F;
    constexpr float back_limit = -0.30F;
    constexpr float radius_x = 0.45F;
    constexpr float radius_y = 0.48F;
    constexpr float radius_z = 0.43F;

    for (unsigned mesh_index = 0; mesh_index < scene->mNumMeshes; ++mesh_index) {
        aiMesh *mesh = scene->mMeshes[mesh_index];
        if (mesh == nullptr || !mesh->HasNormals()) {
            continue;
        }
        for (unsigned vertex_index = 0; vertex_index < mesh->mNumVertices; ++vertex_index) {
            const aiVector3D &position = mesh->mVertices[vertex_index];
            const float radial = std::hypot(position.x, position.y);
            if (position.z >= back_limit || radial >= patch_radius) {
                continue;
            }
            aiVector3D normal(position.x / (radius_x * radius_x),
                              position.y / (radius_y * radius_y),
                              position.z / (radius_z * radius_z));
            normal.Normalize();
            mesh->mNormals[vertex_index] = normal;
        }
    }
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3) {
        std::cerr << "usage: smooth_meshy_b_normals <input.glb> <output.glb>\n";
        return 2;
    }

    Assimp::Importer importer;
    const unsigned flags = aiProcess_Triangulate |
                           aiProcess_JoinIdenticalVertices |
                           aiProcess_GenSmoothNormals |
                           aiProcess_CalcTangentSpace |
                           aiProcess_ImproveCacheLocality |
                           aiProcess_ValidateDataStructure;
    aiScene *scene = const_cast<aiScene *>(importer.ReadFile(argv[1], flags));
    if (scene == nullptr) {
        std::cerr << importer.GetErrorString() << "\n";
        return 3;
    }

    repair_central_back_normals(scene);

    Assimp::Exporter exporter;
    const aiReturn result = exporter.Export(scene, "glb2", argv[2]);
    if (result != AI_SUCCESS) {
        std::cerr << exporter.GetErrorString() << "\n";
        return 4;
    }
    return 0;
}
