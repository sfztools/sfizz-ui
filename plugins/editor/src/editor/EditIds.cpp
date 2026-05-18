// SPDX-License-Identifier: BSD-2-Clause

// This code is part of the sfizz library and is licensed under a BSD 2-clause
// license. You should have receive a LICENSE.md file along with the code.
// If not, contact the sfizz maintainers at https://github.com/sfztools/sfizz

#include "EditIds.h"

EditRange EditRange::get(EditId id)
{
    switch (id) {
    default:
        assert(false);
        return {};
    case EditId::Volume:
        return { 0, -60, 6 };
    case EditId::Polyphony:
        return { 64, 1, 256 };
    case EditId::Oversampling:
        return { 0, 0, 3 };
    case EditId::PreloadSize:
        return { 8192, 1024, 65536 };
    case EditId::ScalaRootKey:
        return { 60, 0, 127 };
    case EditId::TuningFrequency:
        return { 440, 300, 500 };
    case EditId::StretchTuning:
        return { 0, 0, 1 };
    case EditId::SampleQuality:
        return { 2, 0, 10 };
    case EditId::OscillatorQuality:
        return { 1, 0, 3 };
    case EditId::FreewheelingSampleQuality:
        return { 10, 0, 10 };
    case EditId::FreewheelingOscillatorQuality:
        return { 3, 0, 3 };
    case EditId::SustainCancelsRelease:
        return { 0, 0, 1 };
    case EditId::MPEEnabled:
        return { 0, 0, 1 };
    case EditId::MPEMasterPitchBendRange:
        return { 2, 0, 96 };
    case EditId::MPEPerNotePitchBendRange:
        return { 48, 0, 96 };
    case EditId::MPEMasterBendIgnoreRpn:
        return { 0, 0, 1 };
    case EditId::MPEPerNoteBendIgnoreRpn:
        return { 0, 0, 1 };
    case EditId::MPEIgnoreMcm:
        return { 0, 0, 1 };
    case EditId::MPEMasterEffectiveBendRange:
        return { 2, 0, 96 };
    case EditId::MPEPerNoteEffectiveBendRange:
        return { 48, 0, 96 };
    case EditId::MPEMasterBendLastRpn:
        // -1 sentinel = no RPN 0 received yet for this axis. 0..96
        // covers every valid received value (MPE 1.0 caps bend range
        // at ±96 semitones / 8 octaves).
        return { -1, -1, 96 };
    case EditId::MPEPerNoteBendLastRpn:
        return { -1, -1, 96 };
    case EditId::UIActivePanel:
        return { 0, 0, 255 };
    case EditId::UIZoom:
        return { 100, 100, 300 };
    }
}
