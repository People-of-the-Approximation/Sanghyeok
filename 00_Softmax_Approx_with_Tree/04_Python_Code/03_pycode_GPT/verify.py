# verify.py
import numpy as np
import torch
import UART_base
from transformers import AutoTokenizer, AutoModelForCausalLM

import VerificationGPT as vgpt  # 위에서 만든 파일

DEVICE = "cpu"
MODEL_NAME = "gpt2"

# 모델 로드 및 패치
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
if tokenizer.pad_token is None:
    tokenizer.pad_token = tokenizer.eos_token

baseline_model = AutoModelForCausalLM.from_pretrained(MODEL_NAME).to(DEVICE).eval()
approx_model = AutoModelForCausalLM.from_pretrained(MODEL_NAME).to(DEVICE).eval()

# HW 모델의 Attention을 FPGA용으로 교체
vgpt.replace_gpt2_attention(approx_model, vgpt.GPT2AttentionSoftmaxApprox)


def generate_sw(text, max_len=128, gen_tokens=20):
    inputs = tokenizer(text, return_tensors="pt")
    with torch.no_grad():
        out = baseline_model.generate(
            inputs["input_ids"].to(DEVICE),
            max_new_tokens=gen_tokens,
            pad_token_id=tokenizer.eos_token_id,
            do_sample=False,
        )
    return tokenizer.decode(out[0], skip_special_tokens=True)


def generate_hw(text, max_len, gen_tokens, port, baud):
    """
    [수정됨] 2단계 생성 전략 (Hybrid)
    1. HW: 프롬프트 처리 + 첫 번째 토큰 생성 (FPGA 가속)
    2. SW: 시리얼 해제 후 나머지 토큰 생성 (CPU 고속 처리)
    """
    inputs = tokenizer(text, return_tensors="pt")
    input_ids = inputs["input_ids"].to(DEVICE)

    # 1. Serial Open
    ser = UART_base.open_serial(port, int(baud), timeout=1.0)

    try:
        # ====================================================
        # [Step 1] HW 가속 구간 (Prefill + 1st Token)
        # ====================================================
        vgpt.set_serial_to_model(approx_model, ser)

        with torch.no_grad():
            # 딱 1개 토큰만 생성 (여기서 FPGA가 프롬프트 행렬 연산 수행)
            out_1 = approx_model.generate(
                input_ids,
                max_new_tokens=1,
                pad_token_id=tokenizer.eos_token_id,
                do_sample=False,
            )

        # ====================================================
        # [Step 2] 연결 해제 (중요!)
        # ====================================================
        # 첫 토큰이 나왔으므로 FPGA 연결을 끊습니다.
        # 이제 approx_model은 일반 CPU 모델처럼 동작합니다.
        vgpt.set_serial_to_model(approx_model, None)
        try:
            ser.close()  # 물리적 포트 닫기
        except:
            pass
        ser = None  # finally 블록에서 중복 close 방지

        # ====================================================
        # [Step 3] SW 이어가기 (Decoding)
        # ====================================================
        remaining_tokens = gen_tokens - 1

        if remaining_tokens > 0:
            with torch.no_grad():
                # Step 1의 결과(out_1)를 이어서 생성
                out_final = approx_model.generate(
                    out_1,
                    max_new_tokens=remaining_tokens,
                    pad_token_id=tokenizer.eos_token_id,
                    do_sample=False,
                )
        else:
            out_final = out_1

        return tokenizer.decode(out_final[0], skip_special_tokens=True), None

    except Exception as e:
        return "", f"HW Generate Failed: {str(e)}"

    finally:
        # 안전장치: 혹시 중간에 에러나서 안 닫혔을 경우 대비
        if ser is not None:
            try:
                ser.close()
            except:
                pass
        vgpt.set_serial_to_model(approx_model, None)


def compute_hw_heatmap(text, layer, head, max_len, port, baud):
    # Heatmap은 프롬프트 전체에 대한 Attention이므로
    # 기존대로 한 번의 HW Forward Pass만 수행하면 됩니다.
    inputs = tokenizer(text, return_tensors="pt")
    tokens = [tokenizer.decode([t]) for t in inputs["input_ids"][0]]

    ser = UART_base.open_serial(port, int(baud), timeout=1.0)

    try:
        vgpt.set_serial_to_model(approx_model, ser)
        vgpt.set_force_store_attn_to_model(approx_model, True)

        with torch.no_grad():
            _ = approx_model(inputs["input_ids"].to(DEVICE))

        attn = vgpt.get_last_attention_matrix(approx_model, layer, head)
        if attn is None:
            attn = np.zeros((len(tokens), len(tokens)))

        return tokens, attn, None

    except Exception as e:
        return tokens, np.zeros((1, 1)), str(e)

    finally:
        try:
            ser.close()
        except:
            pass
        vgpt.set_serial_to_model(approx_model, None)
        vgpt.set_force_store_attn_to_model(approx_model, False)
