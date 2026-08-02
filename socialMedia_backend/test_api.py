import asyncio
import httpx
import base64
import json

async def test():
    # create a dummy base64 image
    with open("human.jpg", "rb") as f:
        b64 = base64.b64encode(f.read()).decode("utf-8")
        
    async with httpx.AsyncClient() as client:
        res = await client.post("http://127.0.0.1:8000/api/wardrobe/vton/tryon", json={
            "garment_url": "https://images.unsplash.com/photo-1576566588028-4147f3842f27",
            "model_image_b64": b64
        })
        print(res.status_code)
        print(res.text)

asyncio.run(test())
