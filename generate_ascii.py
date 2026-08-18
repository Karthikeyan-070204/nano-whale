import sys
import subprocess
import os

try:
    from PIL import Image
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

def generate_header(image_path, output_path, width=70):
    img = Image.open(image_path).convert('RGBA')
    
    # Replace white background with transparency
    data = list(img.getdata())
    new_data = []
    for item in data:
        # If it is close to white, make it transparent
        if item[0] > 230 and item[1] > 230 and item[2] > 230:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    
    # Crop to bounding box to remove empty space
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    w, h = img.size
    # A half-block is a square pixel.
    aspect = h / float(w)
    new_h = int(aspect * width)
    
    # Make height even so we can process two pixels per character row
    if new_h % 2 != 0:
        new_h += 1
        
    img = img.resize((width, new_h), Image.LANCZOS)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("#pragma once\n")
        f.write("#include <ftxui/dom/elements.hpp>\n")
        f.write("#include <vector>\n")
        f.write("#include <cstdint>\n\n")
        f.write("namespace nw {\n")
        f.write(f"constexpr int ASCII_WIDTH = {width};\n")
        f.write(f"constexpr int ASCII_HEIGHT = {new_h};\n")
        f.write("constexpr uint8_t ascii_img[ASCII_HEIGHT][ASCII_WIDTH][4] = {\n")
        
        for y in range(new_h):
            f.write("    {")
            for x in range(width):
                r, g, b, a = img.getpixel((x, y))
                f.write(f"{{{r},{g},{b},{a}}},")
            f.write("},\n")
        f.write("};\n\n")
            
        f.write("inline ftxui::Element render_ascii_art() {\n")
        f.write("    using namespace ftxui;\n")
        f.write("    std::vector<Element> rows;\n")
        f.write("    // Process 2 pixels vertically for every character row\n")
        f.write("    for (int y = 0; y < ASCII_HEIGHT; y += 2) {\n")
        f.write("        std::vector<Element> cols;\n")
        f.write("        for (int x = 0; x < ASCII_WIDTH; ++x) {\n")
        f.write("            uint8_t r1 = ascii_img[y][x][0];\n")
        f.write("            uint8_t g1 = ascii_img[y][x][1];\n")
        f.write("            uint8_t b1 = ascii_img[y][x][2];\n")
        f.write("            uint8_t a1 = ascii_img[y][x][3];\n")
        f.write("            \n")
        f.write("            uint8_t r2 = ascii_img[y+1][x][0];\n")
        f.write("            uint8_t g2 = ascii_img[y+1][x][1];\n")
        f.write("            uint8_t b2 = ascii_img[y+1][x][2];\n")
        f.write("            uint8_t a2 = ascii_img[y+1][x][3];\n")
        f.write("            \n")
        f.write("            if (a1 == 0 && a2 == 0) {\n")
        f.write('                cols.push_back(text(" "));\n')
        f.write("            } else if (a1 == 0 && a2 != 0) {\n")
        f.write('                cols.push_back(text("▄") | color(Color::RGB(r2, g2, b2)));\n')
        f.write("            } else if (a1 != 0 && a2 == 0) {\n")
        f.write('                cols.push_back(text("▀") | color(Color::RGB(r1, g1, b1)));\n')
        f.write("            } else {\n")
        f.write('                cols.push_back(text("▀") | color(Color::RGB(r1, g1, b1)) | bgcolor(Color::RGB(r2, g2, b2)));\n')
        f.write("            }\n")
        f.write("        }\n")
        f.write("        rows.push_back(hbox(std::move(cols)) | center);\n")
        f.write("    }\n")
        f.write("    return vbox(std::move(rows)) | center;\n")
        f.write("}\n")
        f.write("}\n")

generate_header(
    r"C:\Users\krish\.gemini\antigravity-ide\brain\96fce26c-748e-415f-9cb2-6ff7357c838e\.user_uploaded\media_1787069421787.png", 
    "src/ascii_art.h",
    width=70
)
