# TB520FU 포팅·소스 준비

Yoga Tab Plus(TB520FU / lapis / SM8650) 전용 소스 브랜치입니다. 화면 외에 Wi-Fi/BT, 6채널 앰프 구성, USB-C/DP, DSP/SSC, 펜, 키보드·트랙패드, PMIC 진동, NFC 기본 경로, 지문 제어까지 범위를 확장했습니다. **카메라 촬영, 지문 인증, SAR/덮개 정책 등은 미완료**입니다. [전체 하드웨어 상태](HARDWARE.md)에 구현 범위와 남은 항목을 따로 기록합니다.

사용자 요청으로 컴파일, dtc, DTB/이미지 생성, m4/alsatplg를 실행하지 않았습니다. ADB 장치 식별은 순정 벤더 시스템에서 읽은 결과이며 Linux 동작 확인이 아닙니다.

## 장치 트리 선택

- `sm8650-lenovo-tb520fu.dtb`: Tianma 패널 + `novatek_ts_tianma_fw.bin`. 현재 덤프의 패널 선택을 기본으로 삼습니다.
- `sm8650-lenovo-tb520fu-boe.dtb`: BOE 패널 + `novatek_ts_boe_fw.bin`.

두 트리는 `sm8650-lenovo-tb520fu.dtsi`를 공유합니다. 부트로더가 패널을 자동 판별하도록 구현한 것은 아닙니다. 패널 종류에 맞는 DTB를 명시적으로 선택해야 합니다. 기존 TB321FU 설치 이미지나 GRUB/super 파티션 도구를 TB520FU에서 검증된 설치 절차로 취급하지 마세요.

120 Hz 모드의 계산은 링크당 수평 total 1691, 수직 total 2050을 기준으로 전체 픽셀 클럭 `3382 × 2050 × 120 / 1000 = 831972 kHz`입니다. 순정 DSI 비트 클럭을 DRM 픽셀 클럭으로 대입하지 않습니다. 패널 명령은 순정 순서를 유지하고, DCS 타입 0x05의 패딩 바이트는 전송 데이터에서 제외합니다.

터치 방향은 원시 X 반전 후 X/Y 교환으로 가정했습니다. 실기기 네 모서리 좌표를 확인해 `touchscreen-inverted-x/y`를 조정해야 합니다. 원시 좌표 정밀도를 보존하므로 출력 input 범위는 픽셀 크기의 10배입니다.

## 순정 펌웨어 준비

```bash
python3 tools/pack-tb520fu-firmware.py \
  --stock-root /home/wnduddld0513/tb520fu \
  --image-dir /mnt/c/Users/HJY/Documents/TB520FU/Firmware/TB520FU_ROW_OPEN_USER_Q00002.0_W_ZUI_17.5.10.362_ST_260719-resigned/image
```

`firmware-manifest.json`의 원본 이미지 및 각 파일 크기/SHA256을 확인한 뒤 274개 파일을 `build_files/firmware-lenovo-tb520fu.tar.gz`에 담습니다. 펌웨어 추출/압축만 수행하며 커널이나 이미지를 빌드하지 않습니다. NON-HLOS/BTFM은 읽기 전용 FAT16 reader, dspso는 쓰기 옵션 없는 `debugfs rdump`를 씁니다. 일반 사용자 실행의 ownership 경고와 관계없이 추출 내용은 파일별 해시로 검증합니다.

아카이브·체크섬은 .gitignore로 제외하며 바이너리 payload를 GitHub에 올리지 않습니다. 포함 내용은 두 패널의 터치 펌웨어, GPU/VPU, ADSP/CDSP MDT/segments/DTB, Lapis Wi-Fi BDF/BT, 순정 ACF, DSP 라이브러리, 전체 SSC 설정, QRD ACDB입니다. 카메라 센서/개인 지문 정보·기기별 persist 보정 자료는 포함하지 않습니다.

`tb520fu-firmware.sh`는 정확한 manifest 파일 집합과 해시를 확인한 후 설치합니다. 아카이브가 없으면 중단하며 Y700 펌웨어를 받지 않습니다. QRD용 공용 BDF가 기기의 persist 보정을 대체하지는 않습니다. 다른 순정 릴리스라면 해시만 바꾸기 전에 프로토콜·펌웨어 ABI를 검토해야 합니다.

## DSP·센서 런타임

ADSP 라이브러리는 `/usr/share/qcom/sm8650/Lenovo/tb520fu/dsp/adsp`, SSC JSON은 `sensors/config`, 설정은 `sensors/sns_reg.conf`로 설치합니다. hexagonrpcd의 실제 파일 맵에 맞춘 경로입니다.

`tb520fu-sns-init`은 `/run/tb520fu-sns`에 virtual root를 구성하고 stock `sns_reg_config`에 `sensor_tp=Lapis` selector를 추가합니다. socinfo는 실제 `/sys/devices/soc0`에서 읽고 stock QRD 플랫폼 이름은 값이 없을 때만 보완합니다. daemon 패키지가 쓰는 `/var/lib/qcom-sns/persist/sensors/registry`와 동일한 경로를 사용합니다. 첫 실행에서는 이 태블릿의 persist를 **ro,noload**로 마운트해 registry만 로컬 상태 디렉터리에 복사합니다. persist 파티션을 수정하지 않습니다.

기존 `packages/tb321fu-sensors`는 공유 libssc/hexagonrpc/iio-sensor-proxy 패키지 소스의 역사적 디렉터리 이름입니다. TB520FU에는 별도 조건의 서비스와 새 IMU 이름/ID를 사용하며 Y700 하드웨어 서비스는 활성화하지 않습니다. 센서 firmware가 올라도 표준 proxy와 OEM Hall/SAR/presence 정책은 별도 작업입니다.

## 오디오 토폴로지

`audio_topology/SM8650-TB520FU.m4`와 `audio_topology/tb520fu/`에 이 카드의 소스를 추가했습니다. 토폴로지 템플릿은 source-manifest에 기록한 upstream commit으로 고정합니다. 향후 이미지 빌드 단계 `tb520fu-audio-topology.sh`가 `/usr/lib/firmware/qcom/sm8650/Lenovo-Yoga-TB520FU-tplg.bin`을 생성하도록 연결했습니다. **이번 작업에서는 이 스크립트나 m4/alsatplg를 실행하지 않았습니다.** UCM의 PCM0/1/2/3은 각각 헤드폰/스피커/캡처/DP와 맞춥니다. DSP 그래프·TDM 슬롯/클럭·6개 ACF 적용·마이크 ADC 경로는 실기기 검증이 남습니다.

## 소스 및 검토

- `0820` 패널, `0821` 터치·펜, `0822` 두 KTZ8866, `0823` DSI DSC packet/SCR1.
- `0824` AW882xx ACF/ath12k BDF 선택 및 Y700 graph40 quirk 범위 제한.
- `0825` Lenovo pogo serdev 키보드·트랙패드.
- `0826` 실제 PMIC HV haptics GPL backend와 Linux FF 연결.
- `0827` Goodix 전원/리셋/IRQ 제어. 보안 인증 프로토콜은 포함하지 않음.
- `stock-peripherals.json`: 순정 배선 추출. 노드 존재와 장착 여부는 구분.
- `live-hardware.json`: 식별자·개인 보정값을 제외한 ADB 관측.
- `source-manifest.json` / `firmware-manifest.json`: 원본 출처·해시.

정적 확인은 패치 `-F0` 순서 적용, DT include/label/endpoint 상호 참조, 펌웨어 파일 집합/해시, Python AST 및 shell syntax를 대상으로 합니다. 문법 검사에도 컴파일러/dtc를 사용하지 않습니다. 검토 결과는 `static-review.json`에 기록합니다. 이 확인으로 부팅, 패널 타이밍, 터치 방향, DSP/충전/절전/발열 동작을 증명하지 않습니다.
