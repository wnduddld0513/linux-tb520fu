# TB520FU 전체 하드웨어 대조표

모든 “연결/구현” 표시는 소스 반영을 뜻합니다. 이 브랜치의 Linux에서 확인된 ✅ 항목은 아직 없습니다. 빌드와 Linux 부팅은 사용자 요청에 따라 하지 않았습니다. ADB 확인은 실행 중인 순정 벤더 시스템의 장치 식별에만 사용했습니다.

## 표시·입력·액세서리

| 장치 | 순정 근거 | 이 브랜치 상태 |
| --- | --- | --- |
| Tianma / BOE NT36532 LCD | 실행 DT, 2944×1840, 순정 30/60/90/120/144 Hz | 각각의 초기화 배열, dual DSI D-PHY 4레인, DSC 1.1 SCR1, 120 Hz 구현. 나머지 모드·HDR/HBM·ESD 복구는 미구현 |
| KTZ8866 2개 | ADB 2-0011 / 3-0011, HWEN82·bias72/73 | 두 칩 밝기 0…2047 동기화 및 초기화 구현 |
| NT36532 no-flash 터치 | ADB spi0.0 → NVT-ts, GPL NT36XXX_SPI | 캐스케이드 펌웨어 16개 파티션 범위 확인, 10점 16비트 MT, panel follower PM·복구 구현 |
| 액티브 펜 | ADB NVTCapacitivePen, 압력8191·거리1·tilt±60 | 터치 SPI의 14바이트 펜 패킷, 체크섬·버튼·좌표 변환·release 구현 |
| 펜 자석 2개 | 순정 hall_detect GPIO177/182 | 별도 SW_PEN_INSERTED 입력 2개. 합성 충전 상태나 실제 충전 제어로 표시하지 않음 |
| 펜 Bluetooth 버튼 | ADB Lenovo Tab Pen Pro Mouse/Consumer Control | 일반 Bluetooth HID 경로 유지. 자동 페어링·전용 프레젠테이션 동작은 미구현 |
| pogo 키보드·트랙패드 | GPL lenovo_keyboard, 순정 liblenovo_keyboard.so | QUP2 SE2 @888000, **921600 8N1**, GPIO173/198/171/119, PPP framing·스크램블·키/미디어·4점 MT·분리 release·wake PM 구현. LED/펌웨어 갱신·HAL 명령 handshake는 미구현; RX-only 수신은 실기기 검증 필요 |
| 전원·볼륨 키 | 순정 pmic_pwrkey/resin/gpio-keys | PMIC PON 및 gpio-keys 연결 |
| 외부 Legion G9 | USB HID 액세서리 | 일반 HID 유지, TB520FU용 IMU/PMIC 진동 합성 프로필 추가. 내장 장치가 아니며 장착 상태 테스트 안 함 |

## SoC·연결·전원

| 장치 | 이 브랜치 반영 및 제한 |
| --- | --- |
| SM8650 CPU·GIC·타이머·RPMh·interconnect | 공용 SM8650 지원과 필요한 클럭 패치 유지 |
| GPU Adreno 750 | Freedreno/Turnip 경로, TB520FU zap, gen70900 SQE/GMU manifest 연결. A830 전용 패치/블롭 제외 |
| UFS·리셋 | UFS 전원·GPIO210 연결 |
| Iris 영상 코덱 | VIDEO_QCOM_IRIS 및 순정 vpu33_4v.mbn 연결. 가속 디코딩 실동작 미확인 |
| WCN7850 Wi-Fi | PCIe0, reset94/wake96, PMU 입력/출력 레일, Lapis ROW ELF BDF 선택 패치. 일반 WCN7850 amss/m3/regdb는 유지. RF 보정/persist 및 firmware ABI 실기기 확인 필요 |
| WCN7850 Bluetooth | UART14·PMU, 순정 hmtnv20_Lapis.bin/hmtbtfw20.tlv 연결 |
| USB-C 단일 포트 | PMIC GLINK 역할 전환·충전 보고, USB3/QMP PHY, PM8550B eUSB2 repeater 연결. Y700 두 번째 포트/GPIO58 전환 제거 |
| USBSS 아날로그 오디오 | ADB 1-000e wcd-usbss-i2c-driver, WCD9390 USBSS용 mainline driver 연결. FSA4480 @43은 제외 |
| PS5169·DisplayPort | ADB 2-0030, PS5169 드라이버·QMP/DP graph 연결. AUX/극성·신호 튜닝·외부 모니터/오디오 미검증 |
| 배터리·유선 충전 | ADSP GLINK와 BATTERY_QCOM_BATTMGR로 상태를 받는 경로 연결. 충전 정책/고속충전/thermal limits 미검증; 임의 SMB 레지스터 쓰기 없음 |
| ADSP·CDSP·FastRPC | stock NON-HLOS에서 MDT/segments/DTB, dspso·vendor DSP 라이브러리 추출 manifest 및 runtime 연결 |
| PMIC RTC·온도·전원 관리 | 공용 PMK8550/PM8550/B/VS/VE 지원 유지. 절전·복귀·배터리 소모·열 정책 미검증 |
| 보안 GPIO | 순정 예약 핀40…43,74 반영. 다른 보드의 32…39 예약 범위를 제거해 실제 NFC34/35 배선을 보존 |
| I2C5 debug PMIC @34/@35/@3b | 순정 i2c_pmic 바인딩은 확인. 범용 디버그 바인딩만으로 실제 SMB1396/IDT9418 기능을 확정하지 않음. 충전기/펜 충전 제어 드라이버는 미포팅 |

## 소리·진동·센서

| 장치 | 이 브랜치 반영 및 제한 |
| --- | --- |
| 6× AW882xx 스마트 앰프 | ADB에서 I2C2/3 @34/35/36 모두 확인. 채널0/4/2 및1/3/5, 공유 reset128/28, 순정 ACF와 Linux I2C aliases6/7 연결 |
| WCD9395·마이크 | SoundWire RX/TX·LPASS macro·micbias2=2.7 V 및 UCM 연결. 실제 내장 마이크 ADC 선택/이득·USB-C 헤드셋 검증 필요 |
| 오디오 토폴로지 | TB520FU 전용 m4 소스 및 향후 이미지 단계 추가. MM1 헤드폰/MM2 스피커/MM3 캡처/MM4 DP; stereo source→secondary TDM 8×32-bit. **현재 토폴로지 바이너리는 만들지 않았음** |
| PM8550B HV 진동 | ADB 입력 qcom-hv-haptics 및 SPMI 바인딩 확인. GPL HAP5xx backend, sine/rumble 호환, native FF playback worker, 모터1700 mV·5880 µs·brake ff/3f/1f·PMK SDAM9d00 연결 |
| AW86937 | 현재 기기에서 바인딩되지 않음. 사용되지 않는 Y700 드라이버를 활성 series/설정에서 제외; 원본 패치는 비활성 파일/히스토리로 보존 |
| LSM6DSO 가속도·자이로 | ADB sensorservice 확인. stock SSC JSON/동적 DSP 라이브러리·hexagonrpcd·libssc·IMU bridge 연결 |
| TCS3408 ALS/RGB | ADB 확인. SSC 구성과 iio-sensor-proxy 경로 연결; RGB 전용 사용자 인터페이스 미구현 |
| ADS610x0 근접/존재 감지 | ADB 확인. SSC 설정/라이브러리 준비; 표준 proximity는 proxy 경로, OEM presence/eyesafety/wake 정책 미구현 |
| BU52053NVX 덮개 Hall | ADB SSC 센서 확인. stock registry 포함; AP GPIO200을 중복 점유하지 않음. Linux SW_LID/덮개 정책은 미구현 |
| AW963xx SAR | ADB SSC 센서 확인. stock 설정 포함; SAR 이벤트→Wi-Fi 출력 제한 연동은 미구현 |
| 센서 가상 기능 | step/gravity/orientation 등 stock SSC 설정 보존. Android의 44개 센서가 Linux에서 모두 동일하게 노출된다는 뜻은 아님 |

## NFC·지문·카메라

- **NFC:** ADB qcom,sn-nci 및 /dev/nq-nci 확인. I2C0 @28, VEN34, IRQ75 high, CLKREQ35 입력 배선으로 mainline NXP NCI 기본 전송 경로를 연결했습니다. 현재 Android 시스템에도 NFC 서비스가 없으므로 서비스 동작을 증명하지 않습니다. eSE/TEE, NCI2 vendor 초기화·in-band 다운로드는 미구현입니다.
- **지문:** ADB Goodix platform driver 확인. L9B 3.0 V·reset91·IRQ92를 사용하는 전원/리셋/IRQ 제어 드라이버를 추가했습니다. 프로브 시 전원을 켜지 않습니다. `fingerprint-control` 장치의 `powered`(0/1), `reset`(1), `irq_count`(read/poll) sysfs는 bring-up용입니다. suspend 시 전원을 끕니다. Goodix TEE 프로토콜·센서 영상·libfprint·PAM 인증은 **미구현**이며 Android private ioctl/netlink를 Linux 인증으로 가장하지 않습니다.
- **카메라:** 3개 HAL 카메라와 CCI0/1 sensor0/1/2 바인딩은 확인했지만 `/sys/kernel/camera/subparts_info`는 SELinux로 읽을 수 없습니다. 공용 DT의 후보는 main LCE GC13A0 / TXD OV13B10, front LCE/TXD GC13A2, macro SC202CS입니다. WL2868C @2f·enable5가 바인딩되어 있습니다. CAMSS와 기존 OV13B10 모듈 설정은 준비했으나 **WL2868C regulator, 실제 센서별 power-up/register tables, endpoint/CSI 경로, autofocus, PMIC flash, 촬영·ISP 튜닝은 미완료**입니다. Android camera .so를 복사하는 것만으로 V4L2 드라이버가 되지 않아 활성 카메라 노드를 지어내지 않았습니다.

## 제거 범위

별도 보드의 DTS, SM8250/SM8550/SM8750/AYN/Ayaneo 전용 펌웨어, WCN7860/A830 전용 블롭을 overlay에서 제거했습니다. 활성 커널 패치에서는 다른 보드 패널/터치/내장 게임패드/RGB/PWM 등도 제외했습니다. 일반 Linux 공용 드라이버 전체를 삭제한 것은 아닙니다. 패치 적용에 필요한 선행 조건과 공용 SoC 기능, 확실하지 않은 외부 장치 지원은 유지합니다. 사용자가 파일명을 특정하지 못한 “703” 항목을 근거 없이 추가 삭제하지 않습니다.
