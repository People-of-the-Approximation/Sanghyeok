# VerificationGPT.py
from __future__ import annotations
from typing import Optional, Tuple
import torch
import numpy as np
from transformers.models.gpt2.modeling_gpt2 import GPT2Attention

# [핵심] BERT 프로젝트에서 검증된 배치 전송 모듈 사용
from Attention_approx import softmax_FPGA_UART_batch


class GPT2AttentionSoftmaxApprox(GPT2Attention):
    """
    BERT 프로젝트의 UART 통신 구조를 GPT-2에 이식한 클래스
    Q6.10 Overflow 방지 및 Causal Masking(미래 참조 방지) 로직 포함
    """

    def __init__(self, config, is_cross_attention=False, layer_idx=None):
        try:
            super().__init__(
                config, is_cross_attention=is_cross_attention, layer_idx=layer_idx
            )
        except TypeError:
            super().__init__(config, is_cross_attention=is_cross_attention)

        self.ser = None
        self.last_attn: Optional[np.ndarray] = None
        self.force_store_attn: bool = False
        self.pad_value = -32.0

    def set_serial(self, ser):
        self.ser = ser

    def set_force_store_attn(self, flag: bool):
        self.force_store_attn = bool(flag)

    @staticmethod
    def _shape_qkv(x: torch.Tensor, num_heads: int, head_dim: int) -> torch.Tensor:
        B, T, _ = x.shape
        return x.view(B, T, num_heads, head_dim).permute(0, 2, 1, 3).contiguous()

    def forward(
        self,
        hidden_states,
        past_key_value=None,
        attention_mask=None,
        head_mask=None,
        encoder_hidden_states=None,
        encoder_attention_mask=None,
        use_cache=False,
        output_attentions=False,
        **kwargs,
    ):
        qkv = self.c_attn(hidden_states)
        query, key, value = qkv.split(self.split_size, dim=2)
        query = self._shape_qkv(query, self.num_heads, self.head_dim)
        key = self._shape_qkv(key, self.num_heads, self.head_dim)
        value = self._shape_qkv(value, self.num_heads, self.head_dim)

        if past_key_value is not None:
            past_key, past_value = past_key_value
            key = torch.cat([past_key, key], dim=2)
            value = torch.cat([past_value, value], dim=2)

        present = (key, value) if use_cache else None

        # 1. Score 계산 (Dot Product)
        attn_weights = torch.matmul(query, key.transpose(-1, -2))
        scale_factor = torch.tensor(
            value.size(-1) ** -0.5, dtype=attn_weights.dtype, device=attn_weights.device
        )
        attn_weights = attn_weights * scale_factor

        # 2. [중요] Causal Mask 적용 (미래 토큰 가리기)
        # GPT는 자기 자신과 과거만 봐야 합니다. 이 로직이 없으면 프롬프트 처리 시 문맥이 깨집니다.
        Tq = query.size(-2)
        Tk = key.size(-2)

        # self.bias는 상속받은 GPT2Attention에 이미 정의되어 있습니다 (Lower triangular matrix)
        # causal_mask: 현재 시점 이후의 토큰 위치를 True로 표시
        causal_mask = self.bias[:, :, Tk - Tq : Tk, :Tk].bool()

        # 미래 토큰의 점수를 매우 낮은 값(-1e4)으로 설정하여 Softmax에서 0이 되게 함
        mask_value = torch.tensor(
            -32, dtype=attn_weights.dtype, device=attn_weights.device
        )
        attn_weights = torch.where(causal_mask, attn_weights, mask_value)

        # 3. Padding Mask 적용 (User Input Mask)
        if attention_mask is not None:
            attn_weights = attn_weights + attention_mask

        want_attn = output_attentions or self.force_store_attn

        # 4. 하드웨어 가속 분기 (길이 64 이하일 때만)
        if (self.ser is not None) and (Tk <= 64):
            # === HW 가속 시작 ===
            attn_np = attn_weights.detach().cpu().numpy().astype(np.float64)

            # [Step A] Overflow 방지: 최댓값 빼기
            # 이미 Causal Mask로 미래 토큰은 -10000이 되어 있으므로 max 계산에서 제외됨
            max_val = np.max(attn_np, axis=-1, keepdims=True)
            attn_np = attn_np - max_val

            # [Step B] Underflow 방지: -32.0 하한선 (Clipping)
            # FPGA 포맷(Q6.10)의 한계에 맞춤. 마스킹된 미래 토큰들도 -32로 고정됨.
            attn_np = np.maximum(attn_np, -32.0)

            B, H, Tq, _ = attn_np.shape

            # 리스트로 펼쳐서 배치 전송 (BERT 방식)
            seqs_flat = []
            for b in range(B):
                for h in range(H):
                    for i in range(Tq):
                        seqs_flat.append(attn_np[b, h, i, :])

            try:
                probs_flat = softmax_FPGA_UART_batch(
                    self.ser, seqs_flat, pad_value=self.pad_value, deadline_s=10.0
                )
                probs_np = np.array(probs_flat).reshape(B, H, Tq, Tk)
                attn_weights = torch.tensor(
                    probs_np, dtype=query.dtype, device=query.device
                )
            except Exception as e:
                print(f"HW Fail: {e}")
                attn_weights = torch.softmax(attn_weights, dim=-1)
        else:
            # SW 수행 (Tk > 64 이거나 Serial 없을 때)
            attn_weights = torch.softmax(attn_weights, dim=-1)

        attn_probs = self.attn_dropout(attn_weights)
        attn_output = torch.matmul(attn_probs, value)

        attn_output = attn_output.permute(0, 2, 1, 3).contiguous()
        new_shape = attn_output.size()[:-2] + (self.num_heads * self.head_dim,)
        attn_output = attn_output.view(*new_shape)

        attn_output = self.c_proj(attn_output)
        attn_output = self.resid_dropout(attn_output)

        if want_attn:
            self.last_attn = attn_weights.detach().cpu().numpy()

        outputs = (attn_output, present)
        if output_attentions:
            outputs += (attn_weights,)

        return outputs


# =================================================================
# [필수] 도우미 함수들
# =================================================================


def replace_gpt2_attention(model, NewAttnClass):
    if not hasattr(model, "transformer"):
        return
    for idx, block in enumerate(model.transformer.h):
        old_attn = block.attn
        try:
            new_attn = NewAttnClass(
                model.config, is_cross_attention=False, layer_idx=idx
            )
        except TypeError:
            new_attn = NewAttnClass(model.config, is_cross_attention=False)
        new_attn.load_state_dict(old_attn.state_dict(), strict=True)
        block.attn = new_attn


def set_serial_to_model(model, ser):
    if not hasattr(model, "transformer"):
        return
    for block in model.transformer.h:
        if hasattr(block.attn, "set_serial"):
            block.attn.set_serial(ser)


def set_force_store_attn_to_model(model, flag):
    if not hasattr(model, "transformer"):
        return
    for block in model.transformer.h:
        if hasattr(block.attn, "set_force_store_attn"):
            block.attn.set_force_store_attn(flag)


def get_last_attention_matrix(model, layer=0, head=0):
    attn = model.transformer.h[layer].attn
    if not hasattr(attn, "last_attn") or attn.last_attn is None:
        return None
    return attn.last_attn[0, head]
