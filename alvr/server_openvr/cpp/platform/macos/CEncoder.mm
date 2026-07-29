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

    CMBlockBufferRef blockBuffer =
        CMSampleBufferGetDataBuffer(sampleBuffer);

    if (blockBuffer == nullptr) {
        std::fprintf(
            stderr,
            "[ALVR macOS] Encoded sample has no CMBlockBuffer\n"
        );
        return;
    }

    const size_t encodedSize =
        CMBlockBufferGetDataLength(blockBuffer);

    std::fprintf(
        stderr,
        "[ALVR macOS] Frame encoded: %zu bytes\n",
        encodedSize
    );

    char *dataPointer = nullptr;
    size_t totalLength = 0;

    const OSStatus bufferStatus = CMBlockBufferGetDataPointer(
        blockBuffer,
        0,
        nullptr,
        &totalLength,
        &dataPointer
    );

    if (bufferStatus != kCMBlockBufferNoErr || dataPointer == nullptr) {
        std::fprintf(
            stderr,
            "[ALVR macOS] Failed to access encoded data (%d)\n",
            static_cast<int>(bufferStatus)
        );
        return;
    }

    std::fprintf(
        stderr,
        "[ALVR macOS] Raw encoded buffer: %zu bytes\n",
        totalLength
    );

    const uint8_t *bytes =
        reinterpret_cast<const uint8_t *>(dataPointer);

    size_t offset = 0;
    size_t nalIndex = 0;

    while (offset + 4 <= totalLength) {
        const uint32_t nalLength =
            (static_cast<uint32_t>(bytes[offset]) << 24) |
            (static_cast<uint32_t>(bytes[offset + 1]) << 16) |
            (static_cast<uint32_t>(bytes[offset + 2]) << 8) |
            static_cast<uint32_t>(bytes[offset + 3]);

        offset += 4;

        if (nalLength == 0 || offset + nalLength > totalLength) {
            std::fprintf(
                stderr,
                "[ALVR macOS] Invalid NAL length at offset %zu: %u bytes\n",
                offset - 4,
                nalLength
            );
            return;
        }

        const uint8_t nalType = bytes[offset] & 0x1F;

        std::fprintf(
            stderr,
            "[ALVR macOS] NAL #%zu: type=%u length=%u bytes\n",
            nalIndex,
            static_cast<unsigned>(nalType),
            nalLength
        );

        offset += nalLength;
        ++nalIndex;
    }

    if (offset != totalLength) {
        std::fprintf(
            stderr,
            "[ALVR macOS] Trailing encoded bytes: %zu\n",
            totalLength - offset
        );
    }

    std::fprintf(
        stderr,
        "[ALVR macOS] Parsed %zu NAL unit(s)\n",
        nalIndex
    );
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
