"""
Generate 3D model (.obj, .mtl) and Rickshaw Art texture for Bangla Tesla Rocket Rickshaw.
"""
import os
import math
from PIL import Image, ImageDraw, ImageFont

def generate_rickshaw_art_texture(output_path):
    size = (1024, 1024)
    img = Image.new("RGBA", size, (20, 20, 25, 255))
    draw = ImageDraw.Draw(img)

    # Base background: deep ornate red & teal panels
    # Backplate panel (top half)
    draw.rectangle([50, 50, 974, 500], fill=(210, 30, 45, 255), outline=(255, 215, 0, 255), width=8)
    
    # Yellow inner frame
    draw.rectangle([70, 70, 954, 480], fill=(230, 180, 20, 255), outline=(10, 150, 80, 255), width=6)
    
    # Peacock & Floral decorative motifs (traditional Rickshaw Art)
    center_x, center_y = 512, 275
    # Central medallion
    draw.ellipse([center_x - 140, center_y - 140, center_x + 140, center_y + 140], fill=(15, 120, 190, 255), outline=(255, 255, 255, 255), width=5)
    draw.ellipse([center_x - 110, center_y - 110, center_x + 110, center_y + 110], fill=(245, 110, 20, 255))
    
    # Flower petals
    for angle in range(0, 360, 30):
        rad = math.radians(angle)
        px = center_x + int(85 * math.cos(rad))
        py = center_y + int(85 * math.sin(rad))
        draw.ellipse([px - 22, py - 22, px + 22, py + 22], fill=(255, 240, 60, 255), outline=(200, 20, 40, 255), width=2)
    
    draw.ellipse([center_x - 45, center_y - 45, center_x + 45, center_y + 45], fill=(255, 255, 255, 255), outline=(0, 100, 50, 255), width=4)
    draw.ellipse([center_x - 25, center_y - 25, center_x + 25, center_y + 25], fill=(220, 20, 60, 255))

    # Corner floral ornaments
    corners = [(130, 130), (894, 130), (130, 420), (894, 420)]
    for cx, cy in corners:
        draw.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], fill=(0, 160, 90, 255), outline=(255, 215, 0, 255), width=4)
        draw.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], fill=(255, 50, 90, 255))

    # Lower panel: Rickshaw canopy and hood stripes (bottom half)
    draw.rectangle([50, 540, 974, 974], fill=(10, 140, 80, 255), outline=(255, 215, 0, 255), width=6)
    
    # Ornate geometric triangular border
    tri_w = 40
    for x in range(60, 960, tri_w):
        draw.polygon([(x, 550), (x + tri_w//2, 590), (x + tri_w, 550)], fill=(255, 215, 0, 255))
        draw.polygon([(x, 964), (x + tri_w//2, 924), (x + tri_w, 964)], fill=(255, 215, 0, 255))

    # Center text / logo: BANGLA TESLA in bold decorative style
    # Draw decorative banners
    draw.rectangle([200, 700, 824, 820], fill=(220, 25, 45, 255), outline=(255, 255, 255, 255), width=4)
    # Yellow banner border
    draw.rectangle([210, 710, 814, 810], fill=(240, 190, 20, 255))
    draw.rectangle([220, 720, 804, 800], fill=(20, 30, 45, 255))
    
    # Cyan neon glow lines representing the Tesla rocket technology
    for y in [630, 650, 860, 880]:
        draw.line([(80, y), (940, y)], fill=(0, 230, 255, 255), width=4)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, "PNG")
    print(f"Rickshaw art texture saved to: {output_path}")

def generate_obj_model(obj_path, mtl_path):
    """
    Generates a structured, modular 3D Rickshaw Model with separated components:
    - Chassis & frame
    - Passenger carriage & ornate hood
    - Puller / Driver
    - Front steering fork & wheel
    - Rear wheels (left & right)
    - 3 Downward rocket jet thrusters (front, rear-L, rear-R)
    """
    vertices = []
    texcoords = []
    normals = []
    objects = []

    def add_v(x, y, z):
        vertices.append((x, y, z))
        return len(vertices)

    def add_vt(u, v):
        texcoords.append((u, v))
        return len(texcoords)

    def add_vn(nx, ny, nz):
        normals.append((nx, ny, nz))
        return len(normals)

    # Standard cardinal normals
    n_up = add_vn(0, 1, 0)
    n_down = add_vn(0, -1, 0)
    n_fwd = add_vn(0, 0, 1)
    n_back = add_vn(0, 0, -1)
    n_left = add_vn(-1, 0, 0)
    n_right = add_vn(1, 0, 0)

    # Standard UV corners
    vt_00 = add_vt(0.0, 0.0)
    vt_10 = add_vt(1.0, 0.0)
    vt_11 = add_vt(1.0, 1.0)
    vt_01 = add_vt(0.0, 1.0)
    
    # UV for rickshaw art backplate (top half)
    vt_art_bl = add_vt(0.05, 0.52)
    vt_art_br = add_vt(0.95, 0.52)
    vt_art_tr = add_vt(0.95, 0.95)
    vt_art_tl = add_vt(0.05, 0.95)

    def add_box(obj_name, mat_name, min_x, min_y, min_z, max_x, max_y, max_z, uv_face=None):
        faces = []
        # 8 vertices
        v1 = add_v(min_x, min_y, max_z) # front bl
        v2 = add_v(max_x, min_y, max_z) # front br
        v3 = add_v(max_x, max_y, max_z) # front tr
        v4 = add_v(min_x, max_y, max_z) # front tl
        v5 = add_v(max_x, min_y, min_z) # back bl
        v6 = add_v(min_x, min_y, min_z) # back br
        v7 = add_v(min_x, max_y, min_z) # back tr
        v8 = add_v(max_x, max_y, min_z) # back tl

        # Front (+Z)
        uv = uv_face if uv_face else (vt_00, vt_10, vt_11, vt_01)
        faces.append(((v1, uv[0], n_fwd), (v2, uv[1], n_fwd), (v3, uv[2], n_fwd)))
        faces.append(((v1, uv[0], n_fwd), (v3, uv[2], n_fwd), (v4, uv[3], n_fwd)))
        # Back (-Z)
        faces.append(((v5, uv[0], n_back), (v6, uv[1], n_back), (v7, uv[2], n_back)))
        faces.append(((v5, uv[0], n_back), (v7, uv[2], n_back), (v8, uv[3], n_back)))
        # Top (+Y)
        faces.append(((v4, vt_00, n_up), (v3, vt_10, n_up), (v8, vt_11, n_up)))
        faces.append(((v4, vt_00, n_up), (v8, vt_11, n_up), (v7, vt_01, n_up)))
        # Bottom (-Y)
        faces.append(((v6, vt_00, n_down), (v5, vt_10, n_down), (v2, vt_11, n_down)))
        faces.append(((v6, vt_00, n_down), (v2, vt_11, n_down), (v1, vt_01, n_down)))
        # Left (-X)
        faces.append(((v6, vt_00, n_left), (v1, vt_10, n_left), (v4, vt_11, n_left)))
        faces.append(((v6, vt_00, n_left), (v4, vt_11, n_left), (v7, vt_01, n_left)))
        # Right (+X)
        faces.append(((v2, vt_00, n_right), (v5, vt_10, n_right), (v8, vt_11, n_right)))
        faces.append(((v2, vt_00, n_right), (v8, vt_11, n_right), (v3, vt_01, n_right)))

        objects.append({
            "name": obj_name,
            "material": mat_name,
            "faces": faces
        })

    def add_cylinder(obj_name, mat_name, center_x, center_y, center_z, radius, height, axis="y", segments=12):
        faces = []
        top_verts = []
        bot_verts = []

        for i in range(segments):
            angle = 2.0 * math.pi * i / segments
            c = math.cos(angle) * radius
            s = math.sin(angle) * radius

            if axis == "y":
                # vertical cylinder
                top_verts.append(add_v(center_x + c, center_y + height / 2.0, center_z + s))
                bot_verts.append(add_v(center_x + c, center_y - height / 2.0, center_z + s))
            elif axis == "x":
                # horizontal cylinder along X (wheels)
                top_verts.append(add_v(center_x + height / 2.0, center_y + c, center_z + s))
                bot_verts.append(add_v(center_x - height / 2.0, center_y + c, center_z + s))
            elif axis == "z":
                # horizontal along Z
                top_verts.append(add_v(center_x + c, center_y + s, center_z + height / 2.0))
                bot_verts.append(add_v(center_x + c, center_y + s, center_z - height / 2.0))

        # Side faces
        for i in range(segments):
            next_i = (i + 1) % segments
            t1, t2 = top_verts[i], top_verts[next_i]
            b1, b2 = bot_verts[i], bot_verts[next_i]
            norm_idx = n_up if axis == "y" else (n_right if axis == "x" else n_fwd)
            faces.append(((b1, vt_00, norm_idx), (b2, vt_10, norm_idx), (t2, vt_11, norm_idx)))
            faces.append(((b1, vt_00, norm_idx), (t2, vt_11, norm_idx), (t1, vt_01, norm_idx)))

        # End caps
        c_top = add_v(center_x + (height/2 if axis=="x" else 0), center_y + (height/2 if axis=="y" else 0), center_z + (height/2 if axis=="z" else 0))
        c_bot = add_v(center_x - (height/2 if axis=="x" else 0), center_y - (height/2 if axis=="y" else 0), center_z - (height/2 if axis=="z" else 0))
        for i in range(segments):
            next_i = (i + 1) % segments
            norm_t = n_up if axis == "y" else (n_right if axis == "x" else n_fwd)
            norm_b = n_down if axis == "y" else (n_left if axis == "x" else n_back)
            faces.append(((c_top, vt_00, norm_t), (top_verts[i], vt_10, norm_t), (top_verts[next_i], vt_11, norm_t)))
            faces.append(((c_bot, vt_00, norm_b), (bot_verts[next_i], vt_10, norm_b), (bot_verts[i], vt_11, norm_b)))

        objects.append({
            "name": obj_name,
            "material": mat_name,
            "faces": faces
        })

    def add_cone(obj_name, mat_name, cx, cy, cz, r_top, r_bot, height, segments=12):
        """Downward conical nozzle for jet thrusters"""
        faces = []
        top_v = []
        bot_v = []
        for i in range(segments):
            ang = 2.0 * math.pi * i / segments
            c = math.cos(ang)
            s = math.sin(ang)
            top_v.append(add_v(cx + c * r_top, cy + height / 2.0, cz + s * r_top))
            bot_v.append(add_v(cx + c * r_bot, cy - height / 2.0, cz + s * r_bot))
        
        for i in range(segments):
            next_i = (i + 1) % segments
            faces.append(((bot_v[i], vt_00, n_down), (bot_v[next_i], vt_10, n_down), (top_v[next_i], vt_11, n_up)))
            faces.append(((bot_v[i], vt_00, n_down), (top_v[next_i], vt_11, n_up), (top_v[i], vt_01, n_up)))

        objects.append({
            "name": obj_name,
            "material": mat_name,
            "faces": faces
        })

    # --- 1. CHASSIS / FRAME (Main Cycle Rickshaw Tubes & Base) ---
    # Central spine tube (front to rear)
    add_cylinder("Chassis_Spine", "Mat_Frame_Red", 0.0, 0.45, -0.1, 0.035, 1.2, axis="z", segments=8)
    # Down-tube to pedal crank
    add_cylinder("Chassis_DownTube", "Mat_Frame_Red", 0.0, 0.35, 0.35, 0.03, 0.5, axis="y", segments=8)
    # Bottom rear cross axle support
    add_box("Chassis_RearAxle", "Mat_Frame_Green", -0.55, 0.32, -0.65, 0.55, 0.38, -0.55)
    # Carriage base box (passenger footrest platform)
    add_box("Chassis_Footrest", "Mat_Frame_Green", -0.42, 0.35, -0.60, 0.42, 0.42, -0.05)
    
    # --- 2. PASSENGER CARRIAGE & SEAT ---
    # Passenger seat base box
    add_box("Carriage_SeatBox", "Mat_RickshawArt", -0.45, 0.42, -0.75, 0.45, 0.72, -0.35, 
            uv_face=(vt_art_bl, vt_art_br, vt_art_tr, vt_art_tl))
    # Passenger cushion (upholstery)
    add_box("Carriage_SeatCushion", "Mat_Seat_Leather", -0.44, 0.72, -0.72, 0.44, 0.80, -0.38)
    # Backrest cushion
    add_box("Carriage_Backrest", "Mat_Seat_Leather", -0.44, 0.80, -0.75, 0.44, 1.15, -0.68)
    # Side armrests
    add_box("Carriage_Armrest_L", "Mat_Chrome", -0.46, 0.72, -0.72, -0.42, 0.95, -0.36)
    add_box("Carriage_Armrest_R", "Mat_Chrome", 0.42, 0.72, -0.72, 0.46, 0.95, -0.36)
    
    # --- 3. ORNATE RICKSHAW HOOD / CANOPY (The signature folded curved top) ---
    # Curved canopy ribs & cloth top
    add_box("Canopy_Main", "Mat_RickshawArt", -0.48, 1.12, -0.80, 0.48, 1.62, -0.55,
            uv_face=(vt_art_bl, vt_art_br, vt_art_tr, vt_art_tl))
    add_box("Canopy_TopCurve", "Mat_RickshawArt", -0.47, 1.58, -0.78, 0.47, 1.75, -0.40)
    # Canopy folding metal struts
    add_cylinder("Canopy_Strut_L", "Mat_Chrome", -0.46, 1.25, -0.45, 0.015, 0.7, axis="y", segments=6)
    add_cylinder("Canopy_Strut_R", "Mat_Chrome", 0.46, 1.25, -0.45, 0.015, 0.7, axis="y", segments=6)
    
    # Rear art backplate (facing behind the rickshaw, iconic rickshaw art panel)
    add_box("Carriage_ArtBackplate", "Mat_RickshawArt", -0.42, 0.42, -0.77, 0.42, 0.78, -0.75,
            uv_face=(vt_art_bl, vt_art_br, vt_art_tr, vt_art_tl))

    # --- 4. DRIVER / RICKSHAW PULLER ---
    # Driver seat / saddle
    add_box("Driver_Saddle", "Mat_Seat_Leather", -0.10, 0.65, 0.15, 0.10, 0.70, 0.32)
    # Driver Torso (seated leaning slightly forward)
    add_box("Driver_Torso", "Mat_Driver_Shirt", -0.16, 0.70, 0.18, 0.16, 1.15, 0.36)
    # Driver Head & Cap
    add_box("Driver_Head", "Mat_Driver_Skin", -0.09, 1.15, 0.22, 0.09, 1.30, 0.34)
    # Rickshaw puller baseball cap
    add_box("Driver_Cap", "Mat_Driver_Cap", -0.10, 1.28, 0.20, 0.10, 1.35, 0.40)
    # Arms holding handlebars
    add_cylinder("Driver_Arm_L", "Mat_Driver_Shirt", -0.22, 0.95, 0.48, 0.04, 0.45, axis="z", segments=6)
    add_cylinder("Driver_Arm_R", "Mat_Driver_Shirt", 0.22, 0.95, 0.48, 0.04, 0.45, axis="z", segments=6)
    # Legs down to pedals
    add_cylinder("Driver_Leg_L", "Mat_Driver_Pants", -0.12, 0.52, 0.26, 0.05, 0.40, axis="y", segments=6)
    add_cylinder("Driver_Leg_R", "Mat_Driver_Pants", 0.12, 0.52, 0.26, 0.05, 0.40, axis="y", segments=6)

    # --- 5. STEERING FORK & HANDLEBARS (Separated for Unity steering rotation) ---
    # Steering stem (Z = 0.75, Y = 0.55 to 1.0)
    add_cylinder("Steering_Stem", "Mat_Chrome", 0.0, 0.75, 0.75, 0.025, 0.55, axis="y", segments=8)
    # Handlebar crossbar
    add_cylinder("Steering_Handlebar", "Mat_Chrome", 0.0, 1.02, 0.72, 0.02, 0.60, axis="x", segments=8)
    # Classic round headlight
    add_cylinder("Steering_Headlight", "Mat_Chrome", 0.0, 0.90, 0.82, 0.06, 0.08, axis="z", segments=10)
    add_cylinder("Headlight_Lens", "Mat_Emissive_White", 0.0, 0.90, 0.87, 0.05, 0.02, axis="z", segments=10)
    # Front fork legs
    add_cylinder("Fork_Leg_L", "Mat_Frame_Red", -0.06, 0.48, 0.75, 0.02, 0.45, axis="y", segments=6)
    add_cylinder("Fork_Leg_R", "Mat_Frame_Red", 0.06, 0.48, 0.75, 0.02, 0.45, axis="y", segments=6)

    # --- 6. WHEELS & ROCKET THRUSTERS ---
    # Front Wheel (radius = 0.35m, center = (0, 0.35, 0.75))
    add_cylinder("Wheel_Front_Tire", "Mat_Rubber", 0.0, 0.35, 0.75, 0.35, 0.05, axis="x", segments=16)
    add_cylinder("Wheel_Front_Rim", "Mat_Chrome", 0.0, 0.35, 0.75, 0.28, 0.04, axis="x", segments=16)
    add_cylinder("Wheel_Front_Hub", "Mat_Chrome", 0.0, 0.35, 0.75, 0.06, 0.08, axis="x", segments=8)
    
    # Front Jet Rocket Nozzle (Mounted right at bottom hub firing down!)
    add_cone("Thruster_Front_Nozzle", "Mat_Chrome", 0.0, 0.18, 0.75, 0.06, 0.09, 0.14, segments=12)
    add_cylinder("Thruster_Front_Core", "Mat_Cyan_Plasma", 0.0, 0.10, 0.75, 0.075, 0.02, axis="y", segments=12)

    # Rear Left Wheel (center = (-0.52, 0.35, -0.60))
    add_cylinder("Wheel_Rear_L_Tire", "Mat_Rubber", -0.52, 0.35, -0.60, 0.35, 0.05, axis="x", segments=16)
    add_cylinder("Wheel_Rear_L_Rim", "Mat_Chrome", -0.52, 0.35, -0.60, 0.28, 0.04, axis="x", segments=16)
    add_cylinder("Wheel_Rear_L_Hub", "Mat_Chrome", -0.52, 0.35, -0.60, 0.06, 0.08, axis="x", segments=8)
    # Rear Left Fender / Mudguard
    add_box("Fender_Rear_L", "Mat_Frame_Green", -0.56, 0.68, -0.85, -0.48, 0.73, -0.35)
    # Rear Left Jet Rocket Nozzle
    add_cone("Thruster_Rear_L_Nozzle", "Mat_Chrome", -0.52, 0.18, -0.60, 0.06, 0.09, 0.14, segments=12)
    add_cylinder("Thruster_Rear_L_Core", "Mat_Cyan_Plasma", -0.52, 0.10, -0.60, 0.075, 0.02, axis="y", segments=12)

    # Rear Right Wheel (center = (0.52, 0.35, -0.60))
    add_cylinder("Wheel_Rear_R_Tire", "Mat_Rubber", 0.52, 0.35, -0.60, 0.35, 0.05, axis="x", segments=16)
    add_cylinder("Wheel_Rear_R_Rim", "Mat_Chrome", 0.52, 0.35, -0.60, 0.28, 0.04, axis="x", segments=16)
    add_cylinder("Wheel_Rear_R_Hub", "Mat_Chrome", 0.52, 0.35, -0.60, 0.06, 0.08, axis="x", segments=8)
    # Rear Right Fender / Mudguard
    add_box("Fender_Rear_R", "Mat_Frame_Green", 0.48, 0.68, -0.85, 0.56, 0.73, -0.35)
    # Rear Right Jet Rocket Nozzle
    add_cone("Thruster_Rear_R_Nozzle", "Mat_Chrome", 0.52, 0.18, -0.60, 0.06, 0.09, 0.14, segments=12)
    add_cylinder("Thruster_Rear_R_Core", "Mat_Cyan_Plasma", 0.52, 0.10, -0.60, 0.075, 0.02, axis="y", segments=12)

    # Write OBJ file
    os.makedirs(os.path.dirname(obj_path), exist_ok=True)
    with open(obj_path, "w") as f:
        f.write("# Bangla Tesla 3D Model - Ready for Unity on Android\n")
        f.write(f"mtllib {os.path.basename(mtl_path)}\n\n")

        for v in vertices:
            f.write(f"v {v[0]:.4f} {v[1]:.4f} {v[2]:.4f}\n")
        for vt in texcoords:
            f.write(f"vt {vt[0]:.4f} {vt[1]:.4f}\n")
        for vn in normals:
            f.write(f"vn {vn[0]:.4f} {vn[1]:.4f} {vn[2]:.4f}\n")

        for obj in objects:
            f.write(f"\no {obj['name']}\n")
            f.write(f"usemtl {obj['material']}\n")
            for face in obj["faces"]:
                f.write(f"f {face[0][0]}/{face[0][1]}/{face[0][2]} {face[1][0]}/{face[1][1]}/{face[1][2]} {face[2][0]}/{face[2][1]}/{face[2][2]}\n")

    print(f"Generated OBJ model with {len(vertices)} vertices and {len(objects)} parts at: {obj_path}")

    # Write MTL file
    with open(mtl_path, "w") as f:
        f.write("# Bangla Tesla Materials\n\n")
        f.write("newmtl Mat_RickshawArt\n")
        f.write("Kd 1.0 1.0 1.0\n")
        f.write("Ks 0.2 0.2 0.2\n")
        f.write("Ns 30\n")
        f.write("map_Kd rickshaw_art.png\n\n")

        f.write("newmtl Mat_Frame_Red\n")
        f.write("Kd 0.85 0.12 0.15\n")
        f.write("Ks 0.4 0.4 0.4\n")
        f.write("Ns 50\n\n")

        f.write("newmtl Mat_Frame_Green\n")
        f.write("Kd 0.05 0.55 0.25\n")
        f.write("Ks 0.4 0.4 0.4\n")
        f.write("Ns 50\n\n")

        f.write("newmtl Mat_Chrome\n")
        f.write("Kd 0.9 0.9 0.95\n")
        f.write("Ks 0.95 0.95 0.95\n")
        f.write("Ns 120\n\n")

        f.write("newmtl Mat_Rubber\n")
        f.write("Kd 0.15 0.15 0.16\n")
        f.write("Ks 0.1 0.1 0.1\n")
        f.write("Ns 10\n\n")

        f.write("newmtl Mat_Seat_Leather\n")
        f.write("Kd 0.55 0.15 0.12\n")
        f.write("Ks 0.3 0.3 0.3\n")
        f.write("Ns 25\n\n")

        f.write("newmtl Mat_Driver_Shirt\n")
        f.write("Kd 0.85 0.85 0.88\n")
        f.write("Ks 0.1 0.1 0.1\n")
        f.write("Ns 15\n\n")

        f.write("newmtl Mat_Driver_Pants\n")
        f.write("Kd 0.35 0.38 0.35\n")
        f.write("Ks 0.1 0.1 0.1\n")
        f.write("Ns 15\n\n")

        f.write("newmtl Mat_Driver_Skin\n")
        f.write("Kd 0.68 0.45 0.35\n")
        f.write("Ks 0.1 0.1 0.1\n")
        f.write("Ns 10\n\n")

        f.write("newmtl Mat_Driver_Cap\n")
        f.write("Kd 0.30 0.30 0.32\n")
        f.write("Ks 0.1 0.1 0.1\n")
        f.write("Ns 15\n\n")

        f.write("newmtl Mat_Emissive_White\n")
        f.write("Kd 1.0 1.0 1.0\n")
        f.write("Ke 1.0 1.0 0.9\n")
        f.write("Ns 80\n\n")

        f.write("newmtl Mat_Cyan_Plasma\n")
        f.write("Kd 0.0 0.8 1.0\n")
        f.write("Ke 0.1 0.9 1.0\n")
        f.write("Ns 100\n\n")

    print(f"Generated MTL file at: {mtl_path}")

if __name__ == "__main__":
    base_assets = "/Users/psl/hanif_3.0/bangla_tesla/bangla_tesla/bangla_tesla/assets/models"
    unity_assets = "/Users/psl/hanif_3.0/bangla_tesla/bangla_tesla/bangla_tesla/unity/BanglaTeslaUnity/Assets/Models"

    for dest in [base_assets, unity_assets]:
        tex_path = os.path.join(dest, "rickshaw_art.png")
        obj_path = os.path.join(dest, "bangla_tesla.obj")
        mtl_path = os.path.join(dest, "bangla_tesla.mtl")
        
        generate_rickshaw_art_texture(tex_path)
        generate_obj_model(obj_path, mtl_path)
