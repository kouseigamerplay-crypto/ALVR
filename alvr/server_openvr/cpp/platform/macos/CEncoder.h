#pragma once

#include "shared/threadtools.h"

#include <VideoToolbox/VideoToolbox.h>

class CEncoder : public CThread {
public:
    CEncoder();
    ~CEncoder() override;

    bool Init() override;
    void Run() override;

    void Stop();
    void OnStreamStart();
    void InsertIDR();

    void NewFrameReady();
    void WaitForEncode();
    void CaptureFrame();

private:
    VTCompressionSessionRef m_compressionSession = nullptr;
    bool m_forceIDR = false;
};
