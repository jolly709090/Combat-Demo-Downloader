crosscompile: embed
	GOOS=windows GOARCH=386 go build -o downloader.exe
	rm downloader.syso
embed:
	rsrc -ico EliteDangerous32_101.ico -o downloader.syso
clean:
	rm downloader.syso
	rm downloader.exe

