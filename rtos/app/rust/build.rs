use std::env;
use std::path::PathBuf;

fn main() {
    let include_paths = vec![
        "/usr/include",
        "/usr/lib/gcc-cross/aarch64-linux-gnu/11/include",
        "/usr/lib/gcc-cross/aarch64-linux-gnu/11/../../../../aarch64-linux-gnu/include",
        "../../threadx/common/inc",
        "../../threadx/ports/cortex_a53/gnu/inc"
    ];

    let mut builder = bindgen::Builder::default()
        .header("../../threadx/common/inc/tx_api.h")
        .clang_arg("-std=c11");

    for path in include_paths {
        builder = builder.clang_arg(format!("-I{}", path));
    }
    println!("start binding...");

    let bindings = builder
        .use_core()
        .ctypes_prefix("core::ffi")
        .generate()
        .expect("unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("couldn't write bindings!");
}
