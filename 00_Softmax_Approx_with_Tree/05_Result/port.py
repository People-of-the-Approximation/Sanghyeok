import serial.tools.list_ports

ports = serial.tools.list_ports.comports()

if not ports:
    print("연결된 시리얼 포트가 없습니다. 케이블을 확인하세요.")
else:
    print("--- 사용 가능한 포트 목록 ---")
    for port, desc, hwid in ports:
        print(f"{port}: {desc}")
