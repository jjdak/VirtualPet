#include "PhoebeLive2DRuntime.h"

#include <cstdint>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>

namespace {

constexpr uint32_t kRequiredMask =
    PLDLogicalParameterAngleX |
    PLDLogicalParameterAngleY |
    PLDLogicalParameterAngleZ |
    PLDLogicalParameterBodyAngleX |
    PLDLogicalParameterEyeSmile |
    PLDLogicalParameterMouthOpenY |
    PLDLogicalParameterBreath |
    PLDLogicalParameterHairSwing |
    PLDLogicalParameterHatSwing;

void printMissing(uint32_t mask)
{
    const struct {
        uint32_t bit;
        const char* name;
    } parameters[] = {
        {PLDLogicalParameterAngleX, "ParamAngleX"},
        {PLDLogicalParameterAngleY, "ParamAngleY"},
        {PLDLogicalParameterAngleZ, "ParamAngleZ"},
        {PLDLogicalParameterBodyAngleX, "ParamBodyAngleX"},
        {PLDLogicalParameterEyeSmile, "ParamEyeSmile"},
        {PLDLogicalParameterMouthOpenY, "ParamMouthOpenY"},
        {PLDLogicalParameterBreath, "ParamBreath"},
        {PLDLogicalParameterHairSwing, "ParamHairSwing"},
        {PLDLogicalParameterHatSwing, "ParamHatSwing"},
    };

    std::cerr << "missing logical parameters:";
    for (const auto& parameter : parameters) {
        if ((mask & parameter.bit) != 0) {
            std::cerr << ' ' << parameter.name;
        }
    }
    std::cerr << '\n';
}

} // namespace

int main(int argc, char** argv)
{
    if (argc != 2) {
        std::cerr << "usage: probe_moc <model.moc3>\n";
        return 64;
    }

    std::ifstream input(argv[1], std::ios::binary);
    if (!input) {
        std::cerr << "cannot open: " << argv[1] << '\n';
        return 66;
    }
    std::vector<unsigned char> bytes(
        (std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());

    PLDModelProbeResult result{};
    if (!PLDProbeMoc(bytes.data(), static_cast<uint32_t>(bytes.size()), &result)) {
        std::cerr << "Cubism Core rejected moc3: " << argv[1] << '\n';
        return 1;
    }

    std::cout << "moc_version=" << result.mocVersion
              << " parameter_count=" << result.parameterCount
              << " drawable_count=" << result.drawableCount
              << " logical_mask=0x" << std::hex << result.logicalParameterMask
              << std::dec << '\n';
    if ((result.logicalParameterMask & kRequiredMask) != kRequiredMask) {
        printMissing(kRequiredMask & ~result.logicalParameterMask);
        std::cerr << "production-v1 contract is incomplete; RigLite runtime work may continue if its capability gate passes\n";
        return 2;
    }
    std::cout << "Cubism Core loaded model and satisfied logical parameter contract.\n";
    return 0;
}
