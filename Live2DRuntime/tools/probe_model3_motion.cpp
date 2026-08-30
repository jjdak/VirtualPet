#include "PhoebeLive2DRuntime.h"

#include <cstring>
#include <cstdint>
#include <iomanip>
#include <iostream>

namespace {

uint64_t hashModel(const PLDModel3Handle* handle)
{
    uint64_t hash = 1469598103934665603ull;
    const uint32_t drawableCount = PLDModel3DrawableCount(handle);
    for (uint32_t drawableIndex = 0; drawableIndex < drawableCount; ++drawableIndex) {
        PLDDrawableSnapshot drawable{};
        if (!PLDModel3GetDrawableSnapshot(handle, drawableIndex, &drawable)) {
            return 0;
        }
        const float* values = drawable.vertexPositions;
        const uint32_t valueCount = drawable.vertexCount * 2;
        for (uint32_t valueIndex = 0; valueIndex < valueCount; ++valueIndex) {
            const unsigned char* bytes = reinterpret_cast<const unsigned char*>(&values[valueIndex]);
            for (size_t byteIndex = 0; byteIndex < sizeof(float); ++byteIndex) {
                hash ^= bytes[byteIndex];
                hash *= 1099511628211ull;
            }
        }
    }
    return hash;
}

} // namespace

int main(int argc, char** argv)
{
    if (argc != 2) {
        std::cerr << "usage: probe_model3_motion <model3.json>\n";
        return 64;
    }

    const struct {
        const char* id;
        float value;
    } candidates[] = {
        {"ParamAngleX", 30.0f},
        {"ParamAngleY", 30.0f},
        {"ParamAngleZ", 30.0f},
        {"ParamBodyAngleX", 30.0f},
        {"ParamEyeLSmile", 1.0f},
        {"ParamEyeRSmile", 1.0f},
        {"ParamMouthOpenY", 1.0f},
        {"ParamBreath", 1.0f},
        {"ParamHairFront", 30.0f},
        {"ParamHairSide", 30.0f},
        {"ParamHairBack", 30.0f},
        {"ParamHatSwing", 30.0f},
    };

    bool anyChanged = false;
    bool mouthChanged = false;
    for (const auto& candidate : candidates) {
        PLDModel3Handle* handle = PLDCreateModel3(argv[1]);
        if (!handle) {
            std::cerr << "cannot create persistent model3 handle: " << argv[1] << '\n';
            return 1;
        }
        const uint64_t neutralHash = hashModel(handle);
        const bool parameterFound = PLDModel3SetParameter(handle, candidate.id, candidate.value);
        const bool updated = PLDModel3Update(handle);
        const uint64_t changedHash = hashModel(handle);
        PLDDestroyModel3(handle);

        if (!parameterFound || !updated || neutralHash == 0 || changedHash == 0) {
            std::cerr << candidate.id << ": probe could not complete\n";
            return 1;
        }
        const bool changed = neutralHash != changedHash;
        anyChanged = anyChanged || changed;
        mouthChanged = mouthChanged ||
            (std::strcmp(candidate.id, "ParamMouthOpenY") == 0 && changed);
        std::cout << candidate.id << " changed=" << (changed ? "true" : "false")
                  << " neutral=0x" << std::hex << neutralHash
                  << " value=0x" << changedHash << std::dec << '\n';
    }

    if (!anyChanged) {
        std::cerr << "no tested parameter changed Core drawable vertices\n";
        return 2;
    }
    if (!mouthChanged) {
        std::cerr << "ParamMouthOpenY did not change Core drawable vertices; keep the visual gate open\n";
        return 3;
    }
    std::cout << "ParamMouthOpenY changes Core drawable vertices; the parameter driver is live.\n";
    return 0;
}
