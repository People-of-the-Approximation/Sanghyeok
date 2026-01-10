# app.py
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from contextlib import asynccontextmanager
import torch
import time
import asyncio
import serial

# 기존 모듈 임포트
from softmax_batch import open_serial, close_serial
from VerificationBERT import build_model_BERT
from VerificationGPT2 import build_model_GPT2

# --- 설정 ---
SERIAL_PORT = "COM3"
BAUD_RATE = 115200
TIMEOUT = 1.0

# 전역 변수 저장소 (모델 및 시리얼 객체)
models = {}
hardware_lock = asyncio.Lock()  # 시리얼 포트 동시 접근 방지


# --- Lifespan (시작/종료 시 실행) ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. 시작 시: 시리얼 연결 및 모델 로드
    print(f"[System] Opening serial port {SERIAL_PORT}...")
    try:
        ser = open_serial(SERIAL_PORT, baud=BAUD_RATE, timeout=TIMEOUT)
    except Exception as e:
        print(f"[Error] Failed to open serial port: {e}")
        # 데모를 위해 에러가 나도 서버는 켜지게 하되, ser는 None
        ser = None

    if ser:
        print("[System] Building BERT model...")
        tok_bert, base_bert, approx_bert, dev_bert = build_model_BERT(ser)

        print("[System] Building GPT-2 model...")
        tok_gpt2, base_gpt2, approx_gpt2, dev_gpt2 = build_model_GPT2(ser)

        models["ser"] = ser
        models["bert"] = (tok_bert, base_bert, approx_bert, dev_bert)
        models["gpt2"] = (tok_gpt2, base_gpt2, approx_gpt2, dev_gpt2)
        models["sst2_labels"] = {0: "NEGATIVE", 1: "POSITIVE"}
        print("[System] Ready!")

    yield  # 서버 실행 중

    # 2. 종료 시: 시리얼 닫기
    if models.get("ser"):
        print("[System] Closing serial port...")
        close_serial(models["ser"])


app = FastAPI(lifespan=lifespan)
templates = Jinja2Templates(directory="templates")


# --- 데이터 모델 ---
class InferenceRequest(BaseModel):
    text: str
    model_type: str  # "bert" or "gpt2"


# --- 라우터 ---


@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.post("/predict")
async def predict(req: InferenceRequest):
    if "ser" not in models:
        raise HTTPException(status_code=500, detail="Serial port not connected")

    text = req.text.strip()
    if not text:
        return {"error": "Empty text"}

    async with hardware_lock:
        if req.model_type == "bert":
            return process_bert(text)
        elif req.model_type == "gpt2":
            return process_gpt2(text)
        else:
            return {"error": "Invalid model type"}


def process_bert(text):
    tokenizer, base_model, approx_model, device = models["bert"]
    labels = models["sst2_labels"]

    inputs = tokenizer(text, return_tensors="pt", truncation=True).to(device)

    # Baseline (CPU)
    start_t = time.time()
    with torch.no_grad():
        out_base = base_model(**inputs).logits
    base_time = time.time() - start_t
    pred_base = out_base.argmax(dim=-1).item()

    # Approx (Hardware)
    start_t = time.time()
    with torch.no_grad():
        out_approx = approx_model(**inputs).logits
    approx_time = time.time() - start_t
    pred_approx = out_approx.argmax(dim=-1).item()

    base_res = labels.get(pred_base, "Unknown")
    approx_res = labels.get(pred_approx, "Unknown")

    return {
        "model": "BERT (SST-2)",
        "baseline_result": f"{base_res} ({pred_base})",
        "baseline_time": f"{base_time:.4f}s",
        "approx_result": f"{approx_res} ({pred_approx})",
        "approx_time": f"{approx_time:.4f}s",
        "match": pred_base == pred_approx,
    }


def process_gpt2(text):
    tokenizer, base_model, approx_model, device = models["gpt2"]

    input_ids = tokenizer.encode(text, return_tensors="pt").to(device)
    attention_mask = torch.ones_like(input_ids).to(device)

    # Baseline (CPU)
    start_t = time.time()
    out_base = base_model.generate(
        input_ids,
        attention_mask=attention_mask,
        max_new_tokens=10,
        num_return_sequences=1,
        do_sample=False,
        pad_token_id=tokenizer.eos_token_id,
        use_cache=False,
    )
    base_time = time.time() - start_t
    text_base = tokenizer.decode(out_base[0], skip_special_tokens=True)

    # Approx (Hardware)
    start_t = time.time()
    try:
        out_approx = approx_model.generate(
            input_ids,
            attention_mask=attention_mask,
            max_new_tokens=10,
            num_return_sequences=1,
            do_sample=False,
            pad_token_id=tokenizer.eos_token_id,
            use_cache=False,
        )
        approx_time = time.time() - start_t
        text_approx = tokenizer.decode(out_approx[0], skip_special_tokens=True)
    except Exception as e:
        text_approx = f"Error: {str(e)}"
        approx_time = 0.0

    return {
        "model": "GPT-2 Generation",
        "baseline_result": text_base,
        "baseline_time": f"{base_time:.4f}s",
        "approx_result": text_approx,
        "approx_time": f"{approx_time:.4f}s",
        "match": text_base == text_approx,
    }


if __name__ == "__main__":
    import uvicorn

    # 0.0.0.0으로 열면 외부 접속 가능, 로컬은 127.0.0.1
    uvicorn.run(app, host="127.0.0.1", port=8000)
