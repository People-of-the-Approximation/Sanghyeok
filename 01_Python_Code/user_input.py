import time
import torch
from softmax_batch import open_serial, close_serial
from VerificationBERT import build_model_BERT
from VerificationGPT2 import build_model_GPT2


def main():
    SERIAL_PORT = "COM3"
    BAUD_RATE = 115200
    TIMEOUT = 1.0

    print(f"Opening serial port {SERIAL_PORT} at {BAUD_RATE} baud...")
    try:
        ser = open_serial(SERIAL_PORT, baud=BAUD_RATE, timeout=TIMEOUT)
    except Exception as e:
        print(f"Failed to open serial port: {e}")
        return

    print("[Init] Building BERT model...")
    tokenizer_bert, base_bert, approx_bert, dev_bert = build_model_BERT(ser)
    print("[Init] Building GPT-2 model...")
    tokenizer_gpt2, base_gpt2, approx_gpt2, dev_gpt2 = build_model_GPT2(ser)

    print("=" * 60)
    print(" AI Hardware Verification System Ready")
    print(" BERT: Sentiment Analysis (SST-2)")
    print(" GPT-2: Text Generation")
    print(" Type 'exit' to quit.")
    print("=" * 60)

    sst2_labels = {0: "NEGATIVE", 1: "POSITIVE"}

    while True:
        try:
            print("\n" + "-" * 30)
            user_text = input("Input Text >> ").strip()

            if user_text.lower() in ["exit", "quit"]:
                print("Exiting...")
                break
            if not user_text:
                continue

            while True:
                model_choice = (
                    input("Select Model ( 0:BERT / 1:GPT-2 ) >> ").strip().lower()
                )
                if model_choice in ["0", "bert", "1", "gpt2", "gpt-2"]:
                    break
                print("Invalid choice. Please enter 0 or 1.")

            if model_choice in ["0", "bert"]:
                print(f"\n[BERT Processing]: '{user_text}'")

                inputs = tokenizer_bert(
                    user_text, return_tensors="pt", truncation=True
                ).to(dev_bert)

                start_t = time.time()
                with torch.no_grad():
                    out_base = base_bert(**inputs).logits
                base_time = time.time() - start_t
                pred_base = out_base.argmax(dim=-1).item()

                start_t = time.time()
                with torch.no_grad():
                    out_approx = approx_bert(**inputs).logits
                approx_time = time.time() - start_t
                pred_approx = out_approx.argmax(dim=-1).item()

                base_label = sst2_labels.get(pred_base, "Unknown")
                approx_label = sst2_labels.get(pred_approx, "Unknown")
                match = "MATCH" if pred_base == pred_approx else "MISMATCH"

                print(f"Baseline: {base_label} ({pred_base}) | Time: {base_time:.4f}s")
                print(
                    f"Approx  : {approx_label} ({pred_approx}) | Time: {approx_time:.4f}s"
                )
                print(f"Result  : >> {match} <<")

            elif model_choice in ["1", "gpt2", "gpt-2"]:
                print(f"\n[GPT-2 Generating] input: '{user_text}'")

                input_ids = tokenizer_gpt2.encode(user_text, return_tensors="pt").to(
                    dev_gpt2
                )
                attention_mask = torch.ones_like(input_ids).to(dev_gpt2)

                start_t = time.time()
                out_base = base_gpt2.generate(
                    input_ids,
                    attention_mask=attention_mask,
                    max_new_tokens=10,
                    num_return_sequences=1,
                    do_sample=False,
                    pad_token_id=tokenizer_gpt2.eos_token_id,
                    use_cache=False,
                )
                base_time = time.time() - start_t
                text_base = tokenizer_gpt2.decode(out_base[0], skip_special_tokens=True)
                print(f"[Baseline]: {text_base} ({base_time:.2f}s)")

                start_t = time.time()
                try:
                    out_approx = approx_gpt2.generate(
                        input_ids,
                        attention_mask=attention_mask,
                        max_new_tokens=10,
                        num_return_sequences=1,
                        do_sample=False,
                        pad_token_id=tokenizer_gpt2.eos_token_id,
                        use_cache=False,
                    )
                    approx_time = time.time() - start_t
                    text_approx = tokenizer_gpt2.decode(
                        out_approx[0], skip_special_tokens=True
                    )
                    print(f"[Approx]  : {text_approx} ({approx_time:.2f}s)")
                except Exception as e:
                    print(f"[Approx]  : Error -> {e}")
                    text_approx = "ERROR"

                if text_base == text_approx:
                    print("Result  : >> MATCH <<")
                else:
                    print("Result  : >> MISMATCH <<")

        except KeyboardInterrupt:
            print("\nInterrupted by user.")
            break
        except Exception as e:
            print(f"\nRuntime Error: {e}")
            break

    close_serial(ser)
    print("Serial port closed. Program finished.")


if __name__ == "__main__":
    main()
