import numpy as np

# 파일 읽기
with open("sst2_token_lengths.txt") as f:
    lengths = [int(line.strip()) for line in f]

lengths = np.array(lengths)
N = len(lengths)

# 평균 길이
print("평균 길이:", np.mean(lengths))

# 구간별 비율
p16 = np.sum((lengths >= 1) & (lengths <= 16)) / N
p32 = np.sum((lengths >= 17) & (lengths <= 32)) / N
p64 = np.sum((lengths >= 33) & (lengths <= 64)) / N

print(f"p16={p16:.4f}, p32={p32:.4f}, p64={p64:.4f}")

# 정규화 처리량
Tnorm = 4 * p16 + 2 * p32 + 1 * p64
print("Normalized Throughput =", Tnorm, "x baseline")
