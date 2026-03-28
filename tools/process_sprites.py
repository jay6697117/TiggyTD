import os
import glob
from PIL import Image

src_dir = "/Users/zhangjinhui/.gemini/antigravity/brain/db67c2dd-45fc-4f42-a631-d3ff38c4eefc/"
base_dest_dir = "/Users/zhangjinhui/Desktop/TiggyTD/assets/art/"

def remove_white_bg(img, threshold=245):
    img = img.convert("RGBA")
    data = img.getdata()
    new_data = []
    for item in data:
        if item[0] >= threshold and item[1] >= threshold and item[2] >= threshold:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    return img

def process_and_save(category, prefix, target_size=(256, 256)):
    dest_dir = os.path.join(base_dest_dir, category)
    os.makedirs(dest_dir, exist_ok=True)
    
    # Debug: list all files
    all_files = os.listdir(src_dir)
    print(f"Total files in src_dir: {len(all_files)}")
    
    pattern = os.path.join(src_dir, f"{prefix}_*.png")
    files = glob.glob(pattern)
    print(f"Found {len(files)} files for {prefix} in {category}")
    
    for f in files:
        basename = os.path.basename(f)
        name_part = basename[len(prefix)+1:]
        name = name_part.rsplit("_", 1)[0]
        
        dest_path = os.path.join(dest_dir, f"{name}.png")
        
        try:
            with Image.open(f) as img:
                img = remove_white_bg(img)
                img = img.resize(target_size, Image.Resampling.LANCZOS)
                img.save(dest_path, "PNG")
                print(f"Processed {name} -> {dest_path}")
        except Exception as e:
            print(f"Failed to process {f}: {e}")

if __name__ == "__main__":
    process_and_save("towers", "tower", target_size=(256, 256))
    process_and_save("enemies", "enemy", target_size=(256, 256))
