# Linux TB520FU — Yoga Tab Plus 포팅

`wnduddld0513/linux-tb520fu`의 **`tb520fu` 전용 브랜치**입니다. Lenovo 순정 DT·GPL 커널·벤더 덤프와 연결된 TB520FU의 읽기 전용 ADB 정보를 바탕으로 포팅합니다.

**현재는 소스 포팅 단계입니다. 빌드·DTB 생성·이미지 생성·Linux 실기기 부팅 검증을 하지 않았습니다. 아래 항목은 동작 보증이 아닙니다. 카메라 촬영·지문 인증 등은 아직 미완료입니다.**

| 하드웨어 | 반영 내용 / 상태 |
| --- | --- |
| 화면·밝기 | Tianma/BOE NT36532, 2944×1840 120 Hz, dual DSI/DSC, dual KTZ8866 소스 구현 |
| 터치·펜 | NT36532 SPI 10점 터치, 8191단계 펜 압력·호버·기울기 소스 구현 |
| GPU·영상 | Adreno 750, Iris, 순정 GPU/VPU 펌웨어 경로 연결 |
| Wi-Fi·BT | WCN7850 전원·PCIe·UART, Lapis 전용 RF/BT 펌웨어 연결 |
| 오디오 | 6× AW882xx, WCD9395, USBSS, UCM 및 TB520FU 토폴로지 소스 추가 |
| USB-C·DP·충전 | PS5169, PM8550B eUSB2 repeater, PMIC GLINK/battmgr 연결 |
| 센서 | 실제 LSM6DSO·TCS3408·ADS610x0 등 SSC 구성/라이브러리, FastRPC·IMU 서비스 연결 |
| 진동 | 실제 PM8550B HV haptics 드라이버·모터 설정 포팅; AW86937 구성 제외 |
| 키보드·트랙패드 | pogo serdev 입력 드라이버, 순정 921600 8N1, 4점 MT·미디어 키 구현 |
| NFC | 순정 VEN/IRQ 배선으로 기본 NCI 연결; eSE·펌웨어 갱신은 미구현 |
| 지문 | Goodix 전원·리셋·IRQ 제어 구현; 영상·인증은 미구현 |
| 카메라 | CAMSS/OV13B10 공용 드라이버 설정 및 순정 배선 조사; 센서·전원·촬영 경로 미완료 |

상세 현황: [전체 하드웨어 목록](tb520fu/HARDWARE.md), [포팅·펌웨어 준비](tb520fu/PORTING.md), [실기기에서 읽은 장치 정보](tb520fu/live-hardware.json).

## 포크에만 푸시

```bash
git clone --branch tb520fu https://github.com/wnduddld0513/linux-tb520fu.git
cd linux-tb520fu
bash tools/setup-fork.sh
```

설정 스크립트가 이 포크의 `tb520fu → tb520fu`로 push URL/refspec을 고정합니다. `.githooks/pre-push`는 다른 저장소·브랜치·태그·삭제 푸시를 차단합니다. 새 체크아웃마다 설정이 필요하며, Git hook을 명시적으로 우회하는 행위까지 막지는 못합니다. `main`은 원래 기준 상태로 유지합니다.

```bash
git add <변경한 파일>
git commit -m "Describe the TB520FU change"
git push origin tb520fu:tb520fu
```

업스트림 동기화 워크플로와 PR 도구도 이 포크를 대상으로 합니다. TB520FU 브랜치 푸시는 이미지 빌드 워크플로의 push 조건에 포함되지 않습니다.

다른 기기 전용 DTS와 펌웨어는 이 구성에서 제거했고, 다른 기기 패널·터치·내장 게임패드 등의 패치는 활성 series에서 제외했습니다. 제외 목록은 [패치](tb520fu/excluded-patches.txt)와 [펌웨어](tb520fu/excluded-firmware.txt)에 있습니다. 일반 SoC 기능, 다른 패치의 선행 조건, 확실하지 않은 공용 USB/HID 지원은 유지합니다. 원본 TB321FU 설명은 [역사적 참조 문서](docs/TB321FU-reference.md)로 분리했습니다.
