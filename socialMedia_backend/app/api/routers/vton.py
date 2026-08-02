import os
import base64
import uuid
import tempfile
import httpx
import asyncio
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from gradio_client import Client, handle_file

router = APIRouter()

class VtonRequest(BaseModel):
    garment_url: str
    model_image_b64: str

class VtonResponse(BaseModel):
    image_url: Optional[str] = None
    status: str
    message: Optional[str] = None

# Optional: Add HF_TOKEN to env if you want to use a private space or avoid rate limits
HF_TOKEN = os.getenv("HF_TOKEN")

@router.post("/tryon", response_model=VtonResponse)
async def vton_tryon(req: VtonRequest):
    """
    Hugging Face Space IDM-VTON Endpoint.
    Uses gradio_client to generate virtual try-on images.
    """
    try:
        # 1. Download the garment image from the URL to a temporary file
        garment_temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        async with httpx.AsyncClient(timeout=15.0) as http_client:
            resp = await http_client.get(req.garment_url)
            if resp.status_code != 200:
                raise HTTPException(status_code=400, detail="Could not download garment image")
            garment_temp.write(resp.content)
            garment_temp.close()
            
        # 2. Save the base64 model image to a temporary file
        model_temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        try:
            # handle cases where the base64 string includes 'data:image/...;base64,' prefix
            b64_str = req.model_image_b64
            if "," in b64_str:
                b64_str = b64_str.split(",")[1]
            img_data = base64.b64decode(b64_str)
            model_temp.write(img_data)
            model_temp.close()
        except Exception as e:
            raise HTTPException(status_code=400, detail=f"Invalid model image base64: {e}")

        # 3. Call Hugging Face Space using Gradio Client
        # This is a synchronous call, so we run it in a thread pool to avoid blocking the event loop
        def run_gradio():
            client = Client("yisol/IDM-VTON", hf_token=HF_TOKEN)
            result = client.predict(
                dict={"background": handle_file(model_temp.name), "layers": [], "composite": None},
                garm_img=handle_file(garment_temp.name),
                garment_des="a garment",
                is_checked=True,
                is_checked_crop=False,
                denoise_steps=30,
                seed=42,
                api_name="/tryon"
            )
            return result
        
        # result is a tuple: (output_image_path, masked_image_output_path)
        result = await asyncio.to_thread(run_gradio)
        
        output_image_path = result[0]
        
        # 4. Read the output image and convert it to base64 so frontend can display it
        if not output_image_path or not os.path.exists(output_image_path):
            raise Exception("Hugging Face API did not return a valid output image path")
            
        with open(output_image_path, "rb") as f:
            out_bytes = f.read()
            out_b64 = base64.b64encode(out_bytes).decode("utf-8")
            # Determine mime type from extension, default to webp which is common in HF
            ext = os.path.splitext(output_image_path)[1].lower().replace('.', '')
            mime_type = "jpeg" if ext in ["jpg", "jpeg"] else ext if ext else "webp"
            
            data_uri = f"data:image/{mime_type};base64,{out_b64}"
            
        # Cleanup temp files
        try:
            os.unlink(garment_temp.name)
            os.unlink(model_temp.name)
        except:
            pass
            
        return VtonResponse(
            image_url=data_uri,
            status="completed",
            message="Success"
        )
            
    except HTTPException:
        raise
    except Exception as e:
        # Cleanup on error
        try:
            if 'garment_temp' in locals(): os.unlink(garment_temp.name)
            if 'model_temp' in locals(): os.unlink(model_temp.name)
        except:
            pass
            
        print(f"VTON Error: {e}")
        # Return demo fallback if HF fails (HF spaces can be unstable)
        demo_images = [
            "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=800&q=80",
            "https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&q=80",
        ]
        import random
        return VtonResponse(
            image_url=random.choice(demo_images), 
            status="demo",
            message=f"HuggingFace Space error (overloaded). Fallback to demo mode. Error: {e}"
        )
