# Define options for Spack's installation and configuration
option(INLINE_SPACK_INSTALLATION "Install Spack and packages in-line" ON)
set(SPACK_DOWNLOAD_URL "https://github.com/spack/spack.git" CACHE STRING "URL to download Spack from")
set(SPACK_TAG "v0.20.1" CACHE STRING "Tag of Spack to use")
set(SPACK_INSTALL_DIR "${CMAKE_BINARY_DIR}/spack" CACHE STRING "Directory to install Spack")

include(ExternalProject)

function(setup_spack_config)
    # Modify config.yaml to ensure all files are inside the build/spack folder
    set(config_yaml "${SPACK_INSTALL_DIR}/etc/spack/defaults/config.yaml")
    file(READ ${config_yaml} content)

    # Update paths in config.yaml
    string(REPLACE "$spack/opt/spack" "${SPACK_INSTALL_DIR}/opt/spack" content "${content}")
    string(REPLACE "$tempdir/$user/spack-stage" "${SPACK_INSTALL_DIR}/tmp/spack-stage" content "${content}")
    string(REPLACE "$user_cache_path/stage" "${SPACK_INSTALL_DIR}/tmp/user-stage" content "${content}")
    string(REPLACE "$user_cache_path/test" "${SPACK_INSTALL_DIR}/tmp/user-test" content "${content}")
    string(REPLACE "$spack/var/spack/cache" "${SPACK_INSTALL_DIR}/cache" content "${content}")
    string(REPLACE "$user_cache_path/cache" "${SPACK_INSTALL_DIR}/tmp/user-cache" content "${content}")

    file(WRITE ${config_yaml} "${content}")
endfunction()

function(download_spack)
    # Clone Spack repository
    execute_process(
            COMMAND ${GIT_FOUND} clone ${SPACK_DOWNLOAD_URL} ${SPACK_INSTALL_DIR}
            RESULT_VARIABLE result_clone
    )

    if(result_clone)
        message(FATAL_ERROR "Failed to clone Spack from ${SPACK_DOWNLOAD_URL}")
    endif()

    # Checkout the specified tag/version
    execute_process(
            COMMAND ${GIT_FOUND} -c advice.detachedHead=false checkout ${SPACK_TAG}
            WORKING_DIRECTORY ${SPACK_INSTALL_DIR}
            RESULT_VARIABLE result_checkout
    )

    if(result_checkout)
        message(FATAL_ERROR "Failed to checkout Spack version/tag ${SPACK_TAG}")
    endif()

    set(spack_bin "${SPACK_INSTALL_DIR}/bin/spack")
endfunction()

function(setup_spack_compilers)
    # Initialize Spack with compiler detection
    set(spack_bin "${SPACK_INSTALL_DIR}/bin/spack")
    execute_process(
            COMMAND ${spack_bin} compiler find
            RESULT_VARIABLE result_compiler_find
    )

    if(result_compiler_find)
        message(FATAL_ERROR "Failed to initialize Spack's compiler detection!")
    endif()
endfunction()

function(setup_spack)
    # Check if Spack is already installed
    find_program(SPACK_FOUND spack PATHS ${SPACK_INSTALL_DIR}/bin NO_DEFAULT_PATH)
    find_program(GIT_FOUND git)
    if(NOT GIT_FOUND)
        message(FATAL_ERROR "Git not found! Please ensure Git is installed and available in the system's PATH.")
    endif()

    if(NOT SPACK_FOUND)
        download_spack()
        setup_spack_config()
        setup_spack_compilers()
        message(STATUS "Spack installed")
    else()
        message(STATUS "Spack already installed")
    endif()
endfunction()

function(install_spack_packages)
    foreach(package_name ${ARGN})
        set(spack_prefix "${CMAKE_BINARY_DIR}/_deps/spack")
        set(spack_bin "${spack_prefix}/src/spack/bin/spack")

        execute_process(
                COMMAND ${spack_bin} install ${package_name}
                RESULT_VARIABLE result
        )

        if(result)
            message(FATAL_ERROR "Failed to install ${package_name} using Spack!")
        endif()

        # Ensure Spack is sourced and available
        set(ENV{SPACK_ROOT} "${spack_prefix}/src/spack")

    endforeach()
endfunction()

function(spackCM)
    # Ensure Spack is set up
    setup_spack()

#    if(INLINE_SPACK_INSTALLATION)
#        # Install the packages using Spack in-line
#        install_spack_packages(${ARGN})
#        # Find each package
#        foreach(package_name ${ARGN})
#            find_package(${package_name} REQUIRED)
#        endforeach()
#    else()
#        # Create a custom target to handle the installation
#        add_custom_target(install_deps
#                COMMAND ${CMAKE_COMMAND} -E env SPACK_ROOT=${CMAKE_BINARY_DIR}/_deps/spack/src/spack ${CMAKE_COMMAND} -Dpackages="${ARGN}" -DINSTALL_SPACK_PACKAGES=1 -P ${CMAKE_CURRENT_LIST_FILE}
#                COMMENT "Installing dependencies using Spack"
#                )
#    endif()
endfunction()

## Check if the custom target is being executed
#if(INSTALL_SPACK_PACKAGES)
#    # Convert the semicolon-separated list back to a CMake list
#    string(REPLACE ";" " " packages_list "${packages}")
#
#    # Install the packages using Spack
#    install_spack_packages(${packages_list})
#
#    # Find each package
#    foreach(package_name ${packages_list})
#        find_package(${package_name} REQUIRED)
#    endforeach()
#endif()
