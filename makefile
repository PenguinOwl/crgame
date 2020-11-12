.PHONY: build

build:
	shards build
	patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 bin/crgame
	mkdir -p Resonance.AppDir/usr/bin
	cp bin/crgame Resonance.AppDir/usr/bin/resonance
	cd Resonance.AppDir/usr/ && \
	find . -type f -exec sed -i -e 's#/usr#././#g' {} \;
	appimagetool Resonance.AppDir/

release:
	shards build --release
	patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 bin/crgame
	mkdir -p Resonance.AppDir/usr/bin
	cp bin/crgame Resonance.AppDir/usr/bin/resonance
	cd Resonance.AppDir/usr/ && \
	find . -type f -exec sed -i -e 's#/usr#././#g' {} \;
	appimagetool Resonance.AppDir/
	zip Resonance.zip Resonance-x86_64.AppImage

test: build
	xdg-open http://127.0.0.1:6080/
	sudo docker run -p 6080:80 -p 5900:5900 -v `pwd`:`pwd` -w `pwd` -i -t dorowu/ubuntu-desktop-lxde-vnc -c " \
	./Resonance-x86_64.AppImage --appimage-extract-and-run \
	"
