# Nova Health

Nova Health is a comprehensive Hospital Management System (HMS) designed to streamline healthcare operations, enhance patient care, and improve administrative efficiency. This monorepo functionality for patients, doctors, and administrators across web and mobile platforms.

## 🚀 Features

- **Multi-Platform Support**:
  - **Admin Web Dashboard**: Built with Next.js for hospital administrators to manage resources, staff, and appointments.
  - **Doctor & Patient Mobile App**: Built with Flutter for cross-platform access (iOS/Android) for doctors to manage schedules and patients to book appointments.
  - **Typesafe API**: Robust NestJS backend serving all client applications.

- **Core Functionality**:
  - **Appointment Management**: Complete booking flow, rescheduling, and cancellations.
  - **Doctor Profiles**: Detailed profiles with specializations, availability, and ratings.
  - **Organization Management**: Multi-tenant structure supporting various hospital branches.
  - **Prescription System**: Digital prescription management accessible by relevant parties.

## 🛠️ Tech Stack

- **Backend**: [NestJS](https://nestjs.com/) (Node.js)
- **Admin Frontend**: [Next.js](https://nextjs.org/) (React)
- **Mobile App**: [Flutter](https://flutter.dev/) (Dart)
- **Database**: PostgreSQL (managed via Prisma ORM)
- **Infrastructure**: Docker & Docker Compose

## 📂 Project Structure

- `backend-api`: NestJS backend server (API & Logic).
- `website-frontend`: Next.js web application for administrators.
- `mobile-frontend`: Flutter mobile application for Doctors & Patients.
- `database`: Docker infrastructure and database configuration.

## 🏁 Getting Started

### Prerequisites

- Node.js (v18+)
- Flutter SDK
- Docker & Docker Compose

### Running Locally

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Rishabh5649/Nova_Health.git
    cd Nova_Health
    ```


2.  **Start the Backend:**
    ```bash
    cd backend-api
    npm install
    npm run start:dev
    ```

3.  **Start the Admin Web App:**
    ```bash
    cd website-frontend
    npm install
    npm run dev
    ```

4.  **Run the Mobile App:**
    ```bash
    cd mobile-frontend
    flutter pub get
    flutter run
    ```

## 📄 License

This project is licensed under the MIT License.
