from gradio_client import Client, handle_file
import urllib.request

def test():
    try:
        print("Downloading test image...")
        urllib.request.urlretrieve("https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=400", "human.jpg")
        urllib.request.urlretrieve("https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400", "garment.jpg")
        
        print("Connecting to Kolors...")
        client = Client("Kwai-Kolors/Kolors-Virtual-Try-On")
        print("Viewing API:")
        client.view_api()
    except Exception as e:
        print(f"Error: {e}")

test()
