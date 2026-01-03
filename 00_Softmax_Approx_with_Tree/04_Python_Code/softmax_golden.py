import numpy as np


# ==========================================
# 1. Hex to Float (Q6.10) 변환 함수
# ==========================================
def hex_to_q6_10(hex_str):
    val = int(hex_str, 16)
    if val & 0x8000:  # 2's Complement (음수 처리)
        val -= 0x10000
    return val / 1024.0


# ==========================================
# 2. 그룹별 Softmax 계산 로직
# ==========================================
import numpy as np


def grouped_softmax(data_flat, group_size):
    """
    group_size에 맞춰 Softmax를 계산.
    입력 데이터보다 group_size가 크면, 데이터가 반복된다고 가정하고 확장하여 계산.
    """
    data_np = np.array(data_flat)
    input_len = len(data_np)  # 보통 64

    # ---------------------------------------------------------
    # Case A: 그룹 사이즈가 입력 데이터보다 큰 경우 (Mode 3, 4, 5)
    # -> 데이터를 복사해서 늘린 뒤, 전체에 대해 Softmax 수행
    # ---------------------------------------------------------
    if group_size > input_len:
        # 몇 번 반복해야 group_size를 채울 수 있는지 계산
        # 예: 64개 입력, 목표 128 -> 2번 반복
        repeat_cnt = (group_size + input_len - 1) // input_len

        # 데이터 확장 (Tiling) 후 목표 사이즈만큼 자르기
        extended_data = np.tile(data_np, repeat_cnt)[:group_size]

        # 확장된 데이터로 Softmax 계산
        # (분모가 커지므로 확률값은 작아짐)
        shift_x = extended_data - np.max(extended_data)
        exps = np.exp(shift_x)
        probs = exps / np.sum(exps)

        # 하드웨어 출력 비교를 위해, 원래 입력 개수(64개)에 해당하는 부분만 반환
        return probs[:input_len]

    # ---------------------------------------------------------
    # Case B: 그룹 사이즈가 입력 데이터보다 작거나 같은 경우 (Mode 0, 1, 2)
    # -> 데이터를 쪼개서 각 그룹별로 Softmax 수행
    # ---------------------------------------------------------
    else:
        num_groups = input_len // group_size
        reshaped = data_np.reshape(num_groups, group_size)
        result = []

        for group in reshaped:
            shift_x = group - np.max(group)
            exps = np.exp(shift_x)
            sum_exps = np.sum(exps)

            if sum_exps == 0:
                result.extend(np.zeros_like(exps))
            else:
                result.extend(exps / sum_exps)

        return np.array(result)


# ==========================================
# 3. 데이터 패턴 생성 (8개 패턴 반복)
# ==========================================
# 기본 패턴 8개
p0 = ["061D", "061D", "FDE2", "0B13", "FBCF", "0B26", "042B", "F5BE"]
p1 = ["FA60", "042D", "FFBF", "F46A", "0A79", "F8B9", "FBCC", "F55D"]
p2 = ["00F7", "0AC0", "0A99", "09D6", "FF4D", "F72D", "FF90", "0B2A"]

p0.reverse()
p1.reverse()
p2.reverse()

# 64개로 확장 ({8{...}} 동작)
my_x_0 = [hex_to_q6_10(x) for x in p0 * 8]
my_x_1 = [hex_to_q6_10(x) for x in p1 * 8]
my_x_2 = [hex_to_q6_10(x) for x in p2 * 8]

data_map = {
    "my_x_0": my_x_0,
    "my_x_1": my_x_1,
    "my_x_2": my_x_2,
}

# ==========================================
# 4. 정정해주신 Mode -> Size 매핑
# ==========================================
MODE_SIZE_MAP = {
    0: 16,  # 16개씩 4그룹
    1: 32,  # 32개씩 2그룹
    2: 64,  # 64개씩 1그룹
    3: 128,  # (입력 64개이므로 Global 64로 동작 예상)
    4: 192,  # (위와 동일)
    5: 256,  # (위와 동일)
}

# ==========================================
# 5. Testbench 시퀀스 실행
# ==========================================
# 사용자가 제공한 코드의 순서 그대로 작성
sequence = [
    # Mode 0 (Size 16)
    ("my_x_0", 0),
    ("my_x_1", 0),
    ("my_x_2", 0),
    # Mode 1 (Size 32)
    ("my_x_0", 1),
    ("my_x_1", 1),
    ("my_x_2", 1),
    # Mode 2 (Size 64)
    ("my_x_0", 2),
    ("my_x_1", 2),
    ("my_x_2", 2),
    # Mode 3 (Size 128)
    ("my_x_0", 3),
    ("my_x_1", 3),
    # Mode 4 (Size 192)
    ("my_x_0", 4),
    ("my_x_1", 4),
    ("my_x_2", 4),
    # Mode 5 (Size 256)
    ("my_x_0", 5),
    ("my_x_1", 5),
    ("my_x_2", 5),
    ("my_x_0", 5),
]

print(
    f"{'SEQ':<4}| {'Data':<7} | {'Mode':<4} | {'TargetSize':<10} | {'Max Prob Index':<15} | {'Max Prob Value'}"
)
print("-" * 80)

for i, (d_name, mode) in enumerate(sequence):
    data = data_map[d_name]
    size = MODE_SIZE_MAP[mode]

    # Softmax 계산
    probs = grouped_softmax(data, size)
    print()
    for i in range(len(probs)):
        print(f"{probs[i]:.6f}", end=" ")
        if i % 8 == 7:
            print()
