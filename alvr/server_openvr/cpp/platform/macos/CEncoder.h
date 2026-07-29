#pragma once

#include "shared/threadtools.h"

class CEncoder : public CThread {
public:
    CEncoder() = default;
    ~CEncoder() = default;

    bool Init() override { return true; }
    void Run() override { }

    void Stop() { }
    void OnStreamStart() { }
    void InsertIDR() { }

    void NewFrameReady() { }
    void WaitForEncode() { }
    void CaptureFrame() { }
};
