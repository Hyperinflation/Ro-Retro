# Makefile for Ro-Retro Game Hub (Flutter Edition)

.PHONY: all compile clean dist

all: compile

compile:
	@echo "Compiling Flutter code to Web static assets..."
	cd .. && FLUTTER_SUPPRESS_ANALYTICS=true CI=true flutter build web --release

clean:
	@echo "Cleaning Flutter build artifacts..."
	cd .. && flutter clean

dist: compile
	@echo "Creating distribution source tarball for RPM packaging..."
	mkdir -p ro-retro-1.0.0
	cp -r ../build/web ro-retro-1.0.0/
	cp launcher.py ro-retro.desktop ro-retro.spec Makefile ro-retro-1.0.0/
	cp ../README.md ro-retro-1.0.0/
	mkdir -p ro-retro-1.0.0/web/assets
	cp ../web/assets/icon.svg ro-retro-1.0.0/web/assets/
	tar -czf ro-retro-1.0.0.tar.gz ro-retro-1.0.0
	rm -rf ro-retro-1.0.0
	@echo "Package ro-retro-1.0.0.tar.gz created."
