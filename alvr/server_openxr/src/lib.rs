use openxr as xr;

pub fn initialize() -> Result<(), String> {
    let entry = unsafe { xr::Entry::load() }
        .map_err(|error| format!("Failed to load OpenXR Loader: {error}"))?;

    let extensions = entry
        .enumerate_extensions()
        .map_err(|error| format!("Failed to enumerate OpenXR extensions: {error}"))?;

    println!("OpenXR Loader initialized");
    println!("XR_KHR_metal_enable: {}", extensions.khr_metal_enable);

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn initialize_openxr_loader() {
        initialize().expect("OpenXR initialization failed");
    }
}
