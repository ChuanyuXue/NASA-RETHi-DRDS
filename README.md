# Data Distribution Service for NASA RETHi Project

This repository contains the source code of Data Repository System of NASA-RETHi project. The whole RETHi project aims to develop the Resilient Extra-Terrestrial Habitats for future Moon/Mars expedition, which is divided into three related research thrusts:

1. **System Resilience** develop the techniques needed to establish a control-theoretic paradigm for resilience, and the computational capabilities needed to capture complex behaviors and perform trade studies to weigh different choices regarding habitat architecture and onboard decisions.
2. **Situational Awareness** develop and validate generic, robust, and scalable methods for detection and diagnosis of anticipated and unanticipated faults that incorporates an automated active learning framework with robots- and humans-in-the-loop.
3. **Robotic Maintenance** develop and demonstrate the technologies needed to realize teams of independent autonomous robots, incorporating the use of soft materials, that navigate through dynamic environments, use a variety of modular sensors and end-effectors for specific needs, and perform tasks such as collaboratively replacing damaged structural elements using deployable modular hardware.

Please visit https://www.purdue.edu/rethi for more information.

## Project motivation 

Data distribution service is an important component in the extra-terrestrial habitat system and plays a key role in sensor monitoring, data remaining, communication, and decision making.  

The primary concern of any outer space activity is ensuring safety, which usually involves tons of sensor data from several different subsystems, i.e. power system, interior environment system, and intervention agents to monitoring and controlling. How to ensure the real-time guarantee and 

## Project Structure


## Plan & Deliverables

A key issue in the current code is using "Run" with GoLang instead of directly using "go" keyword to start a new process. This bad idea is from the design of Java and Python style which generally implement the "Run" function of parent class. Another drawback is only "Listen" needs to run in the backend, it makes the system complicated to add "Run" function.(When multi-function doing in backend Run interface is necessary.)



<img src="./img/nasa_logo.jpg" width="50" height="50"> *This project is supported by the National Aeronautics and Space Administration*
