from gradio_client import Client, handle_file
import tempfile
import urllib.request

def test():
    try:
        print("Downloading test image...")
        urllib.request.urlretrieve("https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400", "human.jpg")
        urllib.request.urlretrieve("https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400", "garment.jpg")
        
        print("Connecting to space...")
        client = Client("yisol/IDM-VTON")
        
        print("Calling predict...")
        result = client.predict(
            dict={"background": handle_file("human.jpg"), "layers": [], "composite": None},
            garm_img=handle_file("garment.jpg"),
            garment_des="a garment",
            is_checked=True,
            is_checked_crop=False,
            denoise_steps=30,
            seed=42,
            api_name="/tryon"
        )
        print("Success!", result)
    except Exception as e:
        print(f"Error: {e}")

test()
