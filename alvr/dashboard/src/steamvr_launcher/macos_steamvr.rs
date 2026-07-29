use std::path::Path;
use std::process::Command;

pub fn launch_steamvr() {
    let candidates = ["/Applications/Steam.app", "/Applications/SteamVR.app"];

    let found = candidates.iter().find(|p| Path::new(p).exists());

    match found {
        Some(path) => {
            println!("Found: {path}");

            let result = if path.ends_with("Steam.app") {
                Command::new("open")
                    .arg("-a")
                    .arg(path)
                    .spawn()
            } else {
                Command::new("open")
                    .arg(path)
                    .spawn()
            };

            match result {
                Ok(_) => println!("Launch command sent successfully."),
                Err(e) => eprintln!("Failed to launch: {e}"),
            }
        }
        None => {
            println!("Steam/SteamVR was not found in /Applications.");
        }
    }
}
