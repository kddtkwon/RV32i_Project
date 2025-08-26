🚀 RISC-V 32bit CPU 설계 (RV32I)

Single-Cycle → Multi-Cycle 기반의 RISC-V RV32I CPU 설계 및 검증 프로젝트
작성자: 권혁진 (AI시스템반도체 2기)

📌 프로젝트 개요

Architecture: RISC-V RV32I

Design Language: SystemVerilog, C, Assembly

Tools: Vivado, Visual Studio

목표

RV32I 명령어 셋 구현

Half / Byte 확장 (LB, LBU, LH, LHU 지원)

End-to-End C 코드 실행 및 서브루틴 호출 검증

🏗️ 설계 구조

FSM 기반 CPU

Single Cycle → Multi Cycle 구조 전환

Datapath & Control Unit 블록 다이어그램 설계

메모리 접근 확장

Word / Half / Byte 단위 Load-Store 지원

Instruction 구현

R, I, S, B, U, J 타입 전체 구현

<p align="center"> <img src="doc/block_diagram.png" width="500" alt="Block Diagram"/> </p>
✅ 명령어 검증
Type	검증 내용
R-Type	산술/논리 연산 확인
I-Type	즉시값 연산 검증
S-Type	메모리 Store 동작
L-Type	LB / LBU / LH / LHU 비교
B-Type	조건 분기 및 반복 루프
U-Type	LUI, AUIPC 검증
J-Type	JAL, JALR 점프 & 서브루틴 호출
<p align="center"> <img src="doc/waveform_rtype.png" width="600" alt="Waveform Example"/> </p>
🔎 Trouble Shooting

이슈: Sorting 프로그램 실행 시 이상 값 발생

원인: Simulation용 +10 코드가 datapath에 남아있었음

해결: 불필요한 코드 제거 → 정상 동작

📝 프로젝트 회고

하드웨어 설계에서 **작은 오류(대소문자, 비트수 불일치)**도 큰 버그로 이어짐

모듈이 많아질수록 Diagram 관리 난이도 증가

CPU 구현 과정에서 신중함과 디버깅의 중요성 체득

📂 Repository 구조
📦 RISC-V-CPU
 ┣ 📜 README.md
 ┣ 📂 src          # SystemVerilog 소스코드
 ┣ 📂 test         # Testbench 및 C/Assembly 코드
 ┣ 📂 sim          # Simulation 결과 (waveform 등)
 ┗ 📂 doc          # 블록 다이어그램 및 설계 문서

🎯 실행 예시
# RTL Simulation
vivado -source run_sim.tcl

# Testbench 실행
vsim -do tb_riscv.do

# C 코드 → Assembly 변환 후 실행
riscv32-unknown-elf-gcc test_sort.c -o sort.elf

🙏 감사의 말

CPU 설계 과정을 통해

아키텍처 구현의 복잡성과

디버깅의 중요성
을 깊이 체감할 수 있었습니다.
