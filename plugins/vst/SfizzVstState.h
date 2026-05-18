// SPDX-License-Identifier: BSD-2-Clause

// This code is part of the sfizz library and is licensed under a BSD 2-clause
// license. You should have receive a LICENSE.md file along with the code.
// If not, contact the sfizz maintainers at https://github.com/sfztools/sfizz

#pragma once
#include "base/source/fstreamer.h"
#include <absl/types/optional.h>
#include <string>
#include <vector>

using namespace Steinberg;

class SfizzVstState {
public:
    SfizzVstState() { sfzFile.reserve(8192); scalaFile.reserve(8192); }

    std::string sfzFile;
    float volume = 0;
    int32 numVoices = 64;
    int32 oversamplingLog2 = 0;
    int32 preloadSize = 8192;
    std::string scalaFile;
    int32 scalaRootKey = 60;
    float tuningFrequency = 440.0;
    float stretchedTuning = 0.0;
    int32 sampleQuality = 2;
    int32 oscillatorQuality = 1;
    int32 freewheelingSampleQuality = 10;
    int32 freewheelingOscillatorQuality = 3;
    bool sustainCancelsRelease = false;
    bool mpeEnabled = false;
    float mpeMasterPitchBendRange = 2.0f;
    float mpePerNotePitchBendRange = 48.0f;
    // Opt-outs for MPE auto-config: pin the wrapper-side value against
    // incoming RPN. Stored with "Ignore" semantics so the persisted value
    // matches the editor's checkbox label; default false (accept RPN).
    // - mpeMasterBendIgnoreRpn / mpePerNoteBendIgnoreRpn: RPN 0 (Pitch
    //   Bend Sensitivity), per axis.
    // - mpeIgnoreMcm: RPN 6 (MCM enable/disable). When true, the wrapper
    //   drops engine-driven mpeEnabled flips and re-asserts the user's
    //   toggle into the engine. Spec-permitted opt-out per MPE 1.0
    //   Appendix A.1; default is honor (false), matching the §2.2.1
    //   `shall` clause for MPE-compatible receivers.
    bool mpeMasterBendIgnoreRpn = false;
    bool mpePerNoteBendIgnoreRpn = false;
    bool mpeIgnoreMcm = false;
    int32 lastKeyswitch = -1;
    std::vector<absl::optional<float>> controllers;

    static constexpr uint64 currentStateVersion = 8;

    tresult load(IBStream* state);
    tresult store(IBStream* state) const;
};

struct SfizzPlayState {
    uint32 activeVoices;
};
