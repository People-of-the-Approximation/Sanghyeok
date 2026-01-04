import serial
import time
import os

# --- 설정 ---
SER_PORT = "COM3"
BAUD_RATE = 115200
TIMEOUT = 10
DEPTH_VAL = 11  # [추가] FPGA로 먼저 보낼 Depth 값 (0~255, 1바이트)

# 파일 경로 (절대 경로 권장)
INPUT_FILE = r"C:\Users\PSH\DigitalCircuit\Softmax_Design\00_Softmax_Approx_with_Tree\07_top_module\input_1028b.hex"
OUTPUT_FILE = r"C:\Users\PSH\DigitalCircuit\Softmax_Design\00_Softmax_Approx_with_Tree\07_top_module\output_1028b_2.hex"


def main():
    # 1. 시리얼 포트 연결
    try:
        ser = serial.Serial(SER_PORT, BAUD_RATE, timeout=TIMEOUT)
        print(f"✅ Connected to {SER_PORT}")
    except Exception as e:
        print(f"❌ Serial Error: {e}")
        return

    # 2. 입력 파일 읽기
    try:
        with open(INPUT_FILE, "r") as f:
            lines = [line.strip() for line in f if line.strip()]
        print(f"📖 Loaded {len(lines)} lines from input file.")
    except FileNotFoundError:
        print(f"❌ Error: Input file not found at {INPUT_FILE}")
        return

    # 3. 데이터 전송 (Input -> FPGA)
    print("\n📤 Sending data to FPGA...")

    # [수정] 3-1. Depth 1바이트 먼저 전송
    print(f"   Sending Depth Value: {DEPTH_VAL}")
    ser.write(bytes([DEPTH_VAL]))
    time.sleep(0.02)  # 안정성을 위한 딜레이

    # 3-2. 실제 데이터 전송
    for i, hex_str in enumerate(lines):
        val = int(hex_str, 16)
        byte_array = val.to_bytes(129, byteorder="big")  # 129 bytes sending
        ser.write(byte_array)
        time.sleep(0.02)  # 안정성을 위한 딜레이
        if (i + 1) % 4 == 0:
            print(f"   Sent {i + 1} lines...")

    print("✅ Transmission Complete.")

    # 4. 데이터 수신 (FPGA -> Output)
    expected_bytes = 12 * 129
    print(f"\n📥 Waiting for {expected_bytes} bytes from FPGA...")

    start_time = time.time()
    rx_bytes = ser.read(expected_bytes)
    end_time = time.time()

    if len(rx_bytes) != expected_bytes:
        print(f"❌ Error: Received {len(rx_bytes)} bytes (Expected {expected_bytes})")
        ser.close()
        return

    print(f"✅ Received successfully in {end_time - start_time:.2f}s")
    ser.close()

    # 5. HEX 파일로 저장
    print(f"\n💾 Saving to {OUTPUT_FILE}...")

    try:
        with open(OUTPUT_FILE, "w") as f:
            for i in range(12):
                # 1. 129바이트씩 자르기
                chunk = rx_bytes[i * 129 : (i + 1) * 129]

                # 2. 바이너리 -> Hex 문자열 변환 (대문자)
                hex_str = chunk.hex().upper()

                # 3. 파일에 쓰기
                f.write(hex_str + "\n")

        print("✅ File saved successfully!")

    except Exception as e:
        print(f"❌ File Write Error: {e}")


if __name__ == "__main__":
    main()
