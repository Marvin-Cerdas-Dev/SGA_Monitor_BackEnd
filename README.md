# 📊 SGA Monitor - Backend

Welcome to the **SGA Monitor Backend**, a system designed to connect with an Oracle database to monitor and analyze the status of the **System Global Area (SGA)** in real-time. This backend provides various endpoints to retrieve key data on memory usage, tablespaces, and system events, facilitating in-depth performance analysis for database administrators.

---

## 📋 Table of Contents
1. [Project Overview](#-project-overview)
2. [Requirements](#-requirements)
3. [Installation](#-installation)
4. [Project Structure](#-project-structure)
5. [Endpoints and Functionalities](#-endpoints-and-functionalities)
6. [Running the Application](#-running-the-application)

---

## 🖥️ Project Overview
The backend of **SGA Monitor** is built using **Flask** and utilizes **cx_Oracle** to interact with an Oracle database. It offers multiple endpoints to:
- Query the SGA memory state.
- Retrieve event information on memory usage exceeding defined limits.
- Access tablespace volumetrics to monitor database storage usage.

## 🔧 Requirements
- **Python 3.6+**
- **Flask** and **cx_Oracle** libraries
- Access to an **Oracle Database** with necessary tables (`traffic_memory_state`, `event_info`, etc.)

## ⚙️ Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Marvin-Cerdas-Dev/SGA_Monitor_BackEnd.git
   cd SGA_Monitor_BackEnd
   ```
2. (Optional) Create a virtual environment:
   ```bash
   python -m venv env
   source env/bin/activate  # On Windows: env\Scripts\activate
   ```
3. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Configure the application:
   - Modify the `config.py` file to provide the necessary database connection details and any other required settings.

## 📁 Project Structure
The project follows a standard Flask application structure:
```
SGA_Monitor_BackEnd/
├── api.py
├── requirements.txt
└── SQL Files/
   ├── Monitor2_Tablespaces.sql
   ├── SGA-Del.sql
   ├── SGA-N.sql
   ├── SGA-Update.sql
   ├── SGA.sql
   ├── SQL-Monitor2.sql
   ├── TablesSpaces.sql
   └── XE.sql

```

## 🌐 Endpoints and Functionalities
The SGA Monitor Backend exposes the following endpoints:

**GET /getData/<id>**
 - Retrieves data based on the provided id parameter.

**GET /consultaEjemplo**
- Executes a sample database query and returns the results.

**GET /traffic-memory-state**
- Fetches the current state of the traffic memory, including total memory used and memory percentage.

**GET /event_info**
- Retrieves event information related to high memory usage.

**GET /tablespaces_volumetria**
- Provides detailed information about the database's tablespaces, including size, usage, and growth rates.

## 🚀 Running the Application
1. Ensure that you have the necessary Oracle database connection details and permissions.
2. Start the Flask application:
   ```bash
   python api.py
   ```
3. The backend will be accessible at `http://localhost:5000`.

---

## 📜 License
This project is licensed under the [MIT License](LICENSE).

## 🤝 Contact
Marvin Cerdas - [GitHub Profile](https://github.com/Marvin-Cerdas-Dev)
