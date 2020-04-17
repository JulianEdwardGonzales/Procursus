ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += file
DOWNLOAD       += ftp://ftp.astron.com/pub/file/file-$(FILE_VERSION).tar.gz{,.asc}
FILE_VERSION   := 5.38
DEB_FILE_V     ?= $(FILE_VERSION)

file-setup: setup
	$(call PGP_VERIFY,file-$(FILE_VERSION).tar.gz,asc)
	$(call EXTRACT_TAR,file-$(FILE_VERSION).tar.gz,file-$(FILE_VERSION),file)

# `gl_cv_func_ftello_works=yes` workaround for gnulib issue on macOS Catalina, presumably also
# iOS 13, borrowed from Homebrew formula for coreutils
# TODO: Remove when GNU fixes this issue

ifneq ($(wildcard $(BUILD_WORK)/file/.build_complete),)
file:
	@echo "Using previously built file."
else
file: file-setup xz
	cd $(BUILD_WORK)/file && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/file
	+$(MAKE) -C $(BUILD_WORK)/file install \
		DESTDIR=$(BUILD_STAGE)/file
	touch $(BUILD_WORK)/file/.build_complete
endif

file-package: file-stage
	# file.mk Package Structure
	rm -rf $(BUILD_DIST)/file
	mkdir -p $(BUILD_DIST)/file
	
	# file.mk Prep file
	$(FAKEROOT) cp -a $(BUILD_STAGE)/file/usr $(BUILD_DIST)/file
	
	# file.mk Sign
	$(call SIGN,file,general.xml)
	
	# file.mk Make .debs
	$(call PACK,file,DEB_FILE_V)
	
	# file.mk Build cleanup
	rm -rf $(BUILD_DIST)/file

.PHONY: file file-package
