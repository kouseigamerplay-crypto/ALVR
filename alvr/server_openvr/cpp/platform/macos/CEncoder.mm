#include "CEncoder.h"

#include <CoreMedia/CoreMedia.h>
#include <CoreVideo/CoreVideo.h>

#include <cstdio>

namespace {
constexpr int kProbeWidth = 1280;
constexpr int kProbeHeight = 720;
}

CEncoder::CEncoder() = default;

CEncoder::~CEncoder() {
    Stop();
}

bool CEncoder::Init() {
    if (m_compressionSession != nullptr) {
        return true;
    }

    const OSStatus status = VTCompressionSessionCreate(
        kCFAllocatorDefault,
        kProbeWidth,
        kProbeHeight,
        kCMVideoCodecType_H264,
        nullptr,
        nullptr,
        nullptr,
        nullptr,
        this,
        &m_compressionSession
    );

    if (status != noErr || m_compressionSession == nullptr) {
        std::fprintf(
            stderr,
            "VTCompressionSessionCreate failed with status %d\n",
            static_cast<int>(status)
        );

        m_compressionSession = nullptr;
        return false;
    }

    std::fprintf(
        stderr,
        "VideoToolbox compression session created successfully.\n"
    );

    return true;
}

void CEncoder::Run() {
}

void CEncoder::Stop() {
    if (m_compressionSession == nullptr) {
        return;
    }

    VTCompressionSessionCompleteFrames(
        m_compressionSession,
        kCMTimeInvalid
    );

    VTCompressionSessionInvalidate(m_compressionSession);
    CFRelease(m_compressionSession);
    m_compressionSession = nullptr;

    std::fprintf(
        stderr,
        "VideoToolbox compression session destroyed.\n"
    );
}

void CEncoder::OnStreamStart() {
    Init();
}

void CEncoder::InsertIDR() {
    m_forceIDR = true;
}

void CEncoder::NewFrameReady() {
}

void CEncoder::WaitForEncode() {
}

void CEncoder::CaptureFrame() {
}
