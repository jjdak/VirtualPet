#ifndef PHOEBE_LIVE2D_RUNTIME_H
#define PHOEBE_LIVE2D_RUNTIME_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t PLDCubismCoreVersion(void);
bool PLDRenderingBridgeReady(void);

enum PLDLogicalParameterMask {
    PLDLogicalParameterAngleX = 1u << 0,
    PLDLogicalParameterAngleY = 1u << 1,
    PLDLogicalParameterAngleZ = 1u << 2,
    PLDLogicalParameterBodyAngleX = 1u << 3,
    PLDLogicalParameterEyeSmile = 1u << 4,
    PLDLogicalParameterMouthOpenY = 1u << 5,
    PLDLogicalParameterBreath = 1u << 6,
    PLDLogicalParameterHairSwing = 1u << 7,
    PLDLogicalParameterHatSwing = 1u << 8
};

typedef struct PLDModelProbeResult {
    uint32_t mocVersion;
    uint32_t parameterCount;
    uint32_t drawableCount;
    uint32_t logicalParameterMask;
} PLDModelProbeResult;

bool PLDProbeMoc(const void* mocBytes, uint32_t mocSize, PLDModelProbeResult* result);

typedef struct PLDModel3ProbeResult {
    PLDModelProbeResult moc;
    uint32_t textureCount;
    bool hasMoc;
    bool hasTexture;
    bool hasDisplayInfo;
} PLDModel3ProbeResult;

// Resolves the model3 file's relative references, checks the referenced files,
// and asks Cubism Core to load the referenced moc3. This is a resource gate,
// not a rendering bridge; PLDRenderingBridgeReady remains false until the
// Metal host is integrated.
bool PLDProbeModel3File(const char* model3Path, PLDModel3ProbeResult* result);

typedef struct PLDModel3Handle PLDModel3Handle;

typedef struct PLDDrawableSnapshot {
    const float* vertexPositions; // x/y pairs; owned by PLDModel3Handle
    const float* vertexUvs;       // u/v pairs; owned by PLDModel3Handle
    const uint16_t* indices;
    const int* masks;
    uint32_t vertexCount;
    uint32_t indexCount;
    uint32_t maskCount;
    uint32_t dynamicFlags;
    int textureIndex;
    int drawOrder;
    int blendMode;
    float opacity;
} PLDDrawableSnapshot;

// Creates a persistent Core model from a verified model3 file. Pointers in
// PLDDrawableSnapshot remain valid until PLDDestroyModel3 or the next update.
PLDModel3Handle* PLDCreateModel3(const char* model3Path);
void PLDDestroyModel3(PLDModel3Handle* handle);
bool PLDModel3SetParameter(PLDModel3Handle* handle, const char* parameterId, float value);
bool PLDModel3Update(PLDModel3Handle* handle);
uint32_t PLDModel3DrawableCount(const PLDModel3Handle* handle);
bool PLDModel3GetDrawableSnapshot(const PLDModel3Handle* handle,
                                  uint32_t drawableIndex,
                                  PLDDrawableSnapshot* snapshot);

#ifdef __cplusplus
}
#endif

#endif
