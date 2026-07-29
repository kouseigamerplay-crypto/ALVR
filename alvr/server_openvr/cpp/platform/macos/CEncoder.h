#pragma once

#include "shared/threadtools.h"

#include <VideoToolbox/VideoToolbox.h>
#include <memory>

class PoseHistory;

class CEncoder : public CThread {
public:
    CEncoder(std::shared_ptr<PoseHistory> poseHistory);
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
    std::shared_ptr<PoseHistory> m_poseHistory;
    VTCompressionSessionRef m_compressionSession = nullptr;
    bool m_forceIDR = false;
};
