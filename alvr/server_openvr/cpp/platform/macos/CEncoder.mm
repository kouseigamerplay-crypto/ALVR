#include "CEncoder.h"

#include <CoreMedia/CoreMedia.h>
#include <CoreVideo/CoreVideo.h>

#include <cstdio>
#include <cstring>

namespace {
constexpr int kProbeWidth = 1280;
constexpr int kProbeHeight = 720;

void CompressionOutputCallback(
    void *outputCallbackRefCon,
    void *sourceFrameRefCon,
    OSStatus status,
    VTEncodeInfoFlags infoFlags,
    CMSampleBufferRef sampleBuffer
) {
    (void)outputCallbackRefCon;
    (void)sourceFrameRefCon;
    (void)infoFlags;

    if (status != noErr || sampleBuffer == nullptr) {
        std::fprintf(
            stderr,
            "[ALVR macOS] Encode failed (%d)\n",
            static_cast<int>(status)
        );
        return;
    }

    std::fprintf(stderr, "[ALVR macOS] Frame encoded!\n");
}
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
        CompressionOutputCallback,
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
    if (!Init()) {
        return;
    }

    CVPixelBufferRef pixelBuffer = nullptr;

    const OSStatus createStatus = CVPixelBufferCreate(
        kCFAllocatorDefault,
        kProbeWidth,
        kProbeHeight,
        kCVPixelFormatType_32BGRA,
        nullptr,
        &pixelBuffer
    );

    if (createStatus != kCVReturnSuccess || pixelBuffer == nullptr) {
        std::fprintf(
            stderr,
            "[ALVR macOS] CVPixelBufferCreate failed (%d)\n",
            static_cast<int>(createStatus)
        );
        return;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    const size_t dataSize = CVPixelBufferGetDataSize(pixelBuffer);

    if (baseAddress != nullptr) {
        std::memset(baseAddress, 0, dataSize);
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    const CMTime presentationTime = CMTimeMake(0, 1);

    const OSStatus encodeStatus = VTCompressionSessionEncodeFrame(
        m_compressionSession,
        pixelBuffer,
        presentationTime,
        kCMTimeInvalid,
        nullptr,
        nullptr,
        nullptr
    );

    CVPixelBufferRelease(pixelBuffer);

    if (encodeStatus != noErr) {
        std::fprintf(
            stderr,
            "[ALVR macOS] VTCompressionSessionEncodeFrame failed (%d)\n",
            static_cast<int>(encodeStatus)
        );
        return;
    }

    VTCompressionSessionCompleteFrames(
        m_compressionSession,
        kCMTimeInvalid
    );
}
