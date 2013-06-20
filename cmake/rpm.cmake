
find_program(RPMBUILD rpmbuild)
find_program(MKDIR mkdir)
find_program(CP cp)
find_program(WC wc)

execute_process (COMMAND ${GIT} describe HEAD --abbrev=0
    OUTPUT_VARIABLE VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)

execute_process (COMMAND ${GIT} rev-list --oneline ${VERSION}..
    COMMAND ${WC} -l
    OUTPUT_VARIABLE RELEASE
    OUTPUT_STRIP_TRAILING_WHITESPACE)

set (RPM_PACKAGE_VERSION ${VERSION} CACHE STRING "" FORCE)
set (RPM_PACKAGE_RELEASE ${RELEASE} CACHE STRING "" FORCE)

set (RPM_SOURCE_DIRECTORY_NAME ${CPACK_SOURCE_PACKAGE_FILE_NAME}
     CACHE STRING "" FORCE)
set (RPM_PACKAGE_SOURCE_FILE_NAME ${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.gz
     CACHE STRING "" FORCE)

set (RPM_ROOT "${PROJECT_BINARY_DIR}/RPM" CACHE STRING "" FORCE)
set (RPM_BUILDROOT "${RPM_ROOT}/BUILDROOT" CACHE STRING "" FORCE)

add_custom_command(OUTPUT ${PROJECT_SOURCE_DIR}/${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.gz
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMAND $(MAKE) package_source)

add_custom_command(OUTPUT ${RPM_ROOT}
    COMMAND ${MKDIR} -p ${RPM_ROOT}/BUILD ${RPM_ROOT}/BUILDROOT
            ${RPM_ROOT}/SOURCES)

add_custom_target(rpm
    DEPENDS ${RPM_ROOT}
    DEPENDS ${PROJECT_SOURCE_DIR}/${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.gz
    COMMAND ${CP} ${PROJECT_BINARY_DIR}/${RPM_PACKAGE_SOURCE_FILE_NAME}
            ${RPM_ROOT}/SOURCES
    COMMAND ${RPMBUILD} --buildroot ${RPM_BUILDROOT} -bb ${PROJECT_SOURCE_DIR}/extra/rpm.spec
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR})

add_custom_target(rpm_src
    DEPENDS ${RPM_ROOT}
    DEPENDS ${PROJECT_SOURCE_DIR}/${CPACK_SOURCE_PACKAGE_FILE_NAME}.tar.gz
    COMMAND ${CP} ${PROJECT_BINARY_DIR}/${RPM_PACKAGE_SOURCE_FILE_NAME}
            ${RPM_ROOT}/SOURCES
    COMMAND ${RPMBUILD} --buildroot ${RPM_BUILDROOT} -bs ${PROJECT_SOURCE_DIR}/extra/rpm.spec
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR})