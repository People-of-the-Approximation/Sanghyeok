import numpy as np
import serial
import time
from UART_base import build_softmax_frame, send_exact, read_exact, q610_bytes_to_floats

# FPGA BRAM이 수용 가능한 최대 프레임(행) 수 (하드웨어상 0~255까지 가능하지만 안전하게 64로 설정)
FPGA_MAX_FRAME_DEPTH = 128


def _pack_params(L: int):
    """
    길이 L에 따라 한 프레임(64개)에 몇 개의 시퀀스를 넣을지 결정
    """
    if not (1 <= L <= 64):
        raise ValueError("Length must be between 1 and 64.")
    if L <= 16:
        return 16, 4  # 블록 크기 16, 한 프레임에 4개 (Mode 0)
    elif L <= 32:
        return 32, 2  # 블록 크기 32, 한 프레임에 2개 (Mode 1)
    else:
        return 64, 1  # 블록 크기 64, 한 프레임에 1개 (Mode 2)


def softmax_FPGA_UART_batch(
    ser: serial.Serial,
    scores_list,
    *,
    pad_value: float = -32.0,
    deadline_s: float = 5.0
):
    seqs = [np.asarray(s, dtype=np.float64) for s in scores_list]
    if not seqs:
        return []

    # 모든 시퀀스 길이가 동일하다고 가정 (Self-Attention 특징)
    L = int(seqs[0].shape[0])
    if any(int(s.shape[0]) != L for s in seqs):
        raise ValueError("All sequences must have the same length.")

    # 1. 패킹 전략 수립 (사용자님의 의도대로 작동)
    block_size, max_pack = _pack_params(L)

    # FPGA Mode 값 결정 (헤더로 전송됨)
    if L <= 16:
        mode_val = 0
    elif L <= 32:
        mode_val = 1
    else:
        mode_val = 2

    # 2. 데이터 패킹 (Packing) -> 프레임(Payload) 생성
    payloads = []
    meta_info = []  # 나중에 결과를 풀 때, 이 프레임에 몇 개가 유효했는지 기록

    # max_pack 단위로 시퀀스를 잘라서 프레임에 담음
    for off in range(0, len(seqs), max_pack):
        chunk = seqs[off : off + max_pack]
        G = len(chunk)  # 실제 채워진 개수 (마지막 프레임은 max_pack보다 적을 수 있음)

        # 64개짜리 빈 캔버스 생성 (패딩 값으로 초기화)
        payload = np.full(64, pad_value, dtype=np.float64)

        # 차곡차곡 채워 넣기
        for g, vec in enumerate(chunk):
            start = g * block_size
            payload[start : start + L] = vec

        payloads.append(payload)
        meta_info.append(G)

    # 3. 프레임 전송 및 결과 수신 (Batch Processing)
    final_results = []

    # 생성된 프레임이 많을 경우, FPGA 메모리 한계(FPGA_MAX_FRAME_DEPTH)만큼 끊어서 처리
    for i in range(0, len(payloads), FPGA_MAX_FRAME_DEPTH):
        batch_payloads = payloads[i : i + FPGA_MAX_FRAME_DEPTH]
        batch_meta = meta_info[i : i + FPGA_MAX_FRAME_DEPTH]

        # 이번에 보낼 프레임 개수
        num_frames_to_send = len(batch_payloads)

        # [중요] Depth 전송: (보낼 프레임 수 - 1)
        # 예: 28개 데이터 -> 14 프레임 -> Depth 13 전송
        depth_byte = num_frames_to_send - 1
        ser.write(bytes([depth_byte]))
        time.sleep(0.001)  # FPGA 준비 대기

        # 프레임 연속 전송
        for payload in batch_payloads:
            frame = build_softmax_frame(payload, header_val=mode_val, endian="big")
            ser.write(frame)

        # 결과 수신 (보낸 프레임 수만큼 129바이트씩 수신)
        expected_bytes = num_frames_to_send * 129
        rx_data = read_exact(ser, expected_bytes, deadline_s=deadline_s)

        # 결과 파싱 및 언패킹 (Unpacking)
        for row_idx in range(num_frames_to_send):
            # 129바이트 잘라내기
            chunk_bytes = rx_data[row_idx * 129 : (row_idx + 1) * 129]

            # 실수 변환 (129바이트 -> 64 floats)
            probs64 = q610_bytes_to_floats(chunk_bytes, endian="big")

            # 한 프레임에 묶여 있던 여러 결과를 다시 분리
            num_seqs_in_row = batch_meta[row_idx]
            for g in range(num_seqs_in_row):
                start = g * block_size
                # 유효한 데이터 부분만 잘라서 결과 리스트에 추가
                final_results.append(
                    np.asarray(probs64[start : start + L], dtype=np.float64)
                )

    return final_results


def attention(
    Q, K, V, ser: serial.Serial, *, pad_value: float = -32.0, deadline_s: float = 5.0
):
    Q = np.asarray(Q, dtype=np.float64)
    K = np.asarray(K, dtype=np.float64)
    V = np.asarray(V, dtype=np.float64)

    Nq, d_kq = Q.shape
    Nk, d_kk = K.shape
    Nv, d_kv = V.shape

    assert Nq == Nk and d_kq == d_kk, "Dim Error: Q,K mismatch"
    assert Nv == Nk, "Dim Error: V rows must match K rows"
    assert 1 <= Nk <= 64, "Length N must be between 1 and 64."

    d_k = d_kq

    # 1. Score 계산 (CPU)
    # Self-Attention에서는 Nq == Nk == N 입니다.
    # N=28 이라면 S_matrix는 (28, 28) 크기가 됩니다.
    S_matrix = (Q @ K.T) / np.sqrt(d_k)

    # 2. 리스트 변환 (28개의 벡터가 담긴 리스트 생성)
    seqs = [S_matrix[i, :] for i in range(Nq)]

    # 3. FPGA 가속 (패킹 -> 배치 전송 -> 소프트맥스 -> 언패킹)
    # 내부적으로 2개씩 묶어서 14번 보내는 작업이 여기서 자동으로 수행됩니다.
    probs_list = softmax_FPGA_UART_batch(
        ser, seqs, pad_value=pad_value, deadline_s=deadline_s
    )

    # 4. 결과 합치기
    F = np.vstack(probs_list)

    # 5. Output 계산 (CPU)
    outputs = F @ V

    return outputs
