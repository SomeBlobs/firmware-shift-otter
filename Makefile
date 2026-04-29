.PHONY: clean

all:

prepare:
	bash scripts/prepare.sh

install:
	cd out; find usr -type f -exec install -v -Dm644 "{}" "$(DESTDIR)/{}" \;

clean:
	rm -rfv out/
