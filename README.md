# ARC4 Hardware Cracker (SystemVerilog)

This project implements a **hardware-based brute-force engine** for the ARC4 (RC4) stream cipher in **SystemVerilog**.  
It provides both a standalone ARC4 cipher core and a scalable cracking framework that can search the keyspace in parallel.  

Disclaimer:  
This project is for **educational and research purposes only**. ARC4 is considered insecure and deprecated in real-world use. Do not use this code for illegal purposes.  

---

## Project Structure

```
├── crack.sv         # Cracker engine: brute-forces 24-bit RC4 keys
├── arc4.sv          # Top-level RC4 cipher core (Init + KSA + PRGA)
├── init.sv          # Initializes RC4 state array (S[i] = i)
├── ksa.sv           # Key Scheduling Algorithm
├── prga.sv          # Pseudo-Random Generation Algorithm
├── s_mem.sv         # State memory (RC4 S-box, 256 bytes)
├── pt_mem.sv        # Plaintext buffer memory
├── ct_mem.sv        # Ciphertext memory
├── doublecrack.sv   # Parallel cracker (two engines with disjoint keyspaces)
├── top.sv           # Top level module compatible with the DE1SOC
└── README.md        # Project documentation
```

---

## Features

- **ARC4 (RC4) cipher core**  
  - Implements Init, Key Scheduling (KSA), and Pseudo-Random Generation (PRGA).  
  - Parameterized for **24-bit keys** (simplified for hardware feasibility).  

- **Cracker Engine (`crack`)**  
  - Sequentially tests keys against ciphertext.  
  - Decrypts ciphertext and checks if the result is **printable ASCII text**.  
  - Stops when a valid key is found.  

- **Parallel Cracking (`doublecrack`)**  
  - Instantiates two independent cracker engines.  
  - Splits the keyspace (even vs odd keys) for faster search.  
  - Scalable design: easily extended to 4, 8, or more engines.  

---

## How It Works

1. **Ciphertext Input**  
   - Assumes ciphertext is stored in memory.  
   - First byte encodes the **plaintext message length**.  

2. **ARC4 Decryption**  
   - `init` loads the S-box with values 0–255.  
   - `ksa` permutes the S-box using the candidate key.  
   - `prga` generates the keystream and XORs with ciphertext.  

3. **Cracking Strategy**  
   - Test each candidate key (24-bit space = ~16 million keys).  
   - Validate decrypted output:
     - First byte must match declared length.  
     - All characters must be printable ASCII (`0x20 – 0x7E`).  
   - If valid → report key and halt.  

4. **Parallelism**  
   - `doublecrack` runs two `crack` engines at once.  
   - Each engine skips every other key (`INCREM=2`).  
   - Together they cover the full keyspace.  

---

## Usage

###  FPGA Deployment
1. Compile and run on a De1SOC 
2. Provide a ciphertext file/memory with known key.  
3. Observe the plaintext buffer once a key is found. 

---

## Performance

- Keyspace: **2^24 ≈ 16.7 million keys**  
- With `doublecrack`: ~8.3 million per engine.  
- Scales linearly with number of engines.  
- Brute-force feasible on mid-range FPGAs (parallelism helps).  

---

## References

- [RC4 Wikipedia](https://en.wikipedia.org/wiki/RC4)  
- "Applied Cryptography" by Bruce Schneier  
- FPGA/Hardware Security coursework 

---

