use openxr_sys as xr;
use std::os::raw::c_char;

/// LoaderからOpenXR関数を問い合わせられたときに呼ばれる入口。
///
/// 現在はまだ個別のOpenXR関数を実装していないため、
/// ERROR_FUNCTION_UNSUPPORTEDを返す最小版。
unsafe extern "system" fn get_instance_proc_addr(
    _instance: xr::Instance,
    name: *const c_char,
    function: *mut Option<xr::pfn::VoidFunction>,
) -> xr::Result {
    if name.is_null() || function.is_null() {
        return xr::Result::ERROR_VALIDATION_FAILURE;
    }

    unsafe {
        *function = None;
    }

    xr::Result::ERROR_FUNCTION_UNSUPPORTED
}

/// OpenXR LoaderとRuntimeが最初に行う交渉の入口。
#[unsafe(no_mangle)]
pub unsafe extern "system" fn xrNegotiateLoaderRuntimeInterface(
    loader_info: *const xr::loader::XrNegotiateLoaderInfo,
    runtime_request: *mut xr::loader::XrNegotiateRuntimeRequest,
) -> xr::Result {
    if loader_info.is_null() || runtime_request.is_null() {
        return xr::Result::ERROR_VALIDATION_FAILURE;
    }

    let loader_info = unsafe { &*loader_info };
    let runtime_request = unsafe { &mut *runtime_request };

    if loader_info.ty != xr::loader::XrNegotiateLoaderInfo::TYPE
        || loader_info.struct_version
            != xr::loader::XrNegotiateLoaderInfo::VERSION
        || loader_info.struct_size
            < std::mem::size_of::<xr::loader::XrNegotiateLoaderInfo>()
    {
        return xr::Result::ERROR_INITIALIZATION_FAILED;
    }

    let interface_version = xr::loader::CURRENT_LOADER_RUNTIME_VERSION;

    if interface_version < loader_info.min_interface_version
        || interface_version > loader_info.max_interface_version
    {
        return xr::Result::ERROR_INITIALIZATION_FAILED;
    }

    runtime_request.runtime_interface_version = interface_version;
    runtime_request.runtime_api_version = xr::CURRENT_API_VERSION;
    runtime_request.get_instance_proc_addr = Some(get_instance_proc_addr);

    xr::Result::SUCCESS
}
