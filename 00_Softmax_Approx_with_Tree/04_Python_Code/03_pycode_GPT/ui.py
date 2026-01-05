# ui.py
import matplotlib

matplotlib.use("Agg")  # GUI 창 안 뜨게 설정 (서버용)
import matplotlib.pyplot as plt
import io
import base64
import numpy as np


def _attn_to_png_base64(attn):
    """
    Numpy 2D 배열(Attention Matrix)을 받아서
    PNG 이미지의 Base64 문자열로 반환하는 함수
    """
    if attn is None:
        return ""

    fig = plt.figure(figsize=(6, 6))
    ax = fig.add_subplot(111)

    # 히트맵 그리기
    cax = ax.imshow(attn, aspect="auto", interpolation="nearest", cmap="viridis")
    fig.colorbar(cax)

    # 축 제목 등 설정
    ax.set_title("Attention Heatmap (HW)")
    ax.set_xlabel("Key Token")
    ax.set_ylabel("Query Token")

    plt.tight_layout()

    # 메모리 버퍼에 저장
    buf = io.BytesIO()
    fig.savefig(buf, format="png", dpi=100)
    plt.close(fig)  # 메모리 해제

    buf.seek(0)
    img_base64 = base64.b64encode(buf.read()).decode("utf-8")
    return img_base64


def render_root():
    return """
    <html>
      <head>
        <title>GPT-2 HW Verification</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; text-align: center; }
          a { display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px; }
          a:hover { background: #0056b3; }
        </style>
      </head>
      <body>
        <h1>GPT-2 Hardware Verification System</h1>
        <p>FPGA-based Softmax Acceleration Demo</p>
        <br>
        <a href="/attention_ui">Go to Control Panel</a>
      </body>
    </html>
    """


def render_attention_ui(default_port: str, default_baud: int):
    return f"""
    <html>
      <head>
        <title>GPT Control Panel</title>
        <style>
          body {{ font-family: Arial; margin: 24px; max-width: 800px; margin: 0 auto; padding: 20px; }}
          h2 {{ border-bottom: 2px solid #eee; padding-bottom: 10px; }}
          .row {{ margin-top: 15px; display: flex; align-items: center; gap: 10px; }}
          input[type=text] {{ padding: 8px; border: 1px solid #ddd; border-radius: 4px; }}
          button {{ padding: 10px 20px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px; }}
          button:hover {{ background: #218838; }}
          .card {{ background: #f9f9f9; padding: 20px; border-radius: 8px; border: 1px solid #eee; margin-top: 20px; }}
          label {{ font-weight: bold; color: #555; }}
        </style>
      </head>
      <body>
        <h2>GPT-2 Generation & Attention</h2>
        
        <div class="card">
          <form method="post" action="/attention_generate">
            <div class="row">
              <input type="text" name="text" placeholder="Enter prompt (e.g., I love machine learning)" style="flex-grow: 1;" required />
            </div>
            
            <div class="row" style="background: #fff; padding: 10px; border: 1px solid #ddd;">
              <label>Port:</label>
              <input type="text" name="port" value="{default_port}" style="width:80px;" />
              
              <label>Baud:</label>
              <input type="text" name="baud" value="{default_baud}" style="width:100px;" />
              
              <div style="flex-grow:1;"></div>
              <button type="submit">Run Hardware Acceleration</button>
            </div>
          </form>
        </div>
        
        <div style="margin-top: 30px; color: #666; font-size: 0.9em;">
          ℹ️ <b>Note:</b> Make sure your FPGA board is connected and reset before clicking Run.
        </div>
      </body>
    </html>
    """


def render_result_page(
    *,
    input_text: str,
    sw_text: str,
    hw_text: str,
    heatmap_png_b64: str,
    error_hw: str,
):
    # 에러 메시지 HTML 처리
    error_html = ""
    if error_hw:
        error_html = f"""
        <div class="error-box">
          <strong>⚠️ Hardware Error:</strong> {error_hw}
        </div>
        """

    # 히트맵 이미지 HTML 처리
    heatmap_html = ""
    if heatmap_png_b64:
        heatmap_html = f'<img src="data:image/png;base64,{heatmap_png_b64}" alt="Attention Heatmap" />'
    else:
        heatmap_html = '<div style="padding:40px; background:#eee; color:#999;">No Heatmap Available</div>'

    return f"""
    <html>
      <head>
        <title>Generation Result</title>
        <style>
          body {{ font-family: Arial; margin: 24px; max-width: 1000px; margin: 0 auto; padding: 20px; }}
          h2 {{ border-bottom: 2px solid #eee; padding-bottom: 10px; }}
          .box {{ margin-bottom: 20px; border: 1px solid #ddd; border-radius: 8px; overflow: hidden; }}
          .box-header {{ background: #f1f1f1; padding: 10px 15px; font-weight: bold; border-bottom: 1px solid #ddd; }}
          .box-content {{ padding: 15px; background: #fff; white-space: pre-wrap; }}
          .error-box {{ background: #fff3f3; color: #d9534f; padding: 15px; border: 1px solid #ebccd1; border-radius: 4px; margin-bottom: 20px; }}
          img {{ max-width: 100%; height: auto; display: block; margin: 0 auto; }}
          .btn {{ display: inline-block; padding: 10px 20px; background: #6c757d; color: white; text-decoration: none; border-radius: 5px; }}
          .btn:hover {{ background: #5a6268; }}
        </style>
      </head>
      <body>
        <h2>Generation Result</h2>
        
        {error_html}

        <div class="box">
          <div class="box-header">Input Prompt</div>
          <div class="box-content">{input_text}</div>
        </div>

        <div style="display: flex; gap: 20px;">
          <div class="box" style="flex: 1;">
            <div class="box-header">Software (CPU) Generation</div>
            <div class="box-content" style="background:#f9fff9;">{sw_text}</div>
          </div>
          
          <div class="box" style="flex: 1;">
            <div class="box-header">Hardware (FPGA) Generation</div>
            <div class="box-content" style="background:#fff9f9;">{hw_text}</div>
          </div>
        </div>

        <div class="box">
          <div class="box-header">Hardware Attention Heatmap (Layer 0, Head 0)</div>
          <div class="box-content" style="text-align: center;">
            {heatmap_html}
          </div>
        </div>

        <a href="/attention_ui" class="btn">Try Another Prompt</a>
      </body>
    </html>
    """
