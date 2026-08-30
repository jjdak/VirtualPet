#include "PhoebeLive2DRuntime.h"

#include "Live2DCubismCore.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iterator>
#include <limits>
#include <string>

namespace {

bool readFile(const std::string& path, std::string& contents)
{
    std::ifstream input(path, std::ios::binary);
    if (!input) {
        return false;
    }
    contents.assign(std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>());
    return !input.bad();
}

bool isSafeRelativeReference(const std::string& reference)
{
    if (reference.empty() || reference.front() == '/' || reference.front() == '\\' ||
        reference.find(':') != std::string::npos) {
        return false;
    }

    size_t componentStart = 0;
    while (componentStart <= reference.size()) {
        const size_t separator = reference.find_first_of("/\\", componentStart);
        const size_t componentLength = separator == std::string::npos
            ? reference.size() - componentStart
            : separator - componentStart;
        if (reference.substr(componentStart, componentLength) == "..") {
            return false;
        }
        if (separator == std::string::npos) {
            break;
        }
        componentStart = separator + 1;
    }
    return true;
}

std::string directoryName(const std::string& path)
{
    const size_t separator = path.find_last_of("/\\");
    return separator == std::string::npos ? std::string() : path.substr(0, separator);
}

std::string joinPath(const std::string& directory, const std::string& reference)
{
    return directory.empty() ? reference : directory + "/" + reference;
}

bool findJsonString(const std::string& json,
                    const std::string& key,
                    size_t searchStart,
                    std::string& value,
                    size_t* valueEnd)
{
    const std::string quotedKey = "\"" + key + "\"";
    const size_t keyStart = json.find(quotedKey, searchStart);
    if (keyStart == std::string::npos) {
        return false;
    }
    const size_t colon = json.find(':', keyStart + quotedKey.size());
    if (colon == std::string::npos) {
        return false;
    }
    const size_t openingQuote = json.find('"', colon + 1);
    if (openingQuote == std::string::npos) {
        return false;
    }

    value.clear();
    bool escaped = false;
    for (size_t index = openingQuote + 1; index < json.size(); ++index) {
        const char character = json[index];
        if (escaped) {
            switch (character) {
            case '"': value.push_back('"'); break;
            case '\\': value.push_back('\\'); break;
            case '/': value.push_back('/'); break;
            case 'b': value.push_back('\b'); break;
            case 'f': value.push_back('\f'); break;
            case 'n': value.push_back('\n'); break;
            case 'r': value.push_back('\r'); break;
            case 't': value.push_back('\t'); break;
            default: return false;
            }
            escaped = false;
            continue;
        }
        if (character == '\\') {
            escaped = true;
        } else if (character == '"') {
            if (valueEnd) {
                *valueEnd = index + 1;
            }
            return true;
        } else {
            value.push_back(character);
        }
    }
    return false;
}

bool findFirstArrayString(const std::string& json,
                          const std::string& key,
                          std::string& value)
{
    const std::string quotedKey = "\"" + key + "\"";
    const size_t keyStart = json.find(quotedKey);
    if (keyStart == std::string::npos) {
        return false;
    }
    const size_t colon = json.find(':', keyStart + quotedKey.size());
    const size_t openingBracket = colon == std::string::npos ? std::string::npos : json.find('[', colon + 1);
    if (openingBracket == std::string::npos) {
        return false;
    }

    const size_t openingQuote = json.find('"', openingBracket + 1);
    if (openingQuote == std::string::npos) {
        return false;
    }
    value.clear();
    bool escaped = false;
    for (size_t index = openingQuote + 1; index < json.size(); ++index) {
        const char character = json[index];
        if (escaped) {
            switch (character) {
            case '"': value.push_back('"'); break;
            case '\\': value.push_back('\\'); break;
            case '/': value.push_back('/'); break;
            case 'b': value.push_back('\b'); break;
            case 'f': value.push_back('\f'); break;
            case 'n': value.push_back('\n'); break;
            case 'r': value.push_back('\r'); break;
            case 't': value.push_back('\t'); break;
            default: return false;
            }
            escaped = false;
        } else if (character == '\\') {
            escaped = true;
        } else if (character == '"') {
            return true;
        } else {
            value.push_back(character);
        }
    }
    return false;
}

uint32_t countArrayStrings(const std::string& json, const std::string& key)
{
    const std::string quotedKey = "\"" + key + "\"";
    const size_t keyStart = json.find(quotedKey);
    if (keyStart == std::string::npos) {
        return 0;
    }
    const size_t colon = json.find(':', keyStart + quotedKey.size());
    const size_t openingBracket = colon == std::string::npos ? std::string::npos : json.find('[', colon + 1);
    if (openingBracket == std::string::npos) {
        return 0;
    }
    const size_t closingBracket = json.find(']', openingBracket + 1);
    if (closingBracket == std::string::npos) {
        return 0;
    }

    uint32_t count = 0;
    bool escaped = false;
    bool inString = false;
    for (size_t index = openingBracket + 1; index < closingBracket; ++index) {
        const char character = json[index];
        if (escaped) {
            escaped = false;
        } else if (character == '\\' && inString) {
            escaped = true;
        } else if (character == '"') {
            if (!inString) {
                ++count;
            }
            inString = !inString;
        }
    }
    return count;
}

bool resolveMocPath(const std::string& model3FilePath, std::string& mocPath)
{
    std::string model3JSON;
    if (!readFile(model3FilePath, model3JSON)) {
        return false;
    }
    std::string mocReference;
    if (!findJsonString(model3JSON, "Moc", 0, mocReference, nullptr) ||
        !isSafeRelativeReference(mocReference)) {
        return false;
    }
    mocPath = joinPath(directoryName(model3FilePath), mocReference);
    return true;
}

} // namespace

struct PLDModel3Handle {
    void* mocMemory = nullptr;
    csmMoc* moc = nullptr;
    void* modelMemory = nullptr;
    csmModel* model = nullptr;
};

namespace {

bool hasParameter(const char* const* ids, int count, const char* expected)
{
    if (!ids || !expected || count <= 0) {
        return false;
    }

    for (int index = 0; index < count; ++index) {
        if (ids[index] && std::strcmp(ids[index], expected) == 0) {
            return true;
        }
    }
    return false;
}

void setBitIfPresent(uint32_t& mask,
                    const char* const* ids,
                    int count,
                    const char* expected,
                    uint32_t bit)
{
    if (hasParameter(ids, count, expected)) {
        mask |= bit;
    }
}

bool allocateAligned(void** address, size_t alignment, size_t size)
{
    if (!address || size == 0) {
        return false;
    }
    *address = nullptr;
    return posix_memalign(address, alignment, size) == 0;
}

void releaseModel(PLDModel3Handle* handle)
{
    if (!handle) {
        return;
    }
    std::free(handle->modelMemory);
    std::free(handle->mocMemory);
    handle->modelMemory = nullptr;
    handle->mocMemory = nullptr;
    handle->model = nullptr;
    handle->moc = nullptr;
}

} // namespace

uint32_t PLDCubismCoreVersion(void)
{
    return static_cast<uint32_t>(csmGetVersion());
}

bool PLDRenderingBridgeReady(void)
{
    // Stage 0 only proves the private Cubism Core can be imported and linked.
    // The Metal model host will flip this after it can load phoebe.model3.json.
    return false;
}

bool PLDProbeMoc(const void* mocBytes, uint32_t mocSize, PLDModelProbeResult* result)
{
    if (result) {
        std::memset(result, 0, sizeof(*result));
    }
    if (!mocBytes || mocSize == 0 || !result) {
        return false;
    }

    void* mocMemory = nullptr;
    if (!allocateAligned(&mocMemory, csmAlignofMoc, mocSize)) {
        return false;
    }
    std::memcpy(mocMemory, mocBytes, mocSize);

    result->mocVersion = static_cast<uint32_t>(csmGetMocVersion(mocMemory, mocSize));
    if (!csmHasMocConsistency(mocMemory, mocSize)) {
        std::free(mocMemory);
        return false;
    }

    csmMoc* moc = csmReviveMocInPlace(mocMemory, mocSize);
    if (!moc) {
        std::free(mocMemory);
        return false;
    }

    const unsigned int modelSize = csmGetSizeofModel(moc);
    void* modelMemory = nullptr;
    if (!allocateAligned(&modelMemory, csmAlignofModel, modelSize)) {
        std::free(mocMemory);
        return false;
    }

    csmModel* model = csmInitializeModelInPlace(moc, modelMemory, modelSize);
    if (!model) {
        std::free(modelMemory);
        std::free(mocMemory);
        return false;
    }

    const int parameterCount = csmGetParameterCount(model);
    result->parameterCount = parameterCount > 0 ? static_cast<uint32_t>(parameterCount) : 0;
    const int drawableCount = csmGetDrawableCount(model);
    result->drawableCount = drawableCount > 0 ? static_cast<uint32_t>(drawableCount) : 0;

    const char** parameterIds = csmGetParameterIds(model);
    setBitIfPresent(result->logicalParameterMask, parameterIds, parameterCount,
                    "ParamAngleX", PLDLogicalParameterAngleX);
    setBitIfPresent(result->logicalParameterMask, parameterIds, parameterCount,
                    "ParamAngleY", PLDLogicalParameterAngleY);
    setBitIfPresent(result->logicalParameterMask, parameterIds, parameterCount,
                    "ParamAngleZ", PLDLogicalParameterAngleZ);
    setBitIfPresent(result->logicalParameterMask, parameterIds, parameterCount,
                    "ParamBodyAngleX", PLDLogicalParameterBodyAngleX);
    if (hasParameter(parameterIds, parameterCount, "ParamEyeSmile") ||
        (hasParameter(parameterIds, parameterCount, "ParamEyeLSmile") &&
         hasParameter(parameterIds, parameterCount, "ParamEyeRSmile"))) {
        result->logicalParameterMask |= PLDLogicalParameterEyeSmile;
    }
    setBitIfPresent(result->logicalParameterMask, parameterIds, parameterCount,
                    "ParamMouthOpenY", PLDLogicalParameterMouthOpenY);
    setBitIfPresent(result->logicalParameterMask, parameterIds, parameterCount,
                    "ParamBreath", PLDLogicalParameterBreath);
    if (hasParameter(parameterIds, parameterCount, "ParamHairSwing") ||
        (hasParameter(parameterIds, parameterCount, "ParamHairFront") &&
         hasParameter(parameterIds, parameterCount, "ParamHairSide") &&
         hasParameter(parameterIds, parameterCount, "ParamHairBack"))) {
        result->logicalParameterMask |= PLDLogicalParameterHairSwing;
    }
    setBitIfPresent(result->logicalParameterMask, parameterIds, parameterCount,
                    "ParamHatSwing", PLDLogicalParameterHatSwing);

    std::free(modelMemory);
    std::free(mocMemory);
    return true;
}

bool PLDProbeModel3File(const char* model3Path, PLDModel3ProbeResult* result)
{
    if (result) {
        std::memset(result, 0, sizeof(*result));
    }
    if (!model3Path || model3Path[0] == '\0' || !result) {
        return false;
    }

    const std::string model3FilePath(model3Path);
    std::string model3JSON;
    if (!readFile(model3FilePath, model3JSON)) {
        return false;
    }

    std::string mocReference;
    if (!findJsonString(model3JSON, "Moc", 0, mocReference, nullptr) ||
        !isSafeRelativeReference(mocReference)) {
        return false;
    }

    std::string textureReference;
    result->textureCount = countArrayStrings(model3JSON, "Textures");
    if (result->textureCount == 0 ||
        !findFirstArrayString(model3JSON, "Textures", textureReference) ||
        !isSafeRelativeReference(textureReference)) {
        return false;
    }

    const std::string modelDirectory = directoryName(model3FilePath);
    const std::string mocPath = joinPath(modelDirectory, mocReference);
    const std::string texturePath = joinPath(modelDirectory, textureReference);
    std::ifstream textureFile(texturePath, std::ios::binary);
    if (!textureFile) {
        return false;
    }
    result->hasTexture = true;

    std::string displayInfoReference;
    if (findJsonString(model3JSON, "DisplayInfo", 0, displayInfoReference, nullptr)) {
        if (!isSafeRelativeReference(displayInfoReference)) {
            return false;
        }
        std::ifstream displayInfoFile(
            joinPath(modelDirectory, displayInfoReference), std::ios::binary);
        if (!displayInfoFile) {
            return false;
        }
        result->hasDisplayInfo = true;
    }

    std::string mocBytes;
    if (!readFile(mocPath, mocBytes) || mocBytes.empty() ||
        mocBytes.size() > std::numeric_limits<uint32_t>::max()) {
        return false;
    }
    result->hasMoc = PLDProbeMoc(
        mocBytes.data(), static_cast<uint32_t>(mocBytes.size()), &result->moc);
    return result->hasMoc && result->hasTexture;
}

PLDModel3Handle* PLDCreateModel3(const char* model3Path)
{
    if (!model3Path || model3Path[0] == '\0') {
        return nullptr;
    }

    PLDModel3ProbeResult probe{};
    if (!PLDProbeModel3File(model3Path, &probe)) {
        return nullptr;
    }

    std::string mocPath;
    std::string mocBytes;
    if (!resolveMocPath(model3Path, mocPath) || !readFile(mocPath, mocBytes) ||
        mocBytes.empty() || mocBytes.size() > std::numeric_limits<uint32_t>::max()) {
        return nullptr;
    }

    PLDModel3Handle* handle = new PLDModel3Handle();
    if (!allocateAligned(&handle->mocMemory, csmAlignofMoc, mocBytes.size())) {
        delete handle;
        return nullptr;
    }
    std::memcpy(handle->mocMemory, mocBytes.data(), mocBytes.size());
    if (!csmHasMocConsistency(handle->mocMemory, mocBytes.size())) {
        releaseModel(handle);
        delete handle;
        return nullptr;
    }
    handle->moc = csmReviveMocInPlace(handle->mocMemory, mocBytes.size());
    if (!handle->moc) {
        releaseModel(handle);
        delete handle;
        return nullptr;
    }

    const unsigned int modelSize = csmGetSizeofModel(handle->moc);
    if (!allocateAligned(&handle->modelMemory, csmAlignofModel, modelSize)) {
        releaseModel(handle);
        delete handle;
        return nullptr;
    }
    handle->model = csmInitializeModelInPlace(handle->moc, handle->modelMemory, modelSize);
    if (!handle->model) {
        releaseModel(handle);
        delete handle;
        return nullptr;
    }
    csmUpdateModel(handle->model);
    return handle;
}

void PLDDestroyModel3(PLDModel3Handle* handle)
{
    if (!handle) {
        return;
    }
    releaseModel(handle);
    delete handle;
}

bool PLDModel3SetParameter(PLDModel3Handle* handle, const char* parameterId, float value)
{
    if (!handle || !handle->model || !parameterId) {
        return false;
    }
    const int parameterCount = csmGetParameterCount(handle->model);
    const char** parameterIds = csmGetParameterIds(handle->model);
    float* values = csmGetParameterValues(handle->model);
    const float* minimumValues = csmGetParameterMinimumValues(handle->model);
    const float* maximumValues = csmGetParameterMaximumValues(handle->model);
    if (parameterCount <= 0 || !parameterIds || !values || !minimumValues || !maximumValues) {
        return false;
    }
    for (int index = 0; index < parameterCount; ++index) {
        if (parameterIds[index] && std::strcmp(parameterIds[index], parameterId) == 0) {
            values[index] = std::max(minimumValues[index],
                                     std::min(maximumValues[index], value));
            return true;
        }
    }
    return false;
}

bool PLDModel3Update(PLDModel3Handle* handle)
{
    if (!handle || !handle->model) {
        return false;
    }
    csmUpdateModel(handle->model);
    return true;
}

uint32_t PLDModel3DrawableCount(const PLDModel3Handle* handle)
{
    if (!handle || !handle->model) {
        return 0;
    }
    const int count = csmGetDrawableCount(handle->model);
    return count > 0 ? static_cast<uint32_t>(count) : 0;
}

bool PLDModel3GetDrawableSnapshot(const PLDModel3Handle* handle,
                                  uint32_t drawableIndex,
                                  PLDDrawableSnapshot* snapshot)
{
    if (snapshot) {
        std::memset(snapshot, 0, sizeof(*snapshot));
    }
    if (!handle || !handle->model || !snapshot ||
        drawableIndex >= PLDModel3DrawableCount(handle)) {
        return false;
    }

    const csmModel* model = handle->model;
    const int index = static_cast<int>(drawableIndex);
    const int* vertexCounts = csmGetDrawableVertexCounts(model);
    const csmVector2** positions = csmGetDrawableVertexPositions(model);
    const csmVector2** uvs = csmGetDrawableVertexUvs(model);
    const int* indexCounts = csmGetDrawableIndexCounts(model);
    const unsigned short** indices = csmGetDrawableIndices(model);
    const int* maskCounts = csmGetDrawableMaskCounts(model);
    const int** masks = csmGetDrawableMasks(model);
    const csmFlags* dynamicFlags = csmGetDrawableDynamicFlags(model);
    const int* textureIndices = csmGetDrawableTextureIndices(model);
    const int* drawOrders = csmGetDrawableDrawOrders(model);
    const int* blendModes = csmGetDrawableBlendModes(model);
    const float* opacities = csmGetDrawableOpacities(model);
    if (!vertexCounts || !positions || !uvs || !indexCounts || !indices ||
        !maskCounts || !masks || !dynamicFlags || !textureIndices || !drawOrders ||
        !blendModes || !opacities) {
        return false;
    }

    snapshot->vertexPositions = reinterpret_cast<const float*>(positions[index]);
    snapshot->vertexUvs = reinterpret_cast<const float*>(uvs[index]);
    snapshot->indices = indices[index];
    snapshot->masks = masks[index];
    snapshot->vertexCount = vertexCounts[index] > 0 ? static_cast<uint32_t>(vertexCounts[index]) : 0;
    snapshot->indexCount = indexCounts[index] > 0 ? static_cast<uint32_t>(indexCounts[index]) : 0;
    snapshot->maskCount = maskCounts[index] > 0 ? static_cast<uint32_t>(maskCounts[index]) : 0;
    snapshot->dynamicFlags = static_cast<uint32_t>(dynamicFlags[index]);
    snapshot->textureIndex = textureIndices[index];
    snapshot->drawOrder = drawOrders[index];
    snapshot->blendMode = blendModes[index];
    snapshot->opacity = opacities[index];
    return snapshot->vertexPositions && snapshot->vertexUvs && snapshot->indices;
}
