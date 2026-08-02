from gradio_client import Client, handle_file
import urllib.request

def test():
    try:
        print("Connecting to Nymbo/Virtual-Try-On...")
        client = Client("Nymbo/Virtual-Try-On")
        print("Viewing API:")
        client.view_api()
        
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
