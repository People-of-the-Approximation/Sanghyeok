# app.py
from fastapi import FastAPI, Form
from fastapi.responses import HTMLResponse
import ui
import verify
import numpy as np
import matplotlib

matplotlib.use("Agg")  # GUI 경고 방지

app = FastAPI()

DEFAULT_PORT = "COM3"
DEFAULT_BAUD = 115200


@app.get("/attention_ui", response_class=HTMLResponse)
def attention_ui():
    return HTMLResponse(ui.render_attention_ui(DEFAULT_PORT, DEFAULT_BAUD))


@app.post("/attention_generate", response_class=HTMLResponse)
def attention_generate(
    text: str = Form(...),
    port: str = Form(DEFAULT_PORT),
    baud: int = Form(DEFAULT_BAUD),
):
    # SW
    try:
        sw_text = verify.generate_sw(text)
    except Exception as e:
        sw_text = f"Error: {e}"

    # HW
    hw_text, error_hw = verify.generate_hw(text, 128, 20, port, baud)
    if error_hw:
        hw_text = f"(Failed) {error_hw}"

    # Heatmap
    tokens, attn, hm_err = verify.compute_hw_heatmap(text, 0, 0, 128, port, baud)
    heatmap_b64 = ui._attn_to_png_base64(attn)

    # 에러 메시지 통합
    full_error = ""
    if error_hw:
        full_error += f"Gen Error: {error_hw} | "
    if hm_err:
        full_error += f"Heatmap Error: {hm_err}"

    return HTMLResponse(
        ui.render_result_page(
            input_text=text,
            sw_text=sw_text,
            hw_text=hw_text,
            heatmap_png_b64=heatmap_b64,
            error_hw=full_error,
        )
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
