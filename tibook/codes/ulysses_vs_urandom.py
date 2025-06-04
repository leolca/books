import re
import os
import numpy as np
import pandas as pd

# Função para processar texto de Ulysses
def process_ulysses(input_file, output_file, max_chars=10000):
    with open(input_file, 'r', encoding='utf-8') as f:
        text = f.read()
    # Converter para minúsculas e manter apenas [a-z]
    text = re.sub(r'[^a-z]', '', text.lower())
    # Pegar até max_chars
    text = text[:max_chars]
    # Converter para lista de caracteres
    chars = list(text)
    # Salvar em CSV
    pd.DataFrame(chars, columns=['char']).to_csv(output_file, index=False)

# Função para gerar dados de /dev/urandom e mapear para [a-z]
def generate_urandom(output_file, n=10000):
    # Ler n bytes de /dev/urandom
    with open('/dev/urandom', 'rb') as f:
        bytes_data = f.read(n)
    # Mapear bytes para [0, 25] e converter para letras [a-z]
    mapped_chars = [chr((b % 26) + ord('a')) for b in bytes_data]
    # Salvar em CSV
    pd.DataFrame(mapped_chars, columns=['char']).to_csv(output_file, index=False)

# Executar
process_ulysses('ulysses.txt', 'ulysses_processed.csv',1000000)
generate_urandom('urandom_processed.csv',1000000)
