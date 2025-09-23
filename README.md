**`README.md`**

````markdown
# 🏨 Rezerwacja Noclegów — API (NestJS + MongoDB)

Minimal Viable Product (MVP) aplikacji backendowej do rezerwacji noclegów.  
Projekt zrealizowany w **NestJS + MongoDB**, gotowy do uruchomienia w kontenerach **Docker**.

---

## 📦 Stack technologiczny

- [NestJS](https://nestjs.com/) — framework Node.js dla backendu
- [MongoDB](https://www.mongodb.com/) — baza danych dokumentowa
- [Mongoose](https://mongoosejs.com/) — ODM dla MongoDB
- [Docker + docker-compose](https://docs.docker.com/) — uruchamianie środowiska
- [JWT](https://jwt.io/) — autoryzacja użytkowników
- [Swagger](https://swagger.io/) — dokumentacja REST API
- [class-validator](https://github.com/typestack/class-validator) — walidacja DTO

---

## 📂 Struktura modułów

- **Auth** — logowanie, generowanie tokenów JWT
- **Users** — rejestracja, profil użytkownika, sprawdzanie dostępności loginu/e-maila
- **Rooms** — CRUD pokoi, like/dislike, rezerwacje z walidacją właściciela
- **Common** — współdzielone DTO i interfejsy (np. `HealthResponseDto`, `RequestWithUser`)
- **Filters** — globalne filtry wyjątków (np. `HttpExceptionFilter`)
- **Config** — centralna konfiguracja środowiska (plik `.env`)

---

## ⚙️ Uruchamianie

### 1. Wymagania
- Node.js 20+
- Docker + Docker Compose
- npm

### 2. Klonowanie repozytorium
```bash
git clone https://github.com/trak2026z/rezerwacja-noclegow-nest2.git
cd rezerwacja-noclegow-nest2
````

### 3. Uruchomienie środowiska developerskiego

```bash
docker compose -f docker-compose.dev.yml up --build
```

Aplikacja będzie dostępna pod:

* API: [http://localhost:3000](http://localhost:3000)
* Swagger: [http://localhost:3000/api](http://localhost:3000/api)
* MongoDB: `localhost:27017`

---

## 🔑 Konfiguracja

Plik `.env.dev`:

```env
PORT=3000
NODE_ENV=development
MONGO_URI=mongodb://mongo:27017/bookings
JWT_SECRET=dev_secret_change_me
JWT_EXPIRES=1d
```

---

## 🚀 Najważniejsze endpointy

### Auth

POST `/auth/login` — logowanie (JWT)

### Users

POST `/users/register` — rejestracja
GET `/users/profile` — profil użytkownika (JWT)
GET `/users/{username}` — publiczny profil
GET `/users/availability/email?email=xxx` — sprawdzanie e-maila
GET `/users/availability/username?username=xxx` — sprawdzanie loginu

### Rooms

POST `/rooms` — tworzenie pokoju (JWT)
GET `/rooms` — lista pokoi
GET `/rooms/{id}` — szczegóły pokoju
PUT `/rooms/{id}` — pełna edycja pokoju (JWT, właściciel)
PATCH `/rooms/{id}` — częściowa edycja pokoju (JWT, właściciel)
DELETE `/rooms/{id}` — usunięcie pokoju (JWT, właściciel)
POST `/rooms/{id}/like` — polubienie pokoju (JWT, bez reakcji właściciela)
POST `/rooms/{id}/dislike` — dislike pokoju (JWT, bez reakcji właściciela)
POST `/rooms/{id}/reserve` — rezerwacja pokoju (JWT, właściciel zablokowany, pojedyncza rezerwacja)

---

## 🧪 Testowanie

Testy e2e uruchamiane przez:

```bash
npm run test:e2e
```

---

## 📖 Dokumentacja API

Swagger dostępny po uruchomieniu serwera:

```
http://localhost:3000/api
```

---

## ⚡️ Quick start (curl)

### Rejestracja

```bash
curl -X POST http://localhost:3000/users/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","username":"testuser","password":"Secret123"}'
```

### Logowanie

```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"emailOrUsername":"testuser","password":"Secret123"}'
```

### Utworzenie pokoju (z tokenem)

```bash
curl -X POST http://localhost:3000/rooms \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"title":"Pokój z widokiem na morze","body":"Świetny pokój w Gdańsku","city":"Gdańsk"}'
```

---

## 👨‍💻 Autor

Projekt MVP przygotowany jako przykład aplikacji backendowej w NestJS.
