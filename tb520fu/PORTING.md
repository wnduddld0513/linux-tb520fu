# TB520FU 포팅 상태

이 브랜치는 Lenovo Yoga Tab Plus(TB520FU, lapis, SM8650)의 **초기 mainline 포팅 소스**입니다. 화면·멀티터치를 우선 구현했습니다. 사용자 요청에 따라 컴파일, DTB 빌드, 이미지 빌드는 실행하지 않았으며, 실기기 부팅·동작도 확인하지 않았습니다.

## 이번에 반영한 하드웨어

| 항목 | 반영 내용 | 근거 |
| --- | --- | --- |
| 패널 | Tianma / BOE NT36532 각각의 순정 초기화·종료 명령과 지연 | 순정 실행 중 `running.dts` |
| 화면 모드 | 전체 2944×1840, 120 Hz, 물리 크기 274×171 mm | 링크당 1472×1840 및 순정 porch |
| DSI | DSI0+DSI1, 링크당 D-PHY 4레인, DSI0 PLL 공유 | 순정 controller/PHY 설정 |
| DSC | 1.1 SCR1, 10 bpc→8 bpp, 736×20 슬라이스, 패킷당 2슬라이스 | 순정 DSC 속성 |
| 패널 전원 | PM8550 L11B 1.2 V / L12B 1.95 V / L13B 3.0 V, reset GPIO133 | 순정 공급 항목 및 리셋 배열 |
| 백라이트 | I2C6·I2C7의 KTZ8866 두 개, HWEN GPIO82, ENP72 / ENN73 | 순정 init-cmds, enable/disable 배열 |
| 밝기 | 두 칩을 하나의 backlight 장치로 제어, 범위 0…2047 | 순정 LSB/MSB 레지스터 |
| 터치 | SPI4 / CS0 / 9.6 MHz / IRQ GPIO162 상승 에지 | 순정 터치 노드 |
| 터치 프로토콜 | NT36532 trim ID, `0x1fbxxx` 레지스터, 캐스케이드 펌웨어 전송 및 CRC 명령 | Lenovo GPL 커널 6.1.68 `NT36XXX_SPI` |
| 입력 | 10점 MT, 16비트 좌표, 원시 범위 18400×29440, 패널 follower 및 suspend/resume | 순정 super-resolution 구현 |
| 저장장치 | UFS 및 reset GPIO210 | SM8650 기본 지원 + 보드 배선 |

TB321FU의 NT36523, 3레인 C-PHY, GPIO87 백라이트 구성을 그대로 사용하지 않습니다. NT36532 패널·터치와 두 KTZ8866을 별도 드라이버로 추가했습니다. 기존 TB321FU 자료는 참조용으로 남습니다.

## 장치 트리 선택

- `sm8650-lenovo-tb520fu.dtb`: Tianma 패널 + `novatek_ts_tianma_fw.bin`. 현재 덤프의 패널 선택을 기본으로 삼습니다.
- `sm8650-lenovo-tb520fu-boe.dtb`: BOE 패널 + `novatek_ts_boe_fw.bin`.

두 트리는 `sm8650-lenovo-tb520fu.dtsi`를 공유합니다. 부트로더가 패널을 자동 판별하도록 구현한 것은 아닙니다. 패널 종류에 맞는 DTB를 명시적으로 선택해야 합니다. 기존 TB321FU 설치 이미지나 GRUB/super 파티션 도구를 TB520FU에서 검증된 설치 절차로 취급하지 마세요.

120 Hz 모드의 계산은 링크당 수평 total 1691, 수직 total 2050을 기준으로 전체 픽셀 클럭 `3382 × 2050 × 120 / 1000 = 831972 kHz`입니다. 순정 DSI 비트 클럭을 DRM 픽셀 클럭으로 대입하지 않습니다. 패널 명령은 순정 순서를 유지하고, DCS 타입 0x05의 패딩 바이트는 전송 데이터에서 제외합니다.

터치 방향은 원시 X 반전 후 X/Y 교환으로 가정했습니다. 실기기 네 모서리 좌표를 확인해 `touchscreen-inverted-x/y`를 조정해야 합니다. 원시 좌표 정밀도를 보존하므로 출력 input 범위는 픽셀 크기의 10배입니다.

## 순정 펌웨어 준비

순정 바이너리는 로컬 덤프에서 가져오며 Git에는 체크섬·출처와 추출 도구만 포함합니다. 이 작업에서 아래 명령을 실행해 로컬 아카이브를 준비했습니다. 이는 이미지 빌드가 아닙니다.

```bash
cd /home/wnduddld0513/linux-tb520fu
python3 tools/pack-tb520fu-firmware.py --stock-root /home/wnduddld0513/tb520fu
```

결과는 `build_files/firmware-lenovo-tb520fu.tar.gz` 및 `.sha256`이며 둘 다 `.gitignore`로 제외됩니다. 두 터치 펌웨어, GPU zap, SQE, GMU의 다섯 파일을 포함합니다. `firmware-manifest.json`의 크기·SHA256과 다르면 추출 도구가 중단합니다. 다른 순정 버전을 사용할 때는 출처 및 프로토콜 호환성을 검토한 뒤 manifest를 갱신하세요.

이미지 생성 경로에는 `tb520fu-firmware.sh`를 연결했습니다. 아카이브가 없으면 실패하도록 했으며 TB321FU 펌웨어를 TB520FU용으로 대체하지 않습니다. 기존 linux-firmware의 일반 GPU SQE/GMU는 유지하고, TB520FU 전용 경로의 zap·터치 파일을 설치합니다. GitHub의 깨끗한 체크아웃에서 이미지를 만들려면 이 로컬 아카이브를 별도로 공급해야 합니다.

## 소스 위치와 남은 확인

- `packages/kernel/patches/0820-*`: NT36532 패널 및 순정 명령 배열.
- `packages/kernel/patches/0821-*`: NT36532 SPI 터치, 펌웨어 파서, 다운로드, 복구 및 전원 상태 전환.
- `packages/kernel/patches/0822-*`: KTZ8866 두 칩의 밝기·초기화 동기화.
- `packages/kernel/patches/0823-*`: msm DSI의 패킷당 슬라이스 수 및 SCR1 테이블 선택. 새 DT 속성이 없는 기존 보드는 종전 설정을 유지합니다.
- `source-manifest.json`: 순정 실행 DT와 GPL 터치 소스의 SHA256.
- `firmware-manifest.json`: 사용하는 순정 펌웨어의 SHA256 및 설치 경로.

**확인되지 않은 항목:** 실제 DSI/DPU SCR1 동작, PLL/PHY 타이밍, 두 링크의 화면 정합, 백라이트 전원 순서, 터치 방향·복구·절전 복귀, 기본 부팅 경로. 정적 패치 적용 확인은 컴파일 또는 하드웨어 동작 확인을 대신하지 않습니다.

순정의 30/60/90/144 Hz, HDR, HBM, ESD/TE 화면 복구, 펜 입력은 아직 구현 범위에 넣지 않았습니다. USB-C/DP, Wi-Fi/BT, DSP, 스피커/마이크, 센서, 충전 및 배터리는 후속 포팅 대상이며 TB321FU 노드를 활성화해 대체하지 않습니다. 완성된 TB520FU 배포 이미지나 설치 지원으로 표시하지 않습니다.

이번 작업의 정적 확인: 기존 관련 패치가 반영된 Linux v7.2.6 소스에 0820…0823을 `patch -F0`로 적용했습니다. Tianma on/off 118/13개, BOE on/off 100/12개의 명령과 지연이 순정과 일치합니다. 두 터치 펌웨어의 16개 파티션 범위, 아카이브의 다섯 파일 SHA256, 셸/Python 문법, DT 라벨 참조도 확인했습니다. 컴파일·DTB 생성·이미지 생성은 하지 않았습니다.
