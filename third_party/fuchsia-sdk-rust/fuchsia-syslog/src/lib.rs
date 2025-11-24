#![allow(unused)]

pub fn init() -> Result<(), std::io::Error> {
    env_logger::Builder::from_default_env()
        .filter_level(log::LevelFilter::Info)
        .init();
    Ok(())
}

pub fn init_with_tags(tags: &[&str]) -> Result<(), std::io::Error> {
    env_logger::Builder::from_default_env()
        .filter_level(log::LevelFilter::Info)
        .init();
    log::info!("Initialized syslog with tags: {:?}", tags);
    Ok(())
}
