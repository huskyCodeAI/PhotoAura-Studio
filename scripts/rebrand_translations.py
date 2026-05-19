# -*- coding: utf-8 -*-
import struct
import sys

def read_mo(filename):
    with open(filename, 'rb') as f:
        data = f.read()
    
    # Determinar endianness por el Magic Number de GNU gettext MO
    magic = struct.unpack('<I', data[0:4])[0]
    if magic == 0x950412de:
        endian = '<'
    elif magic == 0xde120495:
        endian = '>'
    else:
        raise ValueError("Invalid magic number")
    
    revision, num_strings, orig_offset, trans_offset, hash_size, hash_offset = struct.unpack(
        endian + 'IIIIII', data[4:28]
    )
    
    # Leer tabla de cadenas originales
    orig_table = []
    for i in range(num_strings):
        len_val, off_val = struct.unpack(
            endian + 'II', data[orig_offset + i * 8 : orig_offset + (i + 1) * 8]
        )
        orig_table.append((len_val, off_val))
        
    # Leer tabla de traducciones
    trans_table = []
    for i in range(num_strings):
        len_val, off_val = struct.unpack(
            endian + 'II', data[trans_offset + i * 8 : trans_offset + (i + 1) * 8]
        )
        trans_table.append((len_val, off_val))
        
    # Extraer pares clave-valor
    translations = {}
    for i in range(num_strings):
        o_len, o_off = orig_table[i]
        orig_str = data[o_off : o_off + o_len].decode('utf-8', errors='ignore')
        
        t_len, t_off = trans_table[i]
        trans_str = data[t_off : t_off + t_len].decode('utf-8', errors='ignore')
        
        translations[orig_str] = trans_str
        
    return translations

def write_mo(filename, translations):
    # Es obligatorio ordenar las claves para que la busqueda binaria de gettext funcione
    sorted_keys = sorted(translations.keys())
    num_strings = len(sorted_keys)
    
    orig_table_offset = 28
    trans_table_offset = orig_table_offset + num_strings * 8
    string_data_offset = trans_table_offset + num_strings * 8
    
    orig_table = []
    trans_table = []
    orig_bytes = []
    trans_bytes = []
    
    current_offset = string_data_offset
    for key in sorted_keys:
        k_bytes = key.encode('utf-8') + b'\x00'
        orig_table.append((len(k_bytes) - 1, current_offset))
        orig_bytes.append(k_bytes)
        current_offset += len(k_bytes)
        
    for key in sorted_keys:
        val = translations[key]
        v_bytes = val.encode('utf-8') + b'\x00'
        trans_table.append((len(v_bytes) - 1, current_offset))
        trans_bytes.append(v_bytes)
        current_offset += len(v_bytes)
        
    # Escribir el nuevo binario
    with open(filename, 'wb') as f:
        f.write(struct.pack('<I', 0x950412de))  # Magic
        f.write(struct.pack('<I', 0))           # Revision
        f.write(struct.pack('<I', num_strings))  # String Count
        f.write(struct.pack('<I', orig_table_offset))
        f.write(struct.pack('<I', trans_table_offset))
        f.write(struct.pack('<I', 0))           # Hash size
        f.write(struct.pack('<I', 0))           # Hash offset
        
        # Guardar tablas de índices
        for length, offset in orig_table:
            f.write(struct.pack('<II', length, offset))
            
        for length, offset in trans_table:
            f.write(struct.pack('<II', length, offset))
            
        # Escribir strings
        for b in orig_bytes:
            f.write(b)
        for b in trans_bytes:
            f.write(b)

if __name__ == '__main__':
    mo_path = r"c:\photo\build\app\share\locale\es\LC_MESSAGES\gimp20.mo"
    print("Abriendo archivo gimp20.mo...")
    translations = read_mo(mo_path)
    
    changed = 0
    for orig, trans in list(translations.items()):
        # 1. Cambiar el titulo oficial del software usando la clave en ingles original (idempotente)
        if orig == "GNU Image Manipulation Program":
            translations[orig] = u"PhotoAura Studio (based on GIMP)"
            changed += 1
            print(f"Reemplazado titulo principal: '{trans}' -> '{translations[orig]}'")
            
    if changed > 0:
        print(f"Se realizaron {changed} reemplazos. Guardando...")
        write_mo(mo_path, translations)
        print("¡Archivo gimp20.mo rebrandeado con exito!")
    else:
        print("No se encontraron cadenas de marca para reemplazar.")
