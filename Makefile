DATESTAMP := $(shell date +%s)

RELEASE = sed -i "s,\r,,g;" bin/release.sh; bin/release.sh "$(@)" "$(DATESTAMP)"

all: testing

clean:
	rm -rfv /cygdrive/c/CYGWIN_RELEASES
	make -C ../Mission clean

.PHONY: production
production:
	make -C ../Mission
	@$(RELEASE)

.PHONY: testing
testing:
	make -C ../Mission
	@$(RELEASE)

