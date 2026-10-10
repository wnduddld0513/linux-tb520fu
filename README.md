# Linux for Lenovo TB520FU

Linux port for the Lenovo Yoga Tab Plus / YOGA Pad Pro AI元启 (TB520FU, lapis), based on the Snapdragon 8 Gen 3 / SM8650. Development takes place on the `main` branch.

This repository contains kernel patches, device trees, firmware manifests and build recipes. It also includes Armada/Fedora bootc image configuration. Hardware definitions were adapted from the stock device tree, Lenovo GPL kernel and vendor sources, stock firmware and read-only ADB observations.

## Build status

Linux 7.2.6, 1,594 modules and both Tianma and BOE device trees were compiled as part of the SteamOS integration. The compiled kernel code is pinned to commit `54ed573a816532658f411e0cabf93072740976e2`.

A dedicated UEFI boot image, ARM64 runtime and SteamOS USB image were built locally. The files have not been uploaded to GitHub Releases. See the [SteamOS integration](https://github.com/wnduddld0513/SteamOS-ARM-Port/tree/main) and [build record](https://github.com/wnduddld0513/SteamOS-ARM-Port/blob/main/docs/tb520fu-build-review.json).

Linux boot and hardware operation on the tablet have not been tested. The entries below describe source implementation, not confirmed working hardware. The complete Armada/Fedora bootc image has not been build-tested.

## Display and touch

| Component | Current configuration |
| --- | --- |
| Resolution and orientation | 2944 × 1840, landscape |
| Refresh rate | 120 Hz; stock 30/60/90/144 Hz modes are not implemented |
| Panels | Tianma and BOE NT36532, with separate stock initialization and shutdown sequences |
| Display link | Dual DSI, four D-PHY lanes per link, DSC 1.1 SCR1, 10 bpc / 8 bpp |
| Backlight | Initialization and synchronized brightness control for two KTZ8866 controllers |
| Touch | Novatek SPI, ten contacts, panel-specific firmware paths, power management and recovery |
| Pen | Pressure, hover, tilt and button packet handling |

The panels share the board configuration but use separate panel settings and touch firmware.

| Panel | Device tree | Touch firmware |
| --- | --- | --- |
| Tianma | `sm8650-lenovo-tb520fu.dtb` | `novatek_ts_tianma_fw.bin` |
| BOE | `sm8650-lenovo-tb520fu-boe.dtb` | `novatek_ts_boe_fw.bin` |

Both panel definitions are present in the stock device tree. Sales region alone does not identify the fitted panel. Automatic panel detection is not implemented; select the matching DTB manually.

The initial touch transform inverts raw X and swaps X/Y. Corner coordinates and pen alignment need testing on hardware. HDR/HBM, ESD recovery, additional refresh rates, brightness range and resume behavior need further implementation or validation.

## Other hardware

None of these paths has been verified under Linux on the tablet.

| Hardware | Implementation and remaining work |
| --- | --- |
| GPU and video | Adreno 750 Freedreno/Turnip and Iris integration, with stock GPU/VPU firmware paths |
| Wi-Fi and Bluetooth | WCN7850 power, PCIe and UART configuration; Lapis RF/BT firmware paths. Calibration and firmware compatibility need validation |
| Speakers and microphones | Six AW882xx amplifiers, WCD9395, UCM and topology sources. DSP graphs, channels and microphone routing need validation |
| USB-C, DisplayPort and charging | PS5169, PM8550B eUSB2 repeater and PMIC GLINK/battmgr configuration. External display, fast charging and thermal policy need validation |
| Sensors | SSC configuration, DSP libraries and IMU services for LSM6DSO, TCS3408, ADS610x0 and related devices. OEM lid and SAR policies remain incomplete |
| Vibration | PM8550B HV haptics backend observed on the stock device, connected to Linux force feedback |
| Keyboard and trackpad | Pogo UART input driver at 921600 8N1, keys, media keys and four-contact multitouch. Handshake, LEDs and firmware updates remain incomplete |
| Buttons and pen magnet | PMIC/gpio-keys and pen insertion input configuration |
| NFC | Basic NCI transport following stock wiring. Vendor initialization, eSE and firmware updates remain incomplete |
| Fingerprint | Goodix power, reset and IRQ control. Sensor imaging, TEE integration and authentication are not implemented |
| Cameras | Stock wiring investigation, candidate sensors and common CAMSS configuration. Sensor power sequences, registers, CSI and capture paths remain incomplete |
| Power management | Common SM8650/PMIC configuration. Suspend/resume, battery drain and thermal behavior need validation |

Confirmed board-specific DTS, firmware and driver settings for other devices are excluded from the active TB520FU configuration. Shared SoC drivers, patch dependencies and uncertain shared support are retained.

## Porting reference

- [Hardware inventory](tb520fu/HARDWARE.md): stock evidence, implementation scope and remaining work
- [Porting and firmware setup](tb520fu/PORTING.md): DTB selection, local firmware extraction and runtime configuration
- [Stock wiring](tb520fu/stock-peripherals.json) and [ADB observations](tb520fu/live-hardware.json)
- [Source manifest](tb520fu/source-manifest.json) and [firmware manifest](tb520fu/firmware-manifest.json)
- [Static review](tb520fu/static-review.json)
- [Excluded patches](tb520fu/excluded-patches.txt) and [excluded firmware](tb520fu/excluded-firmware.txt)

Stock firmware binaries are not committed to Git. Extract them locally and check them against the manifest. Installation images and flashing procedures for other devices have not been validated for TB520FU.

## Repository setup

```bash
git clone --branch main https://github.com/wnduddld0513/linux_kernel_lenovo_tb520fu.git
cd linux_kernel_lenovo_tb520fu
bash tools/setup-fork.sh
```

The setup script restricts pushes to `main` in `wnduddld0513/linux_kernel_lenovo_tb520fu`. The pre-push hook rejects other repositories, branches, tags and deletions. Run the setup script for each new checkout. Explicitly bypassing Git hooks also bypasses this protection.

```bash
git add <changed-files>
git commit -m "Describe the TB520FU change"
git push origin main:main
```

Static checks cover source definitions, wiring, patches and firmware hashes. Compilation results are recorded in the SteamOS build report; neither replaces testing on hardware.

## Credits and license

The TB520FU configuration is based on [Armada](https://github.com/armada-os/armada) and the existing [Y700 Linux port](https://github.com/enij90/armada-tb321fu). Support status for those devices does not establish support for TB520FU.

Credit to [GUF296](https://github.com/GUF296) for the earlier port and [ROCKNIX](https://github.com/ROCKNIX/distribution) for the SM8650 work.

See [LICENSE.md](LICENSE.md). Included components retain their original licenses.
