#include "PhoebeLive2DRuntime.h"

#include <iostream>

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

} // namespace

int main(int argc, char** argv)
{
    if (argc != 2) {
        std::cerr << "usage: probe_model3 <model3.json>\n";
        return 64;
    }

    PLDModel3ProbeResult result{};
    if (!PLDProbeModel3File(argv[1], &result)) {
        std::cerr << "model3 resource gate failed: " << argv[1] << '\n';
        return 1;
    }

    std::cout << "model3=" << argv[1]
              << " has_moc=" << (result.hasMoc ? "true" : "false")
              << " texture_count=" << result.textureCount
              << " has_texture=" << (result.hasTexture ? "true" : "false")
              << " has_display_info=" << (result.hasDisplayInfo ? "true" : "false")
              << " moc_version=" << result.moc.mocVersion
              << " parameter_count=" << result.moc.parameterCount
              << " drawable_count=" << result.moc.drawableCount
              << " logical_mask=0x" << std::hex << result.moc.logicalParameterMask
              << std::dec << '\n';

    if ((result.moc.logicalParameterMask & kRequiredMask) != kRequiredMask) {
        std::cerr << "model3 references are valid, but the logical parameter contract is incomplete\n";
        return 2;
    }
    std::cout << "model3 references and Cubism Core model are valid.\n";
    return 0;
}
