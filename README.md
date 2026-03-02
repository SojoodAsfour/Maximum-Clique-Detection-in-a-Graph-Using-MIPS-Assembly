# 🖥️ ENCS4370 – Project #1  
## Maximum Clique Detection in a Graph Using MIPS Assembly

🎓 Birzeit University    

---

## 📌 Project Overview

This project implements a **Maximum Clique Detection algorithm** using **MIPS Assembly language**.

A **clique** in an undirected graph is a subset of vertices such that every two distinct vertices are connected by an edge.

A **maximum clique** is the clique containing the largest number of vertices in the graph.

Since maximum clique detection is an **NP-Complete problem**, the graph size is limited to **maximum 5 vertices** and a brute-force approach is used.

---

## 🎯 Project Requirements

The program must:

1️⃣ Read a graph from an input text file (Adjacency Matrix format)  
2️⃣ Detect the maximum clique (if any)  
3️⃣ Write the results into an output text file  


---

## ⚙️ Implementation Details

### 🧠 Algorithm
- Brute-force subset generation
- Check all possible vertex subsets
- Validate clique condition
- Track maximum size

### 📦 Data Structures
- Adjacency matrix stored in memory
- Vertex combinations generated using bitmasking approach
- Registers used for subset validation and counting

---

## 🖥️ Program Features

✅ Prompt user to enter input file path  
✅ Validate file existence  
✅ Validate adjacency matrix format  
✅ Error handling for invalid input  
✅ Maximum clique detection logic  
✅ Write results to output file  
✅ Proper commenting and structured assembly code  

---


---

## 🛠️ Tools Used

- MARS MIPS Simulator (Mars4_5.jar)
- MIPS Assembly Language
- File I/O syscalls

---

## 🧪 Error Handling

The program handles:

- ❌ File not found
- ❌ Invalid adjacency matrix
- ❌ Incorrect matrix size
- ❌ Non-binary matrix values

---

## 🧩 Constraints

- Maximum graph size: 5 vertices
- Undirected graph
- No self-loops (diagonal = 0)

---

## 🚀 Learning Outcomes

This project strengthened understanding of:

- Assembly programming
- Memory management in MIPS
- File I/O in low-level systems
- Graph theory fundamentals
- NP-Complete problems
- Algorithm implementation without high-level libraries

---
