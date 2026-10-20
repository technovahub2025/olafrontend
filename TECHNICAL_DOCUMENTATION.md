# Technical Documentation — Taxi App `lib/`

## Scope

This document describes every file currently under this `lib` directory (94 files, based on the inventory at authoring time). It is a source-level map of the Flutter/Dart client. Dependency versions, platform setup, build commands, and server contracts are not specified here because the package manifest and platform directories are outside this directory. Descriptions summarize source responsibilities; they do not imply that a remote endpoint or flow has been integration-tested.

## Application overview

The codebase is a Flutter taxi booking client with customer, driver, and admin experiences. The entry point (`main.dart`) initializes environment configuration and registers Provider-based state objects, then opens the customer splash flow. The customer and driver areas use HTTP services and local session storage; socket clients support live booking/driver events; Google Maps and location packages support map screens. The admin area has separate models, services, providers, screens, and route definitions.

### Main data flow

1. `main.dart` loads `.env`, sets up providers, theme, and initial navigation.
2. Screens collect user input and call service classes.
3. Service classes serialize/deserialize JSON models and communicate with configured or hard-coded API endpoints.
4. Provider classes expose mutable state to widgets through `ChangeNotifier`.
5. `tokenmagemet/` persists role-specific/session credentials using SharedPreferences.
6. Booking and presence features use HTTP and/or Socket.IO; map screens use location, geocoding, directions, and Google Maps SDKs.

## Configuration and operational notes

- `core/config.dart` reads `BASE_URL` from dotenv and otherwise falls back to `https://ola-7ii1.onrender.com`; `apiBaseUrl` and `socketUrl` return that same base URL.
- `main.dart` requires `.env` to load at startup and checks `GOOGLE_MAPS_API_KEY` presence. The key's actual platform wiring is outside `lib`.
- Several service classes define their own endpoint URLs, so `BASE_URL` is not necessarily the sole source of API configuration.
- Session implementations are distinct for customer, driver, and admin contexts; callers should be checked before changing key names or logout behavior.
- There are duplicate/overlapping model and screen types across directories. For example, user/driver models live in `data/`, `drivermodel/`, and `adminmodel/`; customer booking history has legacy and `_new` variants. Confirm imports and navigation before consolidating.
- `presentation/screen/mapscreen_temp.dart` imports `dart:html`, which is web-specific. Check target-platform compilation if this file is imported by a build.
- `presentation/screen/bookingscreen.dart` is present but contains no declarations in the source scan; treat it as empty/reserved until implemented.

## File reference

### App entry and shared core

| File | Responsibility |
|---|---|
| `main.dart` | Flutter entry point. Initializes bindings, Google Maps Android surface behavior, dotenv, MultiProvider, app theme, routes, and initial customer splash screen. |
| `core/color.dart` | Shared color constants used by UI. |
| `core/config.dart` | Resolves API and socket base URLs from dotenv with a production fallback. |

### Customer and shared data models (`data/`)

| File | Responsibility |
|---|---|
| `data/bookingmodel.dart` | Booking entity and JSON parsing/field normalization used by customer and booking services. |
| `data/drivermodel.dart` | Driver/user listing model used by customer-side driver discovery and related services. |
| `data/driverprofilemodel.dart` | Driver profile data model used by the profile-list presentation/provider path. |
| `data/loginmodel.dart` | Customer login request and response models. |
| `data/profilemodel.dart` | Customer profile model representation. |
| `data/registermodel.dart` | Registration/user response models used by customer and service code. |

### Customer domain services and providers (`domain/`)

| File | Responsibility |
|---|---|
| `domain/bookingservice.dart` | Customer booking API: create, retrieve/filter, update status, cancel, and payment-related operations; attaches session authorization and maps responses to booking models. |
| `domain/driverappservice.dart` | Socket.IO client for driver-side booking events, including connect, accept/reject, event filtering, and disconnect. |
| `domain/driverservice.dart` | HTTP access to the driver/user listing endpoint, returning `data/drivermodel.dart` models. |
| `domain/userappservice.dart` | Socket.IO client for customer-side live app/booking events. |
| `domain/service/driverprofile.dart` | HTTP service for fetching or updating driver profile information. |
| `domain/service/locationprovider.dart` | ChangeNotifier holding pickup/destination/map location state and nearby taxi markers; includes a local random helper. |
| `domain/service/loginservice.dart` | Customer authentication HTTP client and login response handling. |
| `domain/service/registerservice.dart` | Customer registration HTTP client and response handling. |
| `domain/service/userprovider.dart` | ChangeNotifier managing the customer-side driver/user collection and related loading/error state. |

### Driver data models (`drivermodel/`)

| File | Responsibility |
|---|---|
| `drivermodel/drivermodel.dart` | Driver-domain user model. It overlaps with `data/drivermodel.dart`; compare imports before changing. |
| `drivermodel/loginmodel.dart` | Driver login request and response models. |
| `drivermodel/registermodel.dart` | Driver registration/user response models. |

### Driver screens (`driverscreen/`)

| File | Responsibility |
|---|---|
| `driverscreen/bookingscreen.dart` | Driver booking list UI, booking filtering/cards, logout handling, and navigation into ride flow. |
| `driverscreen/captchascreen.dart` | Driver-side CAPTCHA UI and verification request flow. |
| `driverscreen/driverhomescreen.dart` | Driver home/navigation shell linking bookings and profile. |
| `driverscreen/driverprofile.dart` | Driver discovery/presence screen with Socket.IO online status and ride request presentation. |
| `driverscreen/driverprofilescreen.dart` | Driver profile editing UI, image selection, status/details display, and logout. |
| `driverscreen/login.dart` | Driver login form and authentication/navigation flow. |
| `driverscreen/ridescreen.dart` | Ride details/navigation map view using Google Maps and booking information. |
| `driverscreen/ridescreen_simple.dart` | Alternate/simple ride map screen with location updates and route display. |

### Driver services (`driverservice/`)

| File | Responsibility |
|---|---|
| `driverservice/bookingservice.dart` | Driver booking API operations and booking response model. |
| `driverservice/driverprofileservice.dart` | Driver profile fetch/update API and profile representation. |
| `driverservice/driverservice.dart` | Retrieves driver/user directory information for driver features. |
| `driverservice/loginservice.dart` | Driver authentication API and credential/session handling. |
| `driverservice/paymentservice.dart` | Driver-facing payment API operations. |
| `driverservice/registerservice.dart` | Driver registration API client. |

### Driver widgets (`driverwidegts/`)

| File | Responsibility |
|---|---|
| `driverwidegts/button.dart` | Reusable driver-area button widget. |
| `driverwidegts/loginfield.dart` | Reusable driver login text field. |
| `driverwidegts/textfield.dart` | Reusable driver text input widget. |

### Admin models (`adminmodel/`)

| File | Responsibility |
|---|---|
| `adminmodel/authmodel.dart` | Admin auth user, login request, and generic API response models. |
| `adminmodel/bookingmodel.dart` | Admin booking data model. |
| `adminmodel/profilemodel.dart` | Admin profile model. |
| `adminmodel/response.dart` | Authentication response envelope referring to the admin auth model. |
| `adminmodel/usermodel.dart` | Admin user model. |

### Admin services and state (`adminservice/`)

| File | Responsibility |
|---|---|
| `adminservice/adminprovider.dart` | ChangeNotifier for admin booking/profile data and screen-facing loading/error state. |
| `adminservice/authservice.dart` | Admin authentication API client. |
| `adminservice/bookingservice.dart` | Admin booking API client and booking data retrieval. |
| `adminservice/imageservice.dart` | Image/file picker adapters and image utility helpers. |
| `adminservice/profileservice.dart` | Admin profile API client and URL-launch helper behavior. |
| `adminservice/provider.dart` | ChangeNotifier for admin-managed user/profile listing and operations. |

### Admin widgets (`adminwidget/`)

| File | Responsibility |
|---|---|
| `adminwidget/button.dart` | Reusable admin button widget. |
| `adminwidget/inputbox.dart` | Stateful admin input field, including its controller/focus behavior. |
| `adminwidget/profiletextfield.dart` | Reusable admin profile text field. |

### Admin screens and navigation (`presentation/adminscreen/`, `routes/`)

| File | Responsibility |
|---|---|
| `presentation/adminscreen/adminhome.dart` | Admin dashboard with statistics, actions, recent bookings, and driver status sections. |
| `presentation/adminscreen/loginscreen.dart` | Admin sign-in UI and navigation to user management. |
| `presentation/adminscreen/register.dart` | Admin registration UI. |
| `presentation/adminscreen/splash.dart` | Admin splash/entry screen. |
| `presentation/adminscreen/userform.dart` | Add/edit admin-managed user form backed by provider state. |
| `presentation/adminscreen/userlist.dart` | Admin user listing, search/filter UI, drawer, and logout controls. |
| `routes/adminroutes.dart` | Named route definitions for admin splash, login, registration, and user list flows. |

### Customer screens (`presentation/screen/`)

| File | Responsibility |
|---|---|
| `presentation/screen/bookinghistory.dart` | Customer booking history with search, status/date filters, speech input, detail display, and payment navigation. |
| `presentation/screen/bookinghistory_new.dart` | Newer/alternate booking history screen with tabs, booking details, payment dialog, and contact actions. |
| `presentation/screen/bookingscreen.dart` | Empty source file at the time of inventory; no implementation documented. |
| `presentation/screen/bookingtaxi.dart` | Booking confirmation/details UI; creates bookings and coordinates customer live events/contact actions. |
| `presentation/screen/bottomnavbar.dart` | Customer bottom navigation shell connecting dashboard, history, driver, and profile sections. |
| `presentation/screen/captchascreen.dart` | Customer CAPTCHA UI and verification request flow. |
| `presentation/screen/dashboard.dart` | Customer home dashboard, search/speech interaction, carousel/map entry, and drawer navigation. |
| `presentation/screen/driverprofile.dart` | Customer driver browser with search, speech input, live socket events, and booking initiation. |
| `presentation/screen/livetracking.dart` | Map-based ride tracking screen with pickup/drop markers, route line, and simulated driver-position updates. |
| `presentation/screen/login.dart` | Customer login form and authentication/session navigation. |
| `presentation/screen/mapscreen.dart` | Customer map/place selection flow with geolocation, suggestions, geocoding, route helpers, and booking navigation. |
| `presentation/screen/mapscreen_temp.dart` | Alternate/temporary map screen; includes web-only `dart:html` map availability handling. |
| `presentation/screen/paymentstatus.dart` | Payment outcome/status presentation screen. |
| `presentation/screen/payment_screen.dart` | Booking payment UI and payment-method launching/status feedback. |
| `presentation/screen/profile.dart` | Customer profile and QR display; loads profile/contact information and listens for socket updates. |
| `presentation/screen/profile_details.dart` | Customer profile details fetch/edit form. |
| `presentation/screen/recentbook.dart` | Recent order/booking summary widget populated from driver/user service data. |
| `presentation/screen/register.dart` | Customer registration form and registration service integration. |
| `presentation/screen/roleselection.dart` | Role chooser routing to customer, driver, or admin authentication. |
| `presentation/screen/splash.dart` | Customer splash/session gate leading to login, welcome, or main navigation. |
| `presentation/screen/toprate.dart` | Top-rated/recent driver listing widget. |
| `presentation/screen/welcomescreen.dart` | Customer welcome/onboarding screen with entry to the main app. |

### Customer legal/info screens (`presentation/screen/security/`)

| File | Responsibility |
|---|---|
| `presentation/screen/security/aboutus.dart` | Static About Us information screen. |
| `presentation/screen/security/condition.dart` | Static terms and conditions screen. |
| `presentation/screen/security/privacypolicy.dart` | Static privacy policy screen with formatted policy sections/date. |

### Shared presentation widgets (`presentation/widegts/`)

| File | Responsibility |
|---|---|
| `presentation/widegts/button.dart` | Reusable customer-facing button widget. |
| `presentation/widegts/drawer.dart` | Customer app drawer with navigation to legal/information pages. |
| `presentation/widegts/driverprofile.dart` | Driver profile list/card presentation backed by Provider data. |
| `presentation/widegts/loginfield.dart` | Reusable customer login field widget. |
| `presentation/widegts/textfield.dart` | Reusable customer text input widget. |

### Shared utilities, services, and session storage

| File | Responsibility |
|---|---|
| `services/driver_filter_service.dart` | Driver filter state, filter/sort application, filter summary/count, and filter controls widget. |
| `services/voice_capture_service.dart` | Speech recognition, microphone permission, silence timer, optional audio/file handling, and voice capture widget. |
| `tokenmagemet/admintoken.dart` | Admin-specific SharedPreferences token storage helpers. |
| `tokenmagemet/drivertoken.dart` | Driver `SessionManager` for persisting and retrieving driver credentials/session data. |
| `tokenmagemet/tokenstorage.dart` | Customer `SessionManager` for token, ID, user/profile data, registered name, JWT ID fallback extraction, and session clearing. |

## Maintenance guidance

- Keep request/response parsing in models and service boundaries, and keep widget code responsible for rendering and user interaction.
- Before modifying an endpoint, search all callers because similar booking/auth/profile operations exist in customer, driver, and admin namespaces.
- Preserve JSON field compatibility with the backend when editing model constructors or serializers.
- Review platform-specific imports, permission requirements, map key configuration, and socket lifecycle when changing map, speech, image, or live-update features.
- Update this inventory when files are added, removed, or repurposed.
