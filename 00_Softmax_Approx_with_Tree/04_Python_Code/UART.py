import serial
import time
import os

# --- Settings ---
SER_PORT = "COM3"
BAUD_RATE = 115200
TIMEOUT = 5
DEPTH_VAL = 12  # Depth value to send to FPGA first (0~255, 1 byte)

# File paths (Absolute paths recommended)
INPUT_FILE = r"C:\Users\PSH\DigitalCircuit\Softmax_Design\00_Softmax_Approx_with_Tree\07_top_module\input_1028b.hex"
OUTPUT_FILE = r"C:\Users\PSH\DigitalCircuit\Softmax_Design\00_Softmax_Approx_with_Tree\07_top_module\output_1028b.hex"


def main():
    # 1. Serial Port Connection
    try:
        ser = serial.Serial(SER_PORT, BAUD_RATE, timeout=TIMEOUT)
        print(f"Connected to {SER_PORT}")
    except Exception as e:
        print(f"Serial Error: {e}")
        return

    # 2. Read Input File
    try:
        with open(INPUT_FILE, "r") as f:
            lines = [line.strip() for line in f if line.strip()]
        print(f"Loaded {len(lines)} lines from input file.")
    except FileNotFoundError:
        print(f"Error: Input file not found at {INPUT_FILE}")
        return

    # 3. Data Transmission (Input -> FPGA)
    print("\nSending data to FPGA...")

    # 3-1. Send Depth byte first
    print(f"Sending Depth Value: {DEPTH_VAL}")
    ser.write(bytes([DEPTH_VAL]))
    time.sleep(0.02)  # Delay for stability

    # 3-2. Send Actual Data
    for i, hex_str in enumerate(lines):
        val = int(hex_str, 16)
        byte_array = val.to_bytes(129, byteorder="big")  # Sending 129 bytes
        ser.write(byte_array)
        time.sleep(0.02)  # Delay for stability
        if (i + 1) % 4 == 0:
            print(f"Sent {i + 1} lines...")

    print("Transmission Complete.")

    # 4. Data Reception (FPGA -> Output)
    expected_bytes = (DEPTH_VAL + 1) * 129
    print(f"\nWaiting for {expected_bytes} bytes from FPGA...")

    start_time = time.time()
    rx_bytes = ser.read(expected_bytes)
    end_time = time.time()

    if len(rx_bytes) != expected_bytes:
        print(f"Error: Received {len(rx_bytes)} bytes (Expected {expected_bytes})")
        ser.close()
        return

    print(f"Received successfully in {end_time - start_time:.2f}s")
    ser.close()

    # 5. Save to HEX File
    print(f"\nSaving to {OUTPUT_FILE}...")

    try:
        with open(OUTPUT_FILE, "w") as f:
            for i in range(DEPTH_VAL + 1):
                # Cut 129 bytes each
                chunk = rx_bytes[i * 129 : (i + 1) * 129]

                # Binary -> Hex string conversion (Uppercase)
                hex_str = chunk.hex().upper()

                # Write to file
                f.write(hex_str + "\n")

        print("File saved successfully!")

    except Exception as e:
        print(f"File Write Error: {e}")


if __name__ == "__main__":
    main()
