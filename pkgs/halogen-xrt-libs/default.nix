{
  lib,
  runCommand,
  patchelf,
  xrtCombined,
}:

runCommand "halogen-xrt-libs"
  {
    nativeBuildInputs = [ patchelf ];
    meta = {
      description = "XRT libraries for the halogen-flash container, flattened and rpath-stripped";
      platforms = [ "x86_64-linux" ];
      license = lib.licenses.asl20;
    };
  }
  ''
    mkdir -p $out/opt/xilinx/xrt/lib
    for f in libxrt_coreutil.so.2 libxrt_core.so.2 libxrt_driver_xdna.so.2; do
      if [ ! -e "${xrtCombined}/lib/$f" ]; then echo "missing $f" >&2; exit 1; fi
      cp -L "${xrtCombined}/lib/$f" "$out/opt/xilinx/xrt/lib/$f"
      chmod +w "$out/opt/xilinx/xrt/lib/$f"
      patchelf --remove-rpath "$out/opt/xilinx/xrt/lib/$f"
    done
  ''
