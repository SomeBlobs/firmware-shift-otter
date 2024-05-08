.PHONY: clean

all:

prepare:
	bash scripts/prepare.sh

install:
	cd out; find lib -type f -exec install -v -Dm644 "{}" "$(DESTDIR)/{}" \;

clean:
	rm -rfv out/
