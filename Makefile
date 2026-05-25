# Makefile for Ro-Retro Game Hub (Flutter Edition)

.PHONY: all compile clean dist

all: compile

compile:
	@echo "Compiling Flutter code to Web static assets..."
	FLUTTER_SUPPRESS_ANALYTICS=true CI=true flutter build web --release

clean:
	@echo "Cleaning Flutter build artifacts..."
	flutter clean

dist: compile
	@echo "Creating distribution source tarball for RPM packaging..."
	tar -czf ro-retro-1.0.0.tar.gz build/web/ launcher.py ro-retro.desktop ro-retro.spec Makefile README.md web/assets/icon.svg
	@echo "Package ro-retro-1.0.0.tar.gz created."
