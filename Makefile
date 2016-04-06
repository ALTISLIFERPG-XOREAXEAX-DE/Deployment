DATESTAMP := $(shell date +%s)

RELEASE = sed -i "s,\r,,g;" bin/release.sh; bin/release.sh "$(@)" "$(DATESTAMP)"

all: testing

clean:
	rm -rfv /cygdrive/c/CYGWIN_RELEASES

.PHONY: production
production:
	@$(RELEASE)

.PHONY: testing
testing:
	@$(RELEASE)
