import struct
import os

os.makedirs('assets', exist_ok=True)
w = 512
h = 512
with open("assets/app_icon.bmp", "wb") as f:
    f.write(b'BM')
    file_size = 54 + w * h * 3
    f.write(struct.pack('<I', file_size))
    f.write(b'\x00\x00\x00\x00')
    f.write(struct.pack('<I', 54))
    
    f.write(struct.pack('<I', 40))
    f.write(struct.pack('<i', w))
    f.write(struct.pack('<i', h))
    f.write(struct.pack('<H', 1))
    f.write(struct.pack('<H', 24))
    f.write(struct.pack('<I', 0)) 
    f.write(struct.pack('<I', w * h * 3))
    f.write(struct.pack('<I', 0))
    f.write(struct.pack('<I', 0))
    f.write(struct.pack('<I', 0))
    f.write(struct.pack('<I', 0))
    
    # BMP is bottom-up by default!
    for y in range(h):
        for x in range(w):
            r = 141 
            g = 188
            b = 166
            
            # Simple icon representation (plus)
            if abs(x-256) < 40 and 150 < y < 362:
                r, g, b = 255, 255, 255
            elif abs(y-256) < 40 and 150 < x < 362:
                r, g, b = 255, 255, 255
                
            f.write(struct.pack('<BBB', b, g, r))
