# konnect-showcase
## Overview
This is a personal project — a social app where users can match and interact with each other. There is a feed with profiles where users can send a message to the profiles they see, then there is a page where the users can see the first messages they have received, without revealing the sender. If both users send a first message to each other a "match" happens and they can see each other and exchange messages. Each user can upload images and write a small bio for his profile that others can see.


## Tech Stack
* Backend: Go (monolith)
* Frontend: Flutter (mobile app)
* Database: PostgreSQL hosted on AWS RDS
* Authentication: JWT-based auth
* Real-Time Communication: WebSockets
* Storage: AWS S3 (signed URLs for image uploads/downloads)
* Notifications: Firebase Cloud Messaging (Android)
* Email Service: Brevo
* Deployment: API served over HTTPS on a purchased domain, backend hosted on AWS EC2

The backend is deployed on a personal domain over HTTPS on an EC2 istance at AWS and supports authentication, real-time messaging, notifications, and image uploads.
The Flutter frontend interacts with the backend through REST APIs and WebSockets.

## Component Diagram:
<p align="center">
<img src="https://github.com/user-attachments/assets/5ac7f891-9934-47e5-ab01-80e84f046a4e" width="850" alt="Component Diagram" />
</p>

## Some Sequence Diagrams: 

**User Registration:**
<p align="center">
<img width="850" alt="image" src="https://github.com/user-attachments/assets/3a2a3e30-312b-41a7-b3eb-2aa6d3e3ed6b" />
</p>

**User Sends a Request:**
<p align="center">
<img width="850" alt="image" src="https://github.com/user-attachments/assets/3dff83ee-af63-47bf-a765-2502a9685b54" />
</p>

**User Uploads an Image to S3:**
<p align="center">
<img width="850" alt="image" src="https://github.com/user-attachments/assets/eb68053c-1bf5-4bbf-8b62-600f4bc830aa" />
</p>




## App Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/67b96d5a-cc1c-4c41-b0e2-0b1b3edad48c" width="180" />
  <img src="https://github.com/user-attachments/assets/ee048d99-892f-43bb-9e6d-91996ddf793e" width="180" />
  <img src="https://github.com/user-attachments/assets/e7cbeb55-ca0a-4fed-b9f1-2e7263983667" width="180" />
  <img src="https://github.com/user-attachments/assets/244ef70e-5ae0-41f5-94a0-236cca079c5f" width="180" />
  <img src="https://github.com/user-attachments/assets/c5af359e-6397-435a-be57-b94b105fe151" width="180" />
</p>



> Note: The full backend source code is private as I aim to publish the app on the playstore.  
> This repository demonstrates the architecture, workflows, screenshots.
