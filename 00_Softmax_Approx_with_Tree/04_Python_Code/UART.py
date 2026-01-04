import serial
import time
import os

# --- 설정 ---
SER_PORT = "COM3"
BAUD_RATE = 115200
TIMEOUT = 10

# 파일 경로 (절대 경로 권장)
# 입력 파일 (읽기용)
INPUT_FILE = r"C:\Users\PSH\DigitalCircuit\Softmax_Design\00_Softmax_Approx_with_Tree\07_top_module\input_1028b.hex"
# 출력 파일 (저장용) - 여기에 결과가 저장됩니다.
OUTPUT_FILE = r"C:\Users\PSH\DigitalCircuit\Softmax_Design\00_Softmax_Approx_with_Tree\07_top_module\output_1028b.hex"


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
    for i, hex_str in enumerate(lines):
        val = int(hex_str, 16)
        byte_array = val.to_bytes(129, byteorder="big")  # 129 bytes sending
        ser.write(byte_array)
        time.sleep(0.02)  # 안정성을 위한 딜레이

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
                # chunk.hex()는 바이트를 '5013e0...' 같은 문자열로 바꿔줍니다.
                hex_str = chunk.hex().upper()

                # 3. 파일에 쓰기
                f.write(hex_str + "\n")

        print("✅ File saved successfully!")

    except Exception as e:
        print(f"❌ File Write Error: {e}")


if __name__ == "__main__":
    main()
