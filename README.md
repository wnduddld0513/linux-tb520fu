# Linux for Lenovo TB520FU

Lenovo **Yoga Tab Plus / YOGA Pad Pro AI元启 (TB520FU, lapis, Snapdragon 8 Gen 3 / SM8650)**용 Linux 포팅 저장소입니다. 작업 브랜치는 이 포크의 **`tb520fu`**입니다.

순정 DT, Lenovo GPL 커널·벤더 소스, 순정 펌웨어와 읽기 전용 ADB 장치 정보를 바탕으로 커널 드라이버·디바이스 트리·펌웨어 경로를 옮겼습니다. 저장소에는 Armada/Fedora bootc 기반 OS 이미지 구성도 포함되어 있습니다.

**SteamOS 통합에서 커널 7.2.6·모듈 1,594개와 Tianma/BOE DTB 컴파일을 완료했습니다. 빌드한 커널 코드의 고정 commit은 `54ed573a816532658f411e0cabf93072740976e2`입니다. 실기기 Linux 부팅·하드웨어 동작은 아직 검증하지 않았으며, 아래의 ‘구현’과 ‘연결’은 동작 확인을 뜻하지 않습니다. Armada/Fedora bootc 이미지 전체 빌드는 별도로 검증하지 않았습니다.**

전용 UEFI boot.img·ARM64 런타임·SteamOS USB 이미지와 파일 검사 결과는 [SteamOS TB520FU 시험판](https://github.com/wnduddld0513/SteamOS-ARM-Port/releases/tag/tb520fu-experimental-20261010) 및 [빌드 기록](https://github.com/wnduddld0513/SteamOS-ARM-Port/blob/tb520fu/docs/tb520fu-build-review.json)을 참조하세요. 기기에 플래시하거나 재부팅하지 않았습니다.

## 디스플레이·터치

| 항목 | 현재 소스 설정 |
| --- | --- |
| 기본 해상도·방향 | **2944×1840, 가로 방향** |
| 기본 주사율 | **120 Hz**. 순정의 30/60/90/144 Hz 모드는 아직 추가하지 않음 |
| 패널 | **Tianma·BOE NT36532 모두 포함**, 각각의 순정 초기화·종료 명령 반영 |
| 화면 연결 | 듀얼 DSI, 링크당 D-PHY 4레인, DSC 1.1 SCR1, 10 bpc / 8 bpp |
| 밝기 | KTZ8866 두 개의 초기화·밝기 동기화 구현 |
| 터치 | Novatek SPI 10점 터치, 패널별 펌웨어 경로, 전원 관리·복구 구현 |
| 펜 | 압력·호버·기울기·버튼 패킷 처리 구현 |

두 패널은 공통 보드 구성을 공유하고 패널 설정과 터치 펌웨어를 분리합니다.

| 패널 | 사용할 DTB | 터치 펌웨어 |
| --- | --- | --- |
| Tianma | `sm8650-lenovo-tb520fu.dtb` | `novatek_ts_tianma_fw.bin` |
| BOE | `sm8650-lenovo-tb520fu-boe.dtb` | `novatek_ts_boe_fw.bin` |

순정 DT에 두 패널 설정이 있어 모두 유지합니다. 내수·해외 판매 지역만으로 패널 종류를 결정하지 않습니다. **자동 패널 판별은 미구현**이며 패널에 맞는 DTB를 선택해야 합니다.

터치 방향은 원시 X 반전 후 X/Y 교환을 적용한 초기 설정입니다. 네 모서리 좌표·펜 정렬은 실기기 확인이 필요합니다. HDR/HBM·ESD 복구, 다른 주사율, 밝기 범위 및 절전 복귀도 추가 구현 또는 검증이 남아 있습니다.

## 다른 하드웨어

모든 항목은 이 브랜치의 Linux에서 실동작을 확인하기 전 상태입니다.

| 하드웨어 | 반영 내용 / 남은 작업 |
| --- | --- |
| GPU·영상 | Adreno 750 Freedreno/Turnip, Iris 및 순정 GPU/VPU 펌웨어 경로 연결 |
| Wi-Fi·Bluetooth | WCN7850 전원·PCIe·UART, Lapis RF/BT 펌웨어 연결. 보정·펌웨어 호환성 확인 필요 |
| 스피커·마이크 | 6× AW882xx, WCD9395, UCM·토폴로지 소스 추가. DSP 그래프·채널·마이크 경로 검증 필요 |
| USB-C·DisplayPort·충전 | PS5169, PM8550B eUSB2 repeater, PMIC GLINK/battmgr 연결. 외부 출력·고속충전·열 정책 검증 필요 |
| 센서 | LSM6DSO·TCS3408·ADS610x0 등의 SSC 설정·DSP 라이브러리 및 IMU 서비스 연결. 덮개·SAR 등 OEM 정책 미완료 |
| 진동 | 실제 기기에서 확인한 PM8550B HV haptics backend와 Linux FF 연결 |
| 키보드·트랙패드 | pogo UART 입력 드라이버, 921600 8N1, 키·미디어 키·4점 멀티터치 구현. handshake·LED·펌웨어 갱신 미완료 |
| 전원·볼륨·펜 자석 | PMIC/gpio-keys 및 펜 삽입 감지 입력 연결 |
| NFC | 순정 배선에 맞춘 기본 NCI 전송 경로 연결. vendor 초기화·eSE·펌웨어 갱신 미완료 |
| 지문 | Goodix 전원·리셋·IRQ 제어 구현. 센서 영상·TEE·지문 인증 미구현 |
| 카메라 | 순정 배선·후보 센서 조사 및 공용 CAMSS 설정. 센서별 전원·레지스터·CSI·촬영 경로 미완료 |
| 절전·전원 관리 | 공용 SM8650/PMIC 구성 연결. suspend/resume·배터리 소모·발열 검증 필요 |

확인된 다른 보드 전용 DTS·펌웨어·드라이버 설정은 TB520FU 활성 구성에서 제외했습니다. 공용 SoC 드라이버, 패치 의존성, 용도를 확정하지 못한 공용 지원은 유지합니다.

## 작업 자료

- [전체 하드웨어 대조표](tb520fu/HARDWARE.md): 순정 근거, 구현 범위와 남은 작업
- [포팅·펌웨어 준비](tb520fu/PORTING.md): DTB 선택, 로컬 펌웨어 추출 및 런타임 구성
- [순정 배선](tb520fu/stock-peripherals.json) · [ADB 장치 관측](tb520fu/live-hardware.json)
- [소스 출처](tb520fu/source-manifest.json) · [펌웨어 목록·해시](tb520fu/firmware-manifest.json)
- [정적 검토 기록](tb520fu/static-review.json)
- [제외한 패치](tb520fu/excluded-patches.txt) · [제외한 펌웨어](tb520fu/excluded-firmware.txt)

순정 펌웨어 바이너리는 Git에 포함하지 않습니다. 로컬 순정 파일에서 manifest에 맞춰 준비하며, 다른 기기의 설치 이미지·플래싱 절차는 TB520FU에서 검증된 절차가 아닙니다.

## 포크 전용 작업 브랜치

```bash
git clone --branch tb520fu https://github.com/wnduddld0513/linux-tb520fu.git
cd linux-tb520fu
bash tools/setup-fork.sh
```

설정 스크립트는 push 대상을 **`wnduddld0513/linux-tb520fu`의 `tb520fu → tb520fu`**로 고정합니다. pre-push hook은 다른 저장소·브랜치·태그·삭제 푸시를 차단합니다. 새 체크아웃마다 스크립트를 실행해야 하며, hook을 명시적으로 우회하는 행위까지 막지는 못합니다.

```bash
git add <변경한 파일>
git commit -m "Describe the TB520FU change"
git push origin tb520fu:tb520fu
```

`tb520fu` 브랜치 푸시는 이미지 빌드 워크플로의 push 조건에 포함되지 않습니다. 정적 검토는 소스·배선·패치·펌웨어 해시를 대상으로 합니다. 컴파일 결과는 위 SteamOS 빌드 기록을 따르며, Linux 실기기 검증을 대신하지 않습니다.

## 기반 프로젝트·라이선스

[Armada](https://github.com/armada-os/armada)와 기존 [Y700 Linux 포팅](https://github.com/enij90/armada-tb321fu)을 기반으로 TB520FU 구성을 분리했습니다. 기반 프로젝트의 다른 기기 지원 상태는 이 기기의 지원 상태를 뜻하지 않습니다.

기존 포팅의 출처인 [GUF296](https://github.com/GUF296)와 SM8650 기반 작업을 제공한 [ROCKNIX](https://github.com/ROCKNIX/distribution)의 기여를 유지합니다.

라이선스는 [LICENSE.md](LICENSE.md)를 따르며, 포함된 구성 요소는 각 원본 라이선스를 유지합니다.
