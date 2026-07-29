use std::path::Path;

pub fn launch_steamvr() {
    let candidates = ["/Applications/Steam.app", "/Applications/SteamVR.app"];

    let found = candidates.iter().find(|p| Path::new(p).exists());

    match found {
        Some(path) => {
            println!("Found: {path}");
            println!("SteamVR launching on macOS is not implemented yet.");
        }
        None => {
            println!("Steam/SteamVR was not found in /Applications.");
        }
    }
}
