# Gemini Instructions for Blog Supabase Project

This file contains project-specific instructions, architecture rules, and workflows for the Gemini CLI agent working on the `blog_supabase` project.

## Project Overview
- **Type:** Flutter Mobile Application
- **Backend:** Supabase (Database, Auth, Storage)
- **Architecture:** Clean Architecture (Feature-driven)

## Tech Stack & Libraries
- **Framework:** Flutter / Dart
- **State Management:** `flutter_bloc` (Bloc / Cubit)
- **Dependency Injection:** `get_it` (Service Locator pattern)
- **Functional Error Handling:** `dartz` (Either, Left/Right for failures and successes)
- **Backend Integration:** `supabase_flutter`
- **Environment Variables:** `flutter_dotenv`

## Architectural Guidelines (Clean Architecture)
The project strictly follows Clean Architecture, organized by features inside the `lib/features/` directory. Each feature should have the following layers:

1. **Presentation (`presentation/`)**:
   - `screens/`: UI pages.
   - `bloc/`: State management logic using Bloc/Cubit.
   - `components/`: Reusable UI widgets specific to the feature.
   - *Rule:* The presentation layer should only interact with the Domain layer (Use Cases or Repositories directly if simple), never with the Data layer.

2. **Domain (`domain/`)**:
   - `entities/`: Pure Dart objects representing core business data.
   - `repositories/`: Abstract classes (interfaces) defining the contract for data operations.
   - *Rule:* This layer must not depend on any Flutter-specific packages or external libraries (except maybe `dartz` and `equatable`).

3. **Data (`data/`)**:
   - `models/`: Data classes that extend Entities, adding serialization/deserialization logic (e.g., `fromJson`, `toJson`).
   - `repositories/`: Concrete implementations of the Domain repository interfaces.
   - `datasources/`: Classes that actually fetch/send data to external sources (Supabase, local DB).
   - *Rule:* The Data layer handles all external APIs and data mapping.

4. **Core (`core/`)**:
   - Contains shared logic, constants, error handling (Exceptions/Failures), routing, themes, and network configurations (`supabase` clients).

## Coding Conventions
- **Dependency Injection:** Always register new Data Sources, Repositories, and Blocs in `lib/core/di/injection_container.dart` using `get_it`.
- **Error Handling:** Use `dartz`'s `Either<Failure, Type>` return types in Repositories and Domain logic. Datasources should throw custom Exceptions, which are caught and converted to Failures in the Repository implementations.
- **State Management:** Keep Bloc events and states organized. Use `equatable` for easy state comparison.
- **UI:** Follow standard Material Design principles unless specified otherwise. Use the existing `AppTheme`.

## Workflow
- Always update tests when adding new features or fixing bugs.
- After modifying dependencies, ensure you instruct the user to run `flutter pub get`.
- Ensure new features adhere to the established Clean Architecture layer separation.
