# CMakeLists.txt - Cross-platform CEF build driver (Fallback)
# Usage: cmake -B build && cmake --build build

cmake_minimum_required(VERSION 3.16)
project(BuildCEF LANGUAGES NONE)

# Detect operating system
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(HOST_OS "linux")
    set(BOOTSTRAP_SCRIPT "./scripts/bootstrap/install-docker.sh")
    set(DOCKERFILE "Dockerfile.linux")
    set(VOLUME_MOUNT "${CMAKE_SOURCE_DIR}/builds:/workspace/builds")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(HOST_OS "windows") 
    set(BOOTSTRAP_SCRIPT ".\\scripts\\bootstrap\\install-docker.ps1")
    set(DOCKERFILE "Dockerfile.windows")
    set(VOLUME_MOUNT "${CMAKE_SOURCE_DIR}/builds:C:/workspace/builds")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(HOST_OS "macos")
    set(BOOTSTRAP_SCRIPT "./scripts/bootstrap/install-docker-macos.sh") 
    set(DOCKERFILE "Dockerfile.macos")
    set(VOLUME_MOUNT "${CMAKE_SOURCE_DIR}/builds:/workspace/builds")
else()
    message(FATAL_ERROR "Unsupported operating system: ${CMAKE_SYSTEM_NAME}")
endif()

set(IMAGE_TAG "cef-builder-${HOST_OS}")
set(BUILDS_DIR "${CMAKE_SOURCE_DIR}/builds")

message(STATUS "BuildingCEF - Cross-platform CEF build system")
message(STATUS "Detected operating system: ${HOST_OS}")
message(STATUS "Using Dockerfile: ${DOCKERFILE}")

# Create builds directory
file(MAKE_DIRECTORY "${BUILDS_DIR}")

# Bootstrap Docker installation
add_custom_target(bootstrap
    COMMAND ${CMAKE_COMMAND} -E echo "[STEP 1] Ensuring Docker is installed on ${HOST_OS}"
    COMMENT "Installing Docker if needed..."
)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    add_custom_command(TARGET bootstrap POST_BUILD
        COMMAND powershell.exe -ExecutionPolicy Bypass -File "${BOOTSTRAP_SCRIPT}"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        COMMENT "Running Windows Docker bootstrap script"
    )
else()
    add_custom_command(TARGET bootstrap POST_BUILD
        COMMAND /bin/bash "${BOOTSTRAP_SCRIPT}"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        COMMENT "Running ${HOST_OS} Docker bootstrap script"
    )
endif()

# Build CEF container
add_custom_target(build-container
    COMMAND ${CMAKE_COMMAND} -E echo "[STEP 2] Building CEF container for ${HOST_OS}"
    COMMAND docker build -t ${IMAGE_TAG} -f ${DOCKERFILE} .
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    DEPENDS bootstrap
    COMMENT "Building Docker container: ${IMAGE_TAG}"
)

# Run CEF build
add_custom_target(run-build
    COMMAND ${CMAKE_COMMAND} -E echo "[STEP 3] Running CEF build container for ${HOST_OS}"
    COMMAND ${CMAKE_COMMAND} -E echo "Output directory: ${BUILDS_DIR}"
    COMMAND ${CMAKE_COMMAND} -E echo "WARNING: This will take 1-3 hours depending on hardware"
    COMMAND docker run --rm -v "${VOLUME_MOUNT}" ${IMAGE_TAG}
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    DEPENDS build-container
    COMMENT "Running CEF build in container"
)

# Create marker file
add_custom_target(create-marker
    COMMAND ${CMAKE_COMMAND} -E echo "CEF build completed successfully" > "${BUILDS_DIR}/cef_build_complete.marker"
    DEPENDS run-build
    COMMENT "Creating build completion marker"
)

# Main build target
add_custom_target(cef-build
    COMMAND ${CMAKE_COMMAND} -E echo "[SUCCESS] CEF build process completed successfully!"
    COMMAND ${CMAKE_COMMAND} -E echo "Your CEF build artifacts are ready in the 'builds/' directory"
    DEPENDS create-marker
    COMMENT "Cross-platform CEF build"
)

# Default target
add_custom_target(default ALL DEPENDS cef-build)

# Clean target
set_property(DIRECTORY PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "${BUILDS_DIR}")

# Help message
if(CMAKE_BUILD_TYPE STREQUAL "")
    message(STATUS "")
    message(STATUS "BuildingCEF Usage:")
    message(STATUS "  cmake -B build && cmake --build build")
    message(STATUS "  cmake --build build --target cef-build")
    message(STATUS "  cmake --build build --target clean")
    message(STATUS "")
    message(STATUS "Requirements:")
    message(STATUS "  - Windows: Run from Administrator Command Prompt")
    message(STATUS "  - Linux/macOS: Regular user privileges")
    message(STATUS "")
    message(STATUS "Build process:")
    message(STATUS "  1. Install Docker if not present")
    message(STATUS "  2. Build CEF container for ${HOST_OS}")
    message(STATUS "  3. Run CEF build (1-3 hours)")
    message(STATUS "  4. Output to builds/ directory")
    message(STATUS "")
endif()
