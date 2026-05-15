// SPDX-License-Identifier: BSD-2-Clause

// This code is part of the sfizz library and is licensed under a BSD 2-clause
// license. You should have receive a LICENSE.md file along with the code.
// If not, contact the sfizz maintainers at https://github.com/sfztools/sfizz

#pragma once
#include "SfizzVstState.h"
#include "SfizzVstUpdates.h"
#include "OrderedEventProcessor.h"
#include "plugin/RMSFollower.h"
#include "sfizz/RTSemaphore.h"
#include "ring_buffer/ring_buffer.h"
#include "public.sdk/source/vst/vstaudioeffect.h"
#include <sfizz.hpp>
#include <SpinMutex.h>
#include <absl/types/optional.h>
#include <array>
#include <thread>
#include <memory>
#include <cstdlib>
#include <cstdint>

using namespace Steinberg;

class SfizzVstProcessor : public Vst::AudioEffect,
                          public OrderedEventProcessor<SfizzVstProcessor> {
public:
    SfizzVstProcessor();
    ~SfizzVstProcessor();

    tresult PLUGIN_API initialize(FUnknown* context) override;
    tresult PLUGIN_API terminate() override;
    tresult PLUGIN_API setBusArrangements(Vst::SpeakerArrangement* inputs, int32 numIns, Vst::SpeakerArrangement* outputs, int32 numOuts) override;

    tresult PLUGIN_API connect(IConnectionPoint* other) override;

    tresult PLUGIN_API setState(IBStream* stream) override;
    tresult PLUGIN_API getState(IBStream* stream) override;
    void syncStateToSynth();

    tresult PLUGIN_API canProcessSampleSize(int32 symbolicSampleSize) override;
    tresult PLUGIN_API setActive(TBool state) override;
    tresult PLUGIN_API process(Vst::ProcessData& data) override;

    // OrderedEventProcessor
    void playOrderedParameter(int32 sampleOffset, Vst::ParamID id, Vst::ParamValue value);
    void playOrderedEvent(const Vst::Event& event);

    void processMessagesFromUi();

    tresult PLUGIN_API notify(Vst::IMessage* message) override;
    void PLUGIN_API update(FUnknown* changedUnknown, int32 message) override;

    static FUnknown* createInstance(void*);

    static FUID cid;

    // --- Sfizz stuff here below ---
protected:
    RMSFollower _rmsFollower {};
    bool _multi { false };
private:
    // synth state. acquire processMutex before accessing
    std::unique_ptr<sfz::Sfizz> _synth;
    bool _isActive = false;
    SfizzVstState _state;
    float _currentStretchedTuning = 0;

    // Last wrapper-state values pushed to the synth for the MPE fields the
    // engine can itself write back to (via RPN 6 / RPN 0 auto-config). The
    // per-block "push wrapper state → synth" loop in process() is gated on
    // a diff against these so a host or UI change still propagates while an
    // engine-side auto-config update isn't overwritten on the next block.
    // Initial values match the SfizzVstState defaults, which also match the
    // engine defaults — so on the very first block no spurious push happens
    // for instances that load with defaults.
    bool _lastPushedMpeEnabled { false };
    float _lastPushedMpeMasterPitchBendRange { 2.0f };
    float _lastPushedMpePerNotePitchBendRange { 48.0f };

    // Wrapper-side RPN 0 (Pitch Bend Sensitivity) tracking. The engine
    // has its own RPN parser, but when the corresponding "Ignore RPN"
    // toggle is on the engine drops the incoming value before applying
    // it to bend-range state. The wrapper still needs to know the last
    // received value so the UI can render the case-3 "RPN received
    // while override is on" badge (the incoming value, struck through).
    // Per-channel parser state because RPN selection is channel-scoped
    // per the MIDI spec. absl::nullopt means no RPN 0 has been seen on
    // this axis since plugin instance start.
    struct RpnParserState {
        uint8_t selectedMsb { 0xFF };
        uint8_t selectedLsb { 0xFF };
    };
    std::array<RpnParserState, 16> _rpnState {};
    absl::optional<float> _lastReceivedMasterRpn;
    absl::optional<float> _lastReceivedPerNoteRpn;
    void parseAndTrackRpn(int channel, uint8_t cc, uint8_t value) noexcept;

    // Diff state for per-block "emit-on-change" of the engine's
    // effective bend ranges + last-RPN values. Effective sentinel
    // -1.0f forces a first-block emit even when engine matches the
    // default. Last-RPN sentinel -2.0f keeps the "not received" -1.0f
    // payload distinguishable from the wrapper's start-of-life state,
    // so an instance that never receives RPN still emits -1 once and
    // the UI gets a definitive "no RPN" signal.
    float _lastReportedEffectiveMasterBend { -1.0f };
    float _lastReportedEffectivePerNoteBend { -1.0f };
    float _lastReportedMasterLastRpn { -2.0f };
    float _lastReportedPerNoteLastRpn { -2.0f };

    // whether allowed to perform events (owns the processing lock)
    bool _canPerformEventsAndParameters {};

    // level meters
    bool _editorIsOpen = false;

    // updates
    IPtr<QueuedUpdates> _queuedMessages;
    IPtr<PlayStateUpdate> _playStateUpdate;
    IPtr<SfzUpdate> _sfzUpdate;
    IPtr<SfzDescriptionUpdate> _sfzDescriptionUpdate;
    IPtr<ScalaUpdate> _scalaUpdate;
    IPtr<AutomationUpdate> _automationUpdate;
    bool processUpdate(FUnknown* changedUnknown, int32 message);

    // client
    sfz::ClientPtr _client;
    std::unique_ptr<uint8_t[]> _oscTemp;
    void receiveOSC(int delay, const char* path, const char* sig, const sfizz_arg_t* args);

    // misc
    void loadSfzFileOrDefault(const std::string& filePath, bool initParametersFromState);

    // note event tracking
    std::array<float, 128> _noteEventsCurrentCycle; // 0: off, >0: on, <0: no change

    // noteId -> channel correlation for VST3 NoteExpressionValueEvent dispatch.
    // VST3 expression events key by noteId only; we need the originating note's
    // channel to dispatch to the right MPE engine method. Fixed-size table,
    // linear scan, RT-safe. Slot is free when noteId == kFreeNoteId.
    // (-1 is a valid host-doesn't-track sentinel and must not collide.)
    static constexpr int32 kFreeNoteId = -2;
    static constexpr size_t kMaxActiveNotes = 64;
    struct ActiveNoteEntry {
        int32 noteId = kFreeNoteId;
        int16 channel = 0;
    };
    std::array<ActiveNoteEntry, kMaxActiveNotes> _activeNotes {};

    void registerActiveNote(int32 noteId, int16 channel) noexcept;
    void clearActiveNote(int32 noteId) noexcept;
    int lookupChannelForNoteId(int32 noteId) const noexcept;

    // worker and thread sync
    std::thread _worker;
    volatile bool _workRunning = false;
    Ring_Buffer _fifoToWorker;
    RTSemaphore _semaToWorker;
    Ring_Buffer _fifoMessageFromUi;
    SpinMutex _processMutex;

    // time info
    int _timeSigNumerator = 0;
    int _timeSigDenominator = 0;
    void updateTimeInfo(const Vst::ProcessContext& context);

    // messaging
    struct RTMessage {
        const char* type;
        uintptr_t size;
        // 32-bit aligned data after header
        template <class T> const T* payload() const;
    };
    struct RTMessageDelete {
        void operator()(RTMessage* x) const noexcept { std::free(x); }
    };
    typedef std::unique_ptr<RTMessage, RTMessageDelete> RTMessagePtr;

    // worker
    void doBackgroundWork();
    void doBackgroundIdle(size_t idleCounter);
    void startBackgroundWork();
    void stopBackgroundWork();
    // writer
    bool writeWorkerMessage(const char* type, const void* data, uintptr_t size);
    // reader
    RTMessagePtr readWorkerMessage();
    bool discardWorkerMessage();

    // generic
    static bool writeMessage(Ring_Buffer& fifo, const char* type, const void* data, uintptr_t size);
};

class SfizzVstProcessorMulti : public SfizzVstProcessor {
public:
    tresult PLUGIN_API initialize(FUnknown* context) override;
    static FUnknown* createInstance(void*);
    static FUID cid;
};
//------------------------------------------------------------------------------

template <class T> const T* SfizzVstProcessor::RTMessage::payload() const
{
    return reinterpret_cast<const T*>(
        reinterpret_cast<const uint8*>(this) + sizeof(*this));
}
