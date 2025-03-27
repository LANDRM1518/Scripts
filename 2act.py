import requests

def scan_url(target_url, word):
    full_url = f"{target_url.rstrip('/')}/{word}"
    try:
        response = requests.get(full_url, timeout=5)
        if response.status_code == 200:
            print(f"Encontrado: {full_url} (Código {response.status_code})")
        elif response.status_code == 403:
            print(f"Acceso denegado: {full_url} (Código {response.status_code})")
        elif response.status_code == 404:
            print(f"No encontrado: {full_url} (Código {response.status_code})")
        else:
            print(f"Estado desconocido: {full_url} (Código {response.status_code})")
    except requests.exceptions.RequestException as e:
        print(f"Error al conectar con {full_url}: {e}")

def scan_from_file(target_url, file_path):
    """Lee una lista de palabras desde un archivo y las escanea en el sitio web."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            words = [line.strip() for line in file if line.strip()]
        
        print(f"Escaneando {len(words)} palabras en {target_url}...")
        for word in words:
            scan_url(target_url, word)
    except FileNotFoundError:
        print(f"Error: El archivo {file_path} no se encontró.")
    except Exception as e:
        print(f"Error al leer el archivo: {e}")

TARGET_URL = "http://127.0.0.1:8000"  
WORDLIST_FILE = "palabras.txt"  

scan_from_file(TARGET_URL, WORDLIST_FILE)

